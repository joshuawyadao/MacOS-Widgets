#!/bin/bash

readonly DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL="io.desktopwidgets.automatic-refresh"
readonly DESKTOP_WIDGETS_AUTOMATIC_REFRESH_THRESHOLD_SECONDS=172800
readonly DESKTOP_WIDGETS_PROFILELESS_RENEWAL_SECONDS=604800

desktop_widgets_lock_owner_pid() {
    local lock_directory="$1"
    /bin/cat "$lock_directory/owner.pid" 2>/dev/null || true
}

desktop_widgets_acquire_install_lock() {
    local lock_directory="$1"
    local owner_pid=""

    if /bin/mkdir "$lock_directory" 2>/dev/null; then
        /usr/bin/printf '%s\n' "$$" > "$lock_directory/owner.pid"
        return 0
    fi

    owner_pid="$(desktop_widgets_lock_owner_pid "$lock_directory")"
    if [[ "$owner_pid" =~ ^[0-9]+$ ]] && kill -0 "$owner_pid" 2>/dev/null; then
        return 1
    fi

    /bin/rm -f -- "$lock_directory/owner.pid"
    /bin/rmdir "$lock_directory" 2>/dev/null || return 1
    /bin/mkdir "$lock_directory" 2>/dev/null || return 1
    /usr/bin/printf '%s\n' "$$" > "$lock_directory/owner.pid"
}

desktop_widgets_release_install_lock() {
    local lock_directory="$1"
    local expected_owner="$2"
    local owner_pid=""

    owner_pid="$(desktop_widgets_lock_owner_pid "$lock_directory")"
    [[ "$owner_pid" == "$expected_owner" ]] || return 0
    /bin/rm -f -- "$lock_directory/owner.pid"
    /bin/rmdir "$lock_directory" 2>/dev/null || true
}

desktop_widgets_automatic_expiration_epoch() {
    local expiration="$1"
    local normalized

    normalized="$(/usr/bin/printf '%s' "$expiration" | /usr/bin/sed -E 's/\.[0-9]+Z$/Z/')"
    /bin/date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$normalized" '+%s' 2>/dev/null
}

desktop_widgets_automatic_should_refresh() {
    local expiration_epoch="$1"
    local current_epoch="$2"
    local threshold_seconds="${3:-$DESKTOP_WIDGETS_AUTOMATIC_REFRESH_THRESHOLD_SECONDS}"

    [[ "$expiration_epoch" =~ ^[0-9]+$ ]] || return 0
    [[ "$current_epoch" =~ ^[0-9]+$ ]] || return 0
    [[ "$threshold_seconds" =~ ^[0-9]+$ ]] || return 0
    (( expiration_epoch - current_epoch <= threshold_seconds ))
}

desktop_widgets_automatic_profileless_deadline() {
    local signed_at_epoch="$1"
    local renewal_seconds="${2:-$DESKTOP_WIDGETS_PROFILELESS_RENEWAL_SECONDS}"
    local deadline_epoch

    [[ "$signed_at_epoch" =~ ^[0-9]+$ && "$renewal_seconds" =~ ^[0-9]+$ ]] || return 1
    deadline_epoch=$((signed_at_epoch + renewal_seconds))
    /bin/date -r "$deadline_epoch" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null
}

desktop_widgets_automatic_expected_agent_path() {
    local user_home="${1:-$HOME}"
    /usr/bin/printf '%s\n' "$user_home/Library/LaunchAgents/${DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL}.plist"
}

desktop_widgets_automatic_status_path() {
    local local_configuration="$1"
    local user_home="${2:-$HOME}"
    local app_group

    app_group="$(desktop_widgets_local_value WIDGET_THEME_APP_GROUP "$local_configuration")"
    [[ -n "$app_group" && "$app_group" != *"/"* ]] || return 1
    /usr/bin/printf '%s\n' "$user_home/Library/Group Containers/$app_group/DesktopWidgetsAutomaticRefresh.plist"
}

desktop_widgets_automatic_status_value() {
    local path="$1"
    local key="$2"
    [[ -f "$path" ]] || return 0
    /usr/bin/plutil -extract "$key" raw -o - "$path" 2>/dev/null || true
}

desktop_widgets_automatic_status_temporary_path() {
    local path="$1"
    local writer_id="$2"

    [[ "$writer_id" =~ ^[0-9]+$ ]] || return 1
    /usr/bin/printf '%s.new.%s\n' "$path" "$writer_id"
}

desktop_widgets_automatic_write_status() {
    local path="$1"
    local enabled="$2"
    local state="$3"
    local message="$4"
    local profile_expiration="${5:-}"
    local last_success="${6:-}"
    local error_code="${7:-}"
    local last_notification_epoch="${8:-0}"
    local checked_at="${DESKTOP_WIDGETS_AUTOMATIC_NOW_ISO:-$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')}"
    local temporary_path

    temporary_path="$(desktop_widgets_automatic_status_temporary_path "$path" "$$")" || return 1

    if [[ -z "$last_success" ]]; then
        last_success="$(desktop_widgets_automatic_status_value "$path" LastSuccess)"
    fi
    if [[ "$last_notification_epoch" == "0" ]]; then
        last_notification_epoch="$(desktop_widgets_automatic_status_value "$path" LastNotificationEpoch)"
        last_notification_epoch="${last_notification_epoch:-0}"
    fi

    /bin/mkdir -p "$(/usr/bin/dirname "$path")"
    umask 077
    /bin/rm -f -- "$temporary_path"
    /usr/bin/plutil -create xml1 "$temporary_path"
    /usr/bin/plutil -insert Enabled -bool "$enabled" "$temporary_path"
    /usr/bin/plutil -insert State -string "$state" "$temporary_path"
    /usr/bin/plutil -insert Message -string "$message" "$temporary_path"
    /usr/bin/plutil -insert LastCheck -string "$checked_at" "$temporary_path"
    /usr/bin/plutil -insert LastNotificationEpoch -integer "$last_notification_epoch" "$temporary_path"
    [[ -z "$profile_expiration" ]] || /usr/bin/plutil -insert ProfileExpiration -string "$profile_expiration" "$temporary_path"
    [[ -z "$last_success" ]] || /usr/bin/plutil -insert LastSuccess -string "$last_success" "$temporary_path"
    [[ -z "$error_code" ]] || /usr/bin/plutil -insert LastErrorCode -string "$error_code" "$temporary_path"
    /bin/mv -f -- "$temporary_path" "$path"
}

desktop_widgets_automatic_should_notify() {
    local status_path="$1"
    local error_code="$2"
    local current_epoch="$3"
    local previous_error
    local previous_notification

    previous_error="$(desktop_widgets_automatic_status_value "$status_path" LastErrorCode)"
    previous_notification="$(desktop_widgets_automatic_status_value "$status_path" LastNotificationEpoch)"
    previous_notification="${previous_notification:-0}"

    [[ "$previous_error" != "$error_code" ]] && return 0
    [[ "$previous_notification" =~ ^[0-9]+$ ]] || return 0
    (( current_epoch - previous_notification >= 86400 ))
}

desktop_widgets_automatic_rotate_log() {
    local path="$1"
    local maximum_bytes="${2:-1048576}"
    local temporary_path="${path}.trimmed"
    local size=0

    [[ -f "$path" ]] || return 0
    size="$(/usr/bin/stat -f '%z' "$path" 2>/dev/null || echo 0)"
    [[ "$size" =~ ^[0-9]+$ ]] || size=0
    (( size <= maximum_bytes )) && return 0
    /usr/bin/tail -n 2000 "$path" > "$temporary_path"
    /bin/mv -f -- "$temporary_path" "$path"
}
