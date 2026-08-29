#!/bin/bash

set -euo pipefail

readonly MODE="${1:-status}"
readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"

# shellcheck source=Scripts/personal-installation-lib.sh
source "$SCRIPT_DIRECTORY/personal-installation-lib.sh"
# shellcheck source=Scripts/automatic-refresh-lib.sh
source "$SCRIPT_DIRECTORY/automatic-refresh-lib.sh"

readonly USER_HOME="${DESKTOP_WIDGETS_HOME:-$HOME}"
readonly SUPPORT_ROOT="${DESKTOP_WIDGETS_SUPPORT_ROOT:-$USER_HOME/Library/Application Support/Desktop Widgets}"
readonly STABLE_SOURCE_ROOT="${DESKTOP_WIDGETS_STABLE_SOURCE_ROOT:-$SUPPORT_ROOT/Installer}"
readonly LOCAL_CONFIGURATION="${DESKTOP_WIDGETS_LOCAL_CONFIGURATION:-$STABLE_SOURCE_ROOT/Local.xcconfig}"
readonly SCHEDULED_SCRIPT="$STABLE_SOURCE_ROOT/Scripts/automatic-refresh.sh"
readonly AGENT_PATH="${DESKTOP_WIDGETS_LAUNCH_AGENT_PATH:-$(desktop_widgets_automatic_expected_agent_path "$USER_HOME")}"
readonly LAUNCHCTL_COMMAND="${DESKTOP_WIDGETS_LAUNCHCTL_COMMAND:-/bin/launchctl}"
readonly USER_ID_COMMAND="${DESKTOP_WIDGETS_ID_COMMAND:-/usr/bin/id}"
readonly USER_DOMAIN="gui/$($USER_ID_COMMAND -u)"
readonly AGENT_SERVICE="$USER_DOMAIN/$DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL"
readonly DRY_RUN="${DESKTOP_WIDGETS_AUTOMATIC_DRY_RUN:-0}"

validate_agent_path() {
    [[ "$AGENT_PATH" == "$(desktop_widgets_automatic_expected_agent_path "$USER_HOME")" ]] || {
        echo "Refusing to manage an unexpected LaunchAgent path: $AGENT_PATH" >&2
        return 1
    }
}

status_path() {
    desktop_widgets_automatic_status_path "$LOCAL_CONFIGURATION" "$USER_HOME"
}

write_agent() {
    local state_path="$1"
    local temporary_path="${AGENT_PATH}.new"

    /bin/mkdir -p "$(/usr/bin/dirname "$AGENT_PATH")"
    /usr/bin/plutil -create xml1 "$temporary_path"
    /usr/bin/plutil -insert Label -string "$DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL" "$temporary_path"
    /usr/bin/plutil -insert ProgramArguments -array "$temporary_path"
    /usr/bin/plutil -insert ProgramArguments.0 -string /bin/bash "$temporary_path"
    /usr/bin/plutil -insert ProgramArguments.1 -string "$SCHEDULED_SCRIPT" "$temporary_path"
    /usr/bin/plutil -insert RunAtLoad -bool true "$temporary_path"
    /usr/bin/plutil -insert StartCalendarInterval -dictionary "$temporary_path"
    /usr/bin/plutil -insert StartCalendarInterval.Hour -integer 11 "$temporary_path"
    /usr/bin/plutil -insert StartCalendarInterval.Minute -integer 0 "$temporary_path"
    /usr/bin/plutil -insert ProcessType -string Background "$temporary_path"
    /usr/bin/plutil -insert LowPriorityIO -bool true "$temporary_path"
    /usr/bin/plutil -insert Nice -integer 10 "$temporary_path"
    /usr/bin/plutil -insert ThrottleInterval -integer 3600 "$temporary_path"
    /usr/bin/plutil -insert LimitLoadToSessionType -string Aqua "$temporary_path"
    /usr/bin/plutil -insert StandardOutPath -string /dev/null "$temporary_path"
    /usr/bin/plutil -insert StandardErrorPath -string /dev/null "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables -dictionary "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables.HOME -string "$USER_HOME" "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables.DESKTOP_WIDGETS_HOME -string "$USER_HOME" "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables.DESKTOP_WIDGETS_SUPPORT_ROOT -string "$SUPPORT_ROOT" "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables.DESKTOP_WIDGETS_LOCAL_CONFIGURATION -string "$LOCAL_CONFIGURATION" "$temporary_path"
    /usr/bin/plutil -insert EnvironmentVariables.DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH -string "$state_path" "$temporary_path"
    /usr/bin/plutil -lint "$temporary_path" >/dev/null
    /bin/mv -f -- "$temporary_path" "$AGENT_PATH"
}

enable_agent() {
    local state_path
    validate_agent_path
    [[ -f "$LOCAL_CONFIGURATION" ]] || {
        echo "Run Install Desktop Widgets.command before enabling automatic refresh." >&2
        return 1
    }
    [[ -x "$SCHEDULED_SCRIPT" ]] || {
        echo "The reusable automatic refresh helper is missing. Run the installer again." >&2
        return 1
    }
    state_path="${DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH:-$(status_path)}"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN: install $AGENT_PATH for $SCHEDULED_SCRIPT"
        return 0
    fi

    write_agent "$state_path"
    "$LAUNCHCTL_COMMAND" bootout "$USER_DOMAIN" "$AGENT_PATH" >/dev/null 2>&1 || true
    "$LAUNCHCTL_COMMAND" bootstrap "$USER_DOMAIN" "$AGENT_PATH"
    desktop_widgets_automatic_write_status "$state_path" true enabled \
        "Automatic maintenance is on. The lightweight check runs at login and daily."
    echo "Automatic Desktop Widgets maintenance is on."
    echo "It checks briefly at login and 11:00 AM, then exits unless profiles are near expiration."
}

disable_agent() {
    local state_path=""
    validate_agent_path
    if [[ -f "$LOCAL_CONFIGURATION" ]]; then
        state_path="${DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH:-$(status_path)}"
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN: remove only $AGENT_PATH"
        return 0
    fi

    "$LAUNCHCTL_COMMAND" bootout "$USER_DOMAIN" "$AGENT_PATH" >/dev/null 2>&1 || true
    /bin/rm -f -- "$AGENT_PATH"
    if [[ -n "$state_path" ]]; then
        desktop_widgets_automatic_write_status "$state_path" false disabled \
            "Automatic maintenance is off. Manual Refresh remains available."
    fi
    echo "Automatic Desktop Widgets maintenance is off."
    echo "The manual Refresh Desktop Widgets.command still works."
}

show_status() {
    validate_agent_path
    if [[ -f "$AGENT_PATH" ]]; then
        echo "Automatic Desktop Widgets maintenance is configured."
        "$LAUNCHCTL_COMMAND" print "$AGENT_SERVICE" >/dev/null 2>&1 \
            && echo "The LaunchAgent is loaded." \
            || echo "The LaunchAgent will load at the next login or when enabled again."
    else
        echo "Automatic Desktop Widgets maintenance is off."
    fi
}

case "$MODE" in
enable) enable_agent ;;
disable) disable_agent ;;
status) show_status ;;
*)
    echo "Usage: $0 enable|disable|status" >&2
    exit 64
    ;;
esac
