#!/bin/bash

# Pure and narrowly-scoped helpers shared by the friendly installer and its
# mocked regression tests. This file intentionally does not enable `set -e` so
# tests can source it and exercise failure paths.

desktop_widgets_redact() {
    /usr/bin/sed -E \
        -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[redacted Apple Account]/g' \
        -e 's/((password|passwd|token|secret)[[:space:]]*[:=][[:space:]]*)[^[:space:]]+/\1[redacted]/Ig'
}

desktop_widgets_resolve_developer_dir() {
    local candidate

    if [[ -n "${DESKTOP_WIDGETS_XCODE_DEVELOPER_DIR:-}" ]]; then
        candidate="$DESKTOP_WIDGETS_XCODE_DEVELOPER_DIR"
        if [[ -x "$candidate/usr/bin/xcodebuild" && "$candidate" == */Contents/Developer ]]; then
            /usr/bin/printf '%s\n' "$candidate"
            return 0
        fi
        return 1
    fi

    for candidate in \
        "${DEVELOPER_DIR:-}" \
        "$(/usr/bin/xcode-select --print-path 2>/dev/null || true)" \
        "/Applications/Xcode.app/Contents/Developer"; do
        if [[ -n "$candidate" && -x "$candidate/usr/bin/xcodebuild" && "$candidate" == */Contents/Developer ]]; then
            /usr/bin/printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

desktop_widgets_xcode_is_initialized() {
    local developer_dir="$1"
    DEVELOPER_DIR="$developer_dir" "$developer_dir/usr/bin/xcodebuild" -checkFirstLaunchStatus >/dev/null 2>&1
}

desktop_widgets_parse_personal_teams() {
    /usr/bin/awk '
        /\{/ { free = 0; team = ""; name = "" }
        /isFreeProvisioningTeam["[:space:]]*=[>]?[[:space:]]*(true|1)/ { free = 1 }
        /teamID["[:space:]]*=[>]?/ {
            line = $0
            sub(/^.*teamID"?[[:space:]]*=[>]?[[:space:]]*"?/, "", line)
            sub(/[";].*$/, "", line)
            team = line
        }
        /teamName["[:space:]]*=[>]?/ {
            line = $0
            sub(/^.*teamName"?[[:space:]]*=[>]?[[:space:]]*"?/, "", line)
            sub(/[";].*$/, "", line)
            name = line
        }
        /\}/ {
            if (free && team ~ /^[A-Z0-9]+$/ && length(team) == 10) {
                if (name == "") name = "Personal Team"
                print team "\t" name
            }
            free = 0; team = ""; name = ""
        }
    ' | /usr/bin/awk -F '\t' '!seen[$1]++'
}

desktop_widgets_read_personal_teams() {
    if [[ -n "${DESKTOP_WIDGETS_TEAM_PREFERENCES_FIXTURE:-}" ]]; then
        /bin/cat "$DESKTOP_WIDGETS_TEAM_PREFERENCES_FIXTURE" | desktop_widgets_parse_personal_teams
        return
    fi

    /usr/bin/defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null \
        | desktop_widgets_parse_personal_teams
}

desktop_widgets_select_personal_team() {
    local teams="$1"
    local count
    local selection
    local selected

    count="$(/usr/bin/printf '%s\n' "$teams" | /usr/bin/awk 'NF { count += 1 } END { print count + 0 }')"
    [[ "$count" -gt 0 ]] || return 1

    if [[ "$count" -eq 1 ]]; then
        /usr/bin/printf '%s\n' "$teams" | /usr/bin/awk -F '\t' 'NF { print $1; exit }'
        return
    fi

    echo "More than one Personal Team is available:" >&2
    /usr/bin/printf '%s\n' "$teams" | /usr/bin/awk -F '\t' 'NF { printf "  %d. %s (%s)\n", NR, $2, $1 }' >&2
    /usr/bin/printf 'Choose a team [1-%s]: ' "$count" >&2
    if [[ -n "${DESKTOP_WIDGETS_TEAM_SELECTION:-}" ]]; then
        selection="$DESKTOP_WIDGETS_TEAM_SELECTION"
        echo "$selection" >&2
    else
        IFS= read -r selection
    fi

    [[ "$selection" =~ ^[0-9]+$ ]] || return 1
    [[ "$selection" -ge 1 && "$selection" -le "$count" ]] || return 1
    selected="$(/usr/bin/printf '%s\n' "$teams" | /usr/bin/awk -F '\t' -v row="$selection" 'NF { index += 1; if (index == row) { print $1; exit } }')"
    [[ "$selected" =~ ^[A-Z0-9]{10}$ ]] || return 1
    /usr/bin/printf '%s\n' "$selected"
}

desktop_widgets_identifier_values() {
    local team_id="$1"
    local lowercase_team

    [[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || return 1
    lowercase_team="$(/usr/bin/printf '%s' "$team_id" | /usr/bin/tr '[:upper:]' '[:lower:]')"
    /usr/bin/printf '%s\n' \
        "io.desktopwidgets.personal.${lowercase_team}.app" \
        "io.desktopwidgets.personal.${lowercase_team}.widgets" \
        "${team_id}.io.desktopwidgets.personal.${lowercase_team}.shared"
}

desktop_widgets_local_value() {
    local key="$1"
    local path="$2"
    /usr/bin/sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\\1/p" "$path" \
        | /usr/bin/head -n 1
}

desktop_widgets_write_local_configuration() {
    local path="$1"
    local team_id="$2"
    local existing_team=""
    local app_identifier
    local extension_identifier
    local app_group
    local values
    local temporary_path="${path}.new"

    if [[ -f "$path" ]]; then
        existing_team="$(desktop_widgets_local_value LOCAL_DEVELOPMENT_TEAM "$path")"
        if [[ -n "$existing_team" && "$existing_team" != "$team_id" ]]; then
            echo "Existing local settings belong to Personal Team $existing_team; refusing to overwrite them." >&2
            return 1
        fi
    fi

    values="$(desktop_widgets_identifier_values "$team_id")" || return 1
    app_identifier="$(/usr/bin/printf '%s\n' "$values" | /usr/bin/sed -n '1p')"
    extension_identifier="$(/usr/bin/printf '%s\n' "$values" | /usr/bin/sed -n '2p')"
    app_group="$(/usr/bin/printf '%s\n' "$values" | /usr/bin/sed -n '3p')"

    # A pre-installer Local.xcconfig represents an existing development install.
    # Keep its historic identifiers so macOS can retain placed widgets/settings.
    if [[ -f "$path" && -z "$(desktop_widgets_local_value DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER "$path")" ]]; then
        app_identifier="com.joshuawyadao.DesktopWidgets"
        extension_identifier="com.joshuawyadao.DesktopWidgets.Widgets"
        app_group="${team_id}.com.joshuawyadao.desktop-widgets"
    fi

    /bin/mkdir -p "$(/usr/bin/dirname "$path")"
    umask 077
    {
        echo "// Generated locally by Install Desktop Widgets.command. Do not commit."
        echo "LOCAL_DEVELOPMENT_TEAM = $team_id"
        echo "DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER = $app_identifier"
        echo "DESKTOP_WIDGETS_EXTENSION_BUNDLE_IDENTIFIER = $extension_identifier"
        echo "WIDGET_THEME_APP_GROUP = $app_group"
        echo 'DESKTOP_WIDGETS_REFRESH_COMMAND_PATH = $(HOME)/Library/Application Support/Desktop Widgets/Installer/Refresh Desktop Widgets.command'
        echo 'DESKTOP_WIDGETS_ENABLE_AUTOMATIC_REFRESH_COMMAND_PATH = $(HOME)/Library/Application Support/Desktop Widgets/Installer/Enable Automatic Refresh.command'
        echo 'DESKTOP_WIDGETS_DISABLE_AUTOMATIC_REFRESH_COMMAND_PATH = $(HOME)/Library/Application Support/Desktop Widgets/Installer/Disable Automatic Refresh.command'
    } > "$temporary_path"

    if [[ -f "$path" ]] && /usr/bin/cmp -s "$temporary_path" "$path"; then
        /bin/rm -f -- "$temporary_path"
        echo "Local signing settings are already configured for Personal Team $team_id."
        return 0
    fi

    /bin/mv -f -- "$temporary_path" "$path"
    echo "Saved private signing settings for Personal Team $team_id."
}

desktop_widgets_expected_install_destination() {
    /usr/bin/printf '%s\n' "${DESKTOP_WIDGETS_HOME:-$HOME}/Applications/Desktop Widgets.app"
}

desktop_widgets_is_safe_install_destination() {
    local requested="$1"
    [[ "$requested" == "$(desktop_widgets_expected_install_destination)" ]]
}

desktop_widgets_print_build_arguments() {
    local project_path="$1"
    local derived_data_path="$2"
    /usr/bin/printf '%s\n' \
        build \
        -project "$project_path" \
        -scheme DesktopWidgets \
        -configuration Release \
        -destination platform=macOS \
        -derivedDataPath "$derived_data_path" \
        -allowProvisioningUpdates
}

desktop_widgets_classify_build_failure() {
    local build_log="$1"
    if /usr/bin/grep -Eqi 'app groups.*(not available|not supported)|do(es)? not support.*app groups|free provisioning profiles.*app groups' "$build_log"; then
        echo "Personal Team provisioning did not grant the required App Group capability. Desktop Widgets cannot safely run without it."
    elif /usr/bin/grep -Eqi 'no accounts|account.*not found|sign in.*account' "$build_log"; then
        echo "Xcode could not use an Apple Account. Open Xcode > Settings > Accounts, sign in, then run this command again."
    elif /usr/bin/grep -Eqi 'provisioning profile|requires a development team|code signing|certificate' "$build_log"; then
        echo "Xcode could not finish free provisioning. Open the project once in Xcode, select your Personal Team for both targets if asked, then run Refresh Desktop Widgets.command."
    else
        echo "Xcode could not build Desktop Widgets. See the redacted diagnostic log for the final error."
    fi
}
