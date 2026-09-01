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

if ! desktop_widgets_acquire_install_lock "$LOCK_DIRECTORY"; then
    exit 0
fi
cleanup() {
    desktop_widgets_release_install_lock "$LOCK_DIRECTORY" "$$"
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

installed_product_is_valid() {
    local extension_path="$INSTALL_DESTINATION/Contents/PlugIns/DesktopWidgetsExtension.appex"
    local expected_team
    local expected_group
    local app_team
    local extension_team
    local app_authority
    local extension_authority
    local app_entitlements="$AUTOMATIC_ROOT/app-entitlements.plist"
    local extension_entitlements="$AUTOMATIC_ROOT/extension-entitlements.plist"

    if [[ -n "${DESKTOP_WIDGETS_INSTALLED_PRODUCT_VALID:-}" ]]; then
        [[ "$DESKTOP_WIDGETS_INSTALLED_PRODUCT_VALID" == "1" ]]
        return
    fi

    [[ -d "$INSTALL_DESTINATION" && -d "$extension_path" ]] || return 1
    /usr/bin/codesign --verify --deep --strict "$INSTALL_DESTINATION" >/dev/null 2>&1 || return 1
    /usr/bin/codesign --verify --strict "$extension_path" >/dev/null 2>&1 || return 1
    expected_team="$(desktop_widgets_local_value LOCAL_DEVELOPMENT_TEAM "$LOCAL_CONFIGURATION")"
    expected_group="$(desktop_widgets_local_value WIDGET_THEME_APP_GROUP "$LOCAL_CONFIGURATION")"
    app_team="$(/usr/bin/codesign -dv --verbose=4 "$INSTALL_DESTINATION" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -n 1)"
    extension_team="$(/usr/bin/codesign -dv --verbose=4 "$extension_path" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -n 1)"
    [[ "$app_team" == "$expected_team" && "$extension_team" == "$expected_team" ]] || return 1
    app_authority="$(/usr/bin/codesign -dv --verbose=4 "$INSTALL_DESTINATION" 2>&1 | /usr/bin/sed -n 's/^Authority=//p' | /usr/bin/head -n 1)"
    extension_authority="$(/usr/bin/codesign -dv --verbose=4 "$extension_path" 2>&1 | /usr/bin/sed -n 's/^Authority=//p' | /usr/bin/head -n 1)"
    [[ "$app_authority" == Apple\ Development:* && "$extension_authority" == Apple\ Development:* ]] || return 1

    /usr/bin/codesign -d --entitlements :- "$INSTALL_DESTINATION" > "$app_entitlements" 2>/dev/null || return 1
    /usr/bin/codesign -d --entitlements :- "$extension_path" > "$extension_entitlements" 2>/dev/null || return 1
    desktop_widgets_validate_required_entitlements "$app_entitlements" "$expected_group" app || return 1
    desktop_widgets_validate_required_entitlements "$extension_entitlements" "$expected_group" extension || return 1
}

profileless_signed_at_epoch() {
    local extension_path="$INSTALL_DESTINATION/Contents/PlugIns/DesktopWidgetsExtension.appex"
    local app_signature_path="$INSTALL_DESTINATION/Contents/_CodeSignature/CodeResources"
    local extension_signature_path="$extension_path/Contents/_CodeSignature/CodeResources"
    local app_epoch
    local extension_epoch

    if [[ -n "${DESKTOP_WIDGETS_PROFILELESS_SIGNED_AT_EPOCH:-}" ]]; then
        [[ "${DESKTOP_WIDGETS_PROFILELESS_SIGNATURE_VALID:-1}" == "1" ]] || return 1
        /usr/bin/printf '%s\n' "$DESKTOP_WIDGETS_PROFILELESS_SIGNED_AT_EPOCH"
        return 0
    fi

    installed_product_is_valid || return 1

    [[ -f "$app_signature_path" && -f "$extension_signature_path" ]] || return 1
    app_epoch="$(/usr/bin/stat -f '%m' "$app_signature_path" 2>/dev/null)" || return 1
    extension_epoch="$(/usr/bin/stat -f '%m' "$extension_signature_path" 2>/dev/null)" || return 1
    if (( app_epoch <= extension_epoch )); then
        echo "$app_epoch"
    else
        echo "$extension_epoch"
    fi
}

maintenance_deadline() {
    local app_profile="$INSTALL_DESTINATION/Contents/embedded.provisionprofile"
    local extension_profile="$INSTALL_DESTINATION/Contents/PlugIns/DesktopWidgetsExtension.appex/Contents/embedded.provisionprofile"
    local profile_deadline
    local signed_at_epoch
    local signature_deadline

    if [[ -n "${DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE:-}" || -n "${DESKTOP_WIDGETS_PROFILE_EXPIRATION_FIXTURE:-}" ]]; then
        if [[ -n "${DESKTOP_WIDGETS_INSTALLED_PRODUCT_VALID:-}" ]]; then
            installed_product_is_valid || return 1
        fi
        profile_deadline="$(earliest_profile_expiration)" || return 1
        /usr/bin/printf 'profile|%s\n' "$profile_deadline"
        return 0
    fi

    if [[ -f "$app_profile" && -f "$extension_profile" ]]; then
        installed_product_is_valid || return 1
        profile_deadline="$(earliest_profile_expiration)" || return 1
        /usr/bin/printf 'profile|%s\n' "$profile_deadline"
        return 0
    fi
    [[ ! -f "$app_profile" && ! -f "$extension_profile" ]] || return 1
    signed_at_epoch="$(profileless_signed_at_epoch)" || return 1
    signature_deadline="$(desktop_widgets_automatic_profileless_deadline "$signed_at_epoch")" || return 1
    /usr/bin/printf 'signature|%s\n' "$signature_deadline"
}

automatic_refresh_run() {
    local status_path
    local deadline
    local deadline_kind
    local expiration
    local expiration_epoch
    local previous_error
    local should_notify=0
    local refreshed_deadline
    local refreshed_expiration
    local refreshed_expiration_epoch
    local refreshed_at
    local refresh_error_code="refresh-failed"
    local refresh_error_message="Automatic refresh could not finish. Open Xcode if asked, then run the manual Refresh command."
    local refresh_status

    if [[ ! -f "$LOCAL_CONFIGURATION" ]]; then
        status_path="${DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH:-}"
        if [[ -n "$status_path" ]]; then
            if desktop_widgets_automatic_should_notify "$status_path" "missing-local-configuration" "$CURRENT_EPOCH"; then
                should_notify=1
            fi
            desktop_widgets_automatic_write_status "$status_path" true needsAttention \
                "Private signing settings are missing. Run Install Desktop Widgets.command again." \
                "" "" "missing-local-configuration" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
        else
            should_notify=1
        fi
        echo "Automatic refresh needs the initial installer to create local signing settings." >&2
        [[ "$should_notify" == 1 ]] && notify_attention
        return 0
    fi
    status_path="${DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH:-$(desktop_widgets_automatic_status_path "$LOCAL_CONFIGURATION" "$USER_HOME")}" || return 1

    if ! deadline="$(maintenance_deadline)"; then
        if desktop_widgets_automatic_should_notify "$status_path" "invalid-signing-state" "$CURRENT_EPOCH"; then
            should_notify=1
        fi
        desktop_widgets_automatic_write_status "$status_path" true needsAttention \
            "The installed signing state is missing, inconsistent, or unreadable. Run the manual Refresh command." \
            "" "" "invalid-signing-state" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
        [[ "$should_notify" == 1 ]] && notify_attention
        echo "Automatic refresh stopped: installed signing state is missing, inconsistent, or unreadable."
        return 0
    fi
    deadline_kind="${deadline%%|*}"
    expiration="${deadline#*|}"

    if ! expiration_epoch="$(desktop_widgets_automatic_expiration_epoch "$expiration")"; then
        if desktop_widgets_automatic_should_notify "$status_path" "invalid-expiration" "$CURRENT_EPOCH"; then
            should_notify=1
        fi
        desktop_widgets_automatic_write_status "$status_path" true needsAttention \
            "The installed signing renewal deadline is unreadable. Run the manual Refresh command." \
            "" "" "invalid-expiration" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
        [[ "$should_notify" == 1 ]] && notify_attention
        echo "Automatic refresh stopped: the signing renewal deadline is unreadable."
        return 0
    fi

    if ! desktop_widgets_automatic_should_refresh "$expiration_epoch" "$CURRENT_EPOCH"; then
        if [[ "$deadline_kind" == "signature" ]]; then
            desktop_widgets_automatic_write_status "$status_path" true healthy \
                "Automatic maintenance is on. Xcode used valid profile-free macOS signing; no precautionary rebuild is needed yet." "$expiration"
            echo "The profile-free signature remains outside the precautionary 48-hour renewal window; no build was started."
        else
            desktop_widgets_automatic_write_status "$status_path" true healthy \
                "Automatic maintenance is on. No rebuild is needed yet." "$expiration"
            echo "Profiles remain valid beyond the 48-hour renewal window; no build was started."
        fi
        return 0
    fi

    previous_error="$(desktop_widgets_automatic_status_value "$status_path" LastErrorCode)"
    desktop_widgets_automatic_write_status "$status_path" true refreshing \
        "Refreshing the free Personal Team build at low priority." "$expiration" "" "$previous_error"
    if [[ "$deadline_kind" == "signature" ]]; then
        echo "The profile-free signature is inside the precautionary 48-hour renewal window; starting a guarded refresh."
    else
        echo "Profiles are inside the 48-hour renewal window; starting a guarded refresh."
    fi

    set +e
    /usr/bin/nice -n 10 /usr/bin/env \
        DESKTOP_WIDGETS_HOME="$USER_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$LOG_DIRECTORY" \
        DESKTOP_WIDGETS_SCHEDULED=1 \
        DESKTOP_WIDGETS_INSTALL_LOCK_HELD_BY_PID="$$" \
        /bin/bash "$REFRESH_SCRIPT" refresh
    refresh_status=$?
    set -e

    if [[ "$refresh_status" -eq 0 ]]; then
        refreshed_deadline="$(maintenance_deadline 2>/dev/null || true)"
        refreshed_expiration="${refreshed_deadline#*|}"
        if [[ -n "$refreshed_deadline" && "$refreshed_expiration" != "$refreshed_deadline" ]] \
            && refreshed_expiration_epoch="$(desktop_widgets_automatic_expiration_epoch "$refreshed_expiration")" \
            && ! desktop_widgets_automatic_should_refresh "$refreshed_expiration_epoch" "$CURRENT_EPOCH"; then
            refreshed_at="$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')"
            desktop_widgets_automatic_write_status "$status_path" true refreshed \
                "Automatic maintenance refreshed Desktop Widgets successfully." "$refreshed_expiration" "$refreshed_at"
            echo "Automatic refresh completed successfully."
            return 0
        fi

        refresh_error_code="renewal-not-extended"
        refresh_error_message="Xcode finished, but the signing renewal deadline did not move beyond the 48-hour window. Open Xcode, then run the manual Refresh command."
        refreshed_expiration="${refreshed_expiration:-$expiration}"
    fi

    if [[ "$previous_error" != "$refresh_error_code" ]] || desktop_widgets_automatic_should_notify "$status_path" "$refresh_error_code" "$CURRENT_EPOCH"; then
        should_notify=1
    fi
    desktop_widgets_automatic_write_status "$status_path" true needsAttention \
        "$refresh_error_message" \
        "${refreshed_expiration:-$expiration}" "" "$refresh_error_code" "$([[ "$should_notify" == 1 ]] && echo "$CURRENT_EPOCH" || echo 0)"
    [[ "$should_notify" == 1 ]] && notify_attention
    if [[ "$refresh_error_code" == "renewal-not-extended" ]]; then
        echo "Automatic refresh finished, but the signing deadline is still inside the 48-hour renewal window." >&2
    else
        echo "Automatic refresh failed. It will retry at the next daily check; manual Refresh remains available." >&2
    fi
    return 0
}

set +e
automatic_refresh_run 2>&1 | desktop_widgets_redact | /usr/bin/tee -a "$AUTOMATIC_LOG"
readonly AUTOMATIC_STATUS="${PIPESTATUS[0]}"
set -e
exit "$AUTOMATIC_STATUS"
