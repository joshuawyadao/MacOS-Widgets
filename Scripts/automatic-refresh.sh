#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly PERSONAL_LIBRARY="$SCRIPT_DIRECTORY/personal-installation-lib.sh"
readonly AUTOMATIC_LIBRARY="$SCRIPT_DIRECTORY/automatic-refresh-lib.sh"

# shellcheck source=Scripts/personal-installation-lib.sh
source "$PERSONAL_LIBRARY"
# shellcheck source=Scripts/automatic-refresh-lib.sh
source "$AUTOMATIC_LIBRARY"

readonly USER_HOME="${DESKTOP_WIDGETS_HOME:-$HOME}"
readonly SUPPORT_ROOT="${DESKTOP_WIDGETS_SUPPORT_ROOT:-$USER_HOME/Library/Application Support/Desktop Widgets}"
readonly AUTOMATIC_ROOT="$SUPPORT_ROOT/AutomaticRefresh"
readonly LOCAL_CONFIGURATION="${DESKTOP_WIDGETS_LOCAL_CONFIGURATION:-$SOURCE_ROOT/Local.xcconfig}"
readonly INSTALL_DESTINATION="${DESKTOP_WIDGETS_INSTALL_DESTINATION:-$USER_HOME/Applications/Desktop Widgets.app}"
readonly LOG_DIRECTORY="${DESKTOP_WIDGETS_LOG_DIRECTORY:-$USER_HOME/Library/Logs/Desktop Widgets}"
readonly AUTOMATIC_LOG="$LOG_DIRECTORY/automatic-refresh.log"
readonly LOCK_DIRECTORY="$AUTOMATIC_ROOT/run.lock"
readonly REFRESH_SCRIPT="${DESKTOP_WIDGETS_REFRESH_SCRIPT:-$SOURCE_ROOT/Scripts/personal-installation.sh}"
readonly SECURITY_COMMAND="${DESKTOP_WIDGETS_SECURITY_COMMAND:-/usr/bin/security}"
readonly NOTIFICATION_COMMAND="${DESKTOP_WIDGETS_NOTIFICATION_COMMAND:-/usr/bin/osascript}"
readonly CURRENT_EPOCH="${DESKTOP_WIDGETS_AUTOMATIC_NOW_EPOCH:-$(/bin/date '+%s')}"

/bin/mkdir -p "$AUTOMATIC_ROOT" "$LOG_DIRECTORY"
desktop_widgets_automatic_rotate_log "$AUTOMATIC_LOG"

if ! /bin/mkdir "$LOCK_DIRECTORY" 2>/dev/null; then
    exit 0
fi
cleanup() {
    /bin/rmdir "$LOCK_DIRECTORY" 2>/dev/null || true
}
trap cleanup EXIT

notify_attention() {
    "$NOTIFICATION_COMMAND" -e 'display notification "Open Desktop Widgets Help, then run the manual Refresh command." with title "Desktop Widgets needs attention"' >/dev/null 2>&1 || true
}

profile_expiration() {
    local bundle_path="$1"
    local profile_path="$bundle_path/Contents/embedded.provisionprofile"
    local decoded_path="$AUTOMATIC_ROOT/$(/usr/bin/basename "$bundle_path").profile.plist"

    [[ -f "$profile_path" ]] || return 1
    "$SECURITY_COMMAND" cms -D -i "$profile_path" -o "$decoded_path" >/dev/null 2>&1 || return 1
    /usr/bin/plutil -extract ExpirationDate raw -o - "$decoded_path" 2>/dev/null
}

earliest_profile_expiration() {
    if [[ -n "${DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE:-}" ]]; then
        [[ -f "$DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE" ]] || return 1
        /bin/cat "$DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE"
        return 0
    fi
    if [[ -n "${DESKTOP_WIDGETS_PROFILE_EXPIRATION_FIXTURE:-}" ]]; then
        /usr/bin/printf '%s\n' "$DESKTOP_WIDGETS_PROFILE_EXPIRATION_FIXTURE"
        return 0
    fi

    local app_expiration
    local extension_expiration
    local app_epoch
    local extension_epoch
    app_expiration="$(profile_expiration "$INSTALL_DESTINATION")" || return 1
    extension_expiration="$(profile_expiration "$INSTALL_DESTINATION/Contents/PlugIns/DesktopWidgetsExtension.appex")" || return 1
    app_epoch="$(desktop_widgets_automatic_expiration_epoch "$app_expiration")" || return 1
    extension_epoch="$(desktop_widgets_automatic_expiration_epoch "$extension_expiration")" || return 1
    if (( app_epoch <= extension_epoch )); then
        echo "$app_expiration"
    else
        echo "$extension_expiration"
    fi
}

automatic_refresh_run() {
    local status_path
    local expiration
    local expiration_epoch
    local previous_error
    local should_notify=0
    local refreshed_expiration
    local refreshed_at
    local refresh_status

    if [[ ! -f "$LOCAL_CONFIGURATION" ]]; then
        echo "Automatic refresh needs the initial installer to create local signing settings." >&2
        notify_attention
        return 0
    fi
    status_path="${DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH:-$(desktop_widgets_automatic_status_path "$LOCAL_CONFIGURATION" "$USER_HOME")}" || return 1

    if ! expiration="$(earliest_profile_expiration)"; then
        previous_error="$(desktop_widgets_automatic_status_value "$status_path" LastErrorCode)"
        if desktop_widgets_automatic_should_notify "$status_path" "missing-profile" "$CURRENT_EPOCH"; then
            should_notify=1
        fi
        desktop_widgets_automatic_write_status "$status_path" true needsAttention \
            "The installed Personal Team profile is missing or unreadable. Run the manual Refresh command." \
            "" "" "missing-profile" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
        [[ "$should_notify" == 1 ]] && notify_attention
        echo "Automatic refresh stopped: installed provisioning profile is missing or unreadable."
        return 0
    fi

    if ! expiration_epoch="$(desktop_widgets_automatic_expiration_epoch "$expiration")"; then
        if desktop_widgets_automatic_should_notify "$status_path" "invalid-expiration" "$CURRENT_EPOCH"; then
            should_notify=1
        fi
        desktop_widgets_automatic_write_status "$status_path" true needsAttention \
            "The installed Personal Team profile has an unreadable expiration date. Run the manual Refresh command." \
            "" "" "invalid-expiration" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
        [[ "$should_notify" == 1 ]] && notify_attention
        echo "Automatic refresh stopped: provisioning profile expiration is unreadable."
        return 0
    fi

    if ! desktop_widgets_automatic_should_refresh "$expiration_epoch" "$CURRENT_EPOCH"; then
        desktop_widgets_automatic_write_status "$status_path" true healthy \
            "Automatic maintenance is on. No rebuild is needed yet." "$expiration"
        echo "Profiles remain valid beyond the 48-hour renewal window; no build was started."
        return 0
    fi

    previous_error="$(desktop_widgets_automatic_status_value "$status_path" LastErrorCode)"
    desktop_widgets_automatic_write_status "$status_path" true refreshing \
        "Refreshing the free Personal Team build at low priority." "$expiration" "" "$previous_error"
    echo "Profiles are inside the 48-hour renewal window; starting a guarded refresh."

    set +e
    /usr/bin/nice -n 10 /usr/bin/env \
        DESKTOP_WIDGETS_HOME="$USER_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$LOG_DIRECTORY" \
        DESKTOP_WIDGETS_SCHEDULED=1 \
        /bin/bash "$REFRESH_SCRIPT" refresh
    refresh_status=$?
    set -e

    if [[ "$refresh_status" -eq 0 ]]; then
        refreshed_at="$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')"
        refreshed_expiration="$(earliest_profile_expiration 2>/dev/null || echo "$expiration")"
        desktop_widgets_automatic_write_status "$status_path" true refreshed \
            "Automatic maintenance refreshed Desktop Widgets successfully." "$refreshed_expiration" "$refreshed_at"
        echo "Automatic refresh completed successfully."
        return 0
    fi

    if [[ "$previous_error" != "refresh-failed" ]] || desktop_widgets_automatic_should_notify "$status_path" "refresh-failed" "$CURRENT_EPOCH"; then
        should_notify=1
    fi
    desktop_widgets_automatic_write_status "$status_path" true needsAttention \
        "Automatic refresh could not finish. Open Xcode if asked, then run the manual Refresh command." \
        "$expiration" "" "refresh-failed" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
    [[ "$should_notify" == 1 ]] && notify_attention
    echo "Automatic refresh failed. It will retry at the next daily check; manual Refresh remains available." >&2
    return 0
}

set +e
automatic_refresh_run 2>&1 | desktop_widgets_redact | /usr/bin/tee -a "$AUTOMATIC_LOG"
readonly AUTOMATIC_STATUS="${PIPESTATUS[0]}"
set -e
exit "$AUTOMATIC_STATUS"
