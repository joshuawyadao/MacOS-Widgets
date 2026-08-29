#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly AUTOMATIC_LIBRARY="$SCRIPT_DIRECTORY/automatic-refresh-lib.sh"
readonly AUTOMATIC_SCRIPT="$SCRIPT_DIRECTORY/automatic-refresh.sh"
readonly MANAGER_SCRIPT="$SCRIPT_DIRECTORY/manage-automatic-refresh.sh"
readonly TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-automatic-test.XXXXXX")"
readonly TEST_HOME="$TEST_ROOT/Home"
readonly SUPPORT_ROOT="$TEST_ROOT/Support"
readonly STABLE_ROOT="$SUPPORT_ROOT/Installer"
readonly LOCAL_CONFIGURATION="$STABLE_ROOT/Local.xcconfig"
readonly STATUS_PATH="$TEST_ROOT/automatic-status.plist"
readonly COMMAND_LOG="$TEST_ROOT/commands.log"
readonly NOTIFICATION_LOG="$TEST_ROOT/notifications.log"
readonly REFRESH_LOG="$TEST_ROOT/refreshes.log"
readonly EXPIRATION_FILE="$TEST_ROOT/expiration.txt"
readonly TEAM_ID="ABC123DE45"
readonly APP_GROUP="$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared"
readonly CURRENT_ISO="2026-08-27T12:00:00Z"

cleanup() {
    if [[ -n "$TEST_ROOT" && "$TEST_ROOT" == *"/desktop-widgets-automatic-test."* ]]; then
        /bin/rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

# shellcheck source=Scripts/personal-installation-lib.sh
source "$SCRIPT_DIRECTORY/personal-installation-lib.sh"
# shellcheck source=Scripts/automatic-refresh-lib.sh
source "$AUTOMATIC_LIBRARY"

readonly CURRENT_EPOCH="$(desktop_widgets_automatic_expiration_epoch "$CURRENT_ISO")"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    [[ "$expected" == "$actual" ]] || fail "$description (expected '$expected', got '$actual')"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    [[ "$haystack" == *"$needle"* ]] || fail "$description (missing '$needle')"
}

/bin/mkdir -p "$STABLE_ROOT/Scripts" "$TEST_HOME/Library/LaunchAgents"
/usr/bin/printf '%s\n' \
    "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" \
    "WIDGET_THEME_APP_GROUP = $APP_GROUP" > "$LOCAL_CONFIGURATION"

assert_equal "$CURRENT_EPOCH" "$(desktop_widgets_automatic_expiration_epoch '2026-08-27T12:00:00.000Z')" "fractional RFC3339 expiration should parse"
assert_equal "2026-09-03T12:00:00Z" "$(desktop_widgets_automatic_profileless_deadline "$CURRENT_EPOCH")" "profile-free signing should use a conservative seven-day renewal deadline"
healthy_epoch="$(desktop_widgets_automatic_expiration_epoch '2026-08-30T12:00:01Z')"
near_epoch="$(desktop_widgets_automatic_expiration_epoch '2026-08-29T11:59:59Z')"
if desktop_widgets_automatic_should_refresh "$healthy_epoch" "$CURRENT_EPOCH"; then
    fail "profile beyond the 48-hour window should not refresh"
fi
desktop_widgets_automatic_should_refresh "$near_epoch" "$CURRENT_EPOCH" || fail "profile inside the 48-hour window should refresh"
desktop_widgets_automatic_should_refresh 1 "$CURRENT_EPOCH" || fail "expired profile should refresh"
desktop_widgets_automatic_should_refresh invalid "$CURRENT_EPOCH" || fail "unreadable profile should take the safe refresh path"

first_status_temporary="$(desktop_widgets_automatic_status_temporary_path "$STATUS_PATH" 101)"
second_status_temporary="$(desktop_widgets_automatic_status_temporary_path "$STATUS_PATH" 202)"
[[ "$first_status_temporary" != "$second_status_temporary" ]] || fail "concurrent status writers should use distinct temporary files"
assert_equal "$STATUS_PATH.new.101" "$first_status_temporary" "status temporary files should remain beside the atomic destination"
[[ "$(/bin/cat "$AUTOMATIC_SCRIPT")" == *'DESKTOP_WIDGETS_INSTALL_LOCK_HELD_BY_PID="$$"'* ]] \
    || fail "automatic refresh should hand its common installer lock to the scheduled child"

desktop_widgets_automatic_write_status "$STATUS_PATH" true needsAttention "Open Xcode." "" "" "refresh-failed"
desktop_widgets_automatic_publish_manual_refresh "$STATUS_PATH" true
assert_equal "refreshed" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "manual refresh should clear stale attention while maintenance stays enabled"
desktop_widgets_automatic_publish_manual_refresh "$STATUS_PATH" false
assert_equal "disabled" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "manual refresh should preserve disabled maintenance"

/usr/bin/printf '%s\n' 'installed agent fixture' > "$TEST_ROOT/enabled-agent.plist"
assert_equal "true" "$(desktop_widgets_automatic_enabled_state "$TEST_ROOT/missing-status.plist" "$TEST_ROOT/enabled-agent.plist")" "missing status should retain enabled maintenance when its agent exists"
assert_equal "false" "$(desktop_widgets_automatic_enabled_state "$TEST_ROOT/missing-status.plist" "$TEST_ROOT/missing-agent.plist")" "missing status should report off only when no agent exists"

/usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'printf "%s\n" "$*" >> "$DESKTOP_WIDGETS_TEST_COMMAND_LOG"' \
    'if [[ "${1:-}" == "print" ]]; then exit 1; fi' \
    'exit 0' > "$TEST_ROOT/fake-launchctl.sh"
/bin/chmod +x "$TEST_ROOT/fake-launchctl.sh"

/usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    'echo 501' > "$TEST_ROOT/fake-id.sh"
/bin/chmod +x "$TEST_ROOT/fake-id.sh"

/usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    'exit 0' > "$STABLE_ROOT/Scripts/automatic-refresh.sh"
/bin/chmod +x "$STABLE_ROOT/Scripts/automatic-refresh.sh"

run_manager() {
    env \
        DESKTOP_WIDGETS_HOME="$TEST_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_STABLE_SOURCE_ROOT="$STABLE_ROOT" \
        DESKTOP_WIDGETS_LOCAL_CONFIGURATION="$LOCAL_CONFIGURATION" \
        DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH="$STATUS_PATH" \
        DESKTOP_WIDGETS_LAUNCHCTL_COMMAND="$TEST_ROOT/fake-launchctl.sh" \
        DESKTOP_WIDGETS_ID_COMMAND="$TEST_ROOT/fake-id.sh" \
        DESKTOP_WIDGETS_TEST_COMMAND_LOG="$COMMAND_LOG" \
        /bin/bash "$MANAGER_SCRIPT" "$1"
}

run_manager enable >/dev/null
run_manager enable >/dev/null
readonly AGENT_PATH="$TEST_HOME/Library/LaunchAgents/$DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL.plist"
[[ -f "$AGENT_PATH" ]] || fail "Enable should create the exact Desktop Widgets LaunchAgent"
assert_equal "$DESKTOP_WIDGETS_AUTOMATIC_REFRESH_LABEL" "$(/usr/bin/plutil -extract Label raw -o - "$AGENT_PATH")" "LaunchAgent label should be stable"
assert_equal "true" "$(/usr/bin/plutil -extract RunAtLoad raw -o - "$AGENT_PATH")" "LaunchAgent should check at login"
assert_equal "11" "$(/usr/bin/plutil -extract StartCalendarInterval.Hour raw -o - "$AGENT_PATH")" "LaunchAgent should check daily at 11"
assert_equal "10" "$(/usr/bin/plutil -extract Nice raw -o - "$AGENT_PATH")" "LaunchAgent should run at low CPU priority"
assert_equal "true" "$(/usr/bin/plutil -extract LowPriorityIO raw -o - "$AGENT_PATH")" "LaunchAgent should use low-priority IO"
assert_equal "$STATUS_PATH" "$(/usr/bin/plutil -extract EnvironmentVariables.DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH raw -o - "$AGENT_PATH")" "LaunchAgent should retain the status path independently of local signing settings"
if /usr/bin/plutil -extract KeepAlive raw -o - "$AGENT_PATH" >/dev/null 2>&1; then
    fail "LaunchAgent must not remain alive"
fi
assert_equal "enabled" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "Enable should publish status"
enable_status_line="$(/usr/bin/grep -n -F 'desktop_widgets_automatic_write_status "$state_path" true enabled' "$MANAGER_SCRIPT" | /usr/bin/head -n 1 | /usr/bin/cut -d: -f1)"
bootstrap_line="$(/usr/bin/grep -n -F '"$LAUNCHCTL_COMMAND" bootstrap' "$MANAGER_SCRIPT" | /usr/bin/head -n 1 | /usr/bin/cut -d: -f1)"
[[ -n "$enable_status_line" && -n "$bootstrap_line" && "$enable_status_line" -lt "$bootstrap_line" ]] \
    || fail "Enable should publish its initial state before RunAtLoad can publish a newer result"
[[ "$(/usr/bin/grep -c 'bootstrap' "$COMMAND_LOG")" == "2" ]] || fail "Repeated enable should safely reload the same agent"
if /usr/bin/grep -q 'kickstart' "$COMMAND_LOG"; then
    fail "Enable should rely on RunAtLoad bootstrap instead of a potentially blocking kickstart"
fi

unrelated_agent="$TEST_HOME/Library/LaunchAgents/com.example.unrelated.plist"
echo 'unrelated' > "$unrelated_agent"
run_manager disable >/dev/null
[[ ! -e "$AGENT_PATH" ]] || fail "Disable should remove the Desktop Widgets agent"
[[ -f "$unrelated_agent" ]] || fail "Disable must not remove unrelated agents"
assert_equal "disabled" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "Disable should publish status"

run_manager enable >/dev/null
/usr/bin/printf '%s\n' "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" > "$LOCAL_CONFIGURATION"
run_manager disable >/dev/null
[[ ! -e "$AGENT_PATH" ]] || fail "Disable should remove the agent even when local configuration is malformed"
assert_equal "disabled" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "Disable should recover the status path from the agent plist"
/usr/bin/printf '%s\n' \
    "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" \
    "WIDGET_THEME_APP_GROUP = $APP_GROUP" > "$LOCAL_CONFIGURATION"

unsafe_output="$(env DESKTOP_WIDGETS_HOME="$TEST_HOME" DESKTOP_WIDGETS_LAUNCH_AGENT_PATH="$unrelated_agent" DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" DESKTOP_WIDGETS_STABLE_SOURCE_ROOT="$STABLE_ROOT" DESKTOP_WIDGETS_LOCAL_CONFIGURATION="$LOCAL_CONFIGURATION" /bin/bash "$MANAGER_SCRIPT" disable 2>&1 || true)"
assert_contains "$unsafe_output" "Refusing to manage" "manager should reject unexpected LaunchAgent paths"
[[ -f "$unrelated_agent" ]] || fail "unsafe path rejection must preserve the unrelated agent"

/usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'printf "%s\n" "$*" >> "$DESKTOP_WIDGETS_TEST_REFRESH_LOG"' \
    'if [[ "${DESKTOP_WIDGETS_TEST_REFRESH_RESULT:-success}" == "failure" ]]; then exit 65; fi' \
    'if [[ -n "${DESKTOP_WIDGETS_REFRESHED_EXPIRATION:-}" ]]; then printf "%s\n" "$DESKTOP_WIDGETS_REFRESHED_EXPIRATION" > "$DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE"; fi' \
    'exit 0' > "$TEST_ROOT/fake-refresh.sh"
/bin/chmod +x "$TEST_ROOT/fake-refresh.sh"

/usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'printf "%s\n" "$*" >> "$DESKTOP_WIDGETS_TEST_NOTIFICATION_LOG"' > "$TEST_ROOT/fake-notification.sh"
/bin/chmod +x "$TEST_ROOT/fake-notification.sh"

run_automatic() {
    env \
        DESKTOP_WIDGETS_HOME="$TEST_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_LOCAL_CONFIGURATION="$LOCAL_CONFIGURATION" \
        DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH="$STATUS_PATH" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$TEST_ROOT/Logs" \
        DESKTOP_WIDGETS_REFRESH_SCRIPT="$TEST_ROOT/fake-refresh.sh" \
        DESKTOP_WIDGETS_NOTIFICATION_COMMAND="$TEST_ROOT/fake-notification.sh" \
        DESKTOP_WIDGETS_PROFILE_EXPIRATION_FILE="$EXPIRATION_FILE" \
        DESKTOP_WIDGETS_AUTOMATIC_NOW_EPOCH="$CURRENT_EPOCH" \
        DESKTOP_WIDGETS_AUTOMATIC_NOW_ISO="$CURRENT_ISO" \
        DESKTOP_WIDGETS_TEST_REFRESH_LOG="$REFRESH_LOG" \
        DESKTOP_WIDGETS_TEST_NOTIFICATION_LOG="$NOTIFICATION_LOG" \
        "$@" \
        /bin/bash "$AUTOMATIC_SCRIPT"
}

run_profileless_automatic() {
    local signed_at_epoch="$1"
    shift
    env \
        DESKTOP_WIDGETS_HOME="$TEST_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_LOCAL_CONFIGURATION="$LOCAL_CONFIGURATION" \
        DESKTOP_WIDGETS_AUTOMATIC_STATUS_PATH="$STATUS_PATH" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$TEST_ROOT/Logs" \
        DESKTOP_WIDGETS_REFRESH_SCRIPT="$TEST_ROOT/fake-refresh.sh" \
        DESKTOP_WIDGETS_NOTIFICATION_COMMAND="$TEST_ROOT/fake-notification.sh" \
        DESKTOP_WIDGETS_PROFILELESS_SIGNED_AT_EPOCH="$signed_at_epoch" \
        DESKTOP_WIDGETS_AUTOMATIC_NOW_EPOCH="$CURRENT_EPOCH" \
        DESKTOP_WIDGETS_AUTOMATIC_NOW_ISO="$CURRENT_ISO" \
        DESKTOP_WIDGETS_TEST_REFRESH_LOG="$REFRESH_LOG" \
        DESKTOP_WIDGETS_TEST_NOTIFICATION_LOG="$NOTIFICATION_LOG" \
        "$@" \
        /bin/bash "$AUTOMATIC_SCRIPT"
}

echo '2026-09-01T12:00:00Z' > "$EXPIRATION_FILE"
: > "$REFRESH_LOG"
/bin/mkdir -p "$SUPPORT_ROOT/AutomaticRefresh/run.lock"
/usr/bin/printf '%s\n' '999999' > "$SUPPORT_ROOT/AutomaticRefresh/run.lock/owner.pid"
run_automatic >/dev/null
[[ ! -s "$REFRESH_LOG" ]] || fail "healthy profile check must not start Xcode"
assert_equal "healthy" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "healthy no-op should publish status"
[[ ! -d "$SUPPORT_ROOT/AutomaticRefresh/run.lock" ]] || fail "a completed check should remove a reclaimed stale lock"

: > "$NOTIFICATION_LOG"
run_automatic DESKTOP_WIDGETS_INSTALLED_PRODUCT_VALID=0 >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "an invalid profiled product must not be reported healthy"
assert_equal "invalid-signing-state" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "an invalid profiled product should request signing repair"
[[ -s "$NOTIFICATION_LOG" ]] || fail "an invalid profiled product should notify the user"

/bin/mkdir -p "$SUPPORT_ROOT/AutomaticRefresh/run.lock"
: > "$REFRESH_LOG"
run_automatic >/dev/null
[[ ! -s "$REFRESH_LOG" ]] || fail "a fresh ownerless lock should prevent concurrent refresh during owner publication"
[[ -d "$SUPPORT_ROOT/AutomaticRefresh/run.lock" ]] || fail "a contender must not remove a fresh ownerless lock"
/bin/rmdir "$SUPPORT_ROOT/AutomaticRefresh/run.lock"

/bin/mkdir -p "$SUPPORT_ROOT/AutomaticRefresh/run.lock"
/usr/bin/printf '%s\n' "$$" > "$SUPPORT_ROOT/AutomaticRefresh/run.lock/owner.pid"
echo '2026-08-28T12:00:00Z' > "$EXPIRATION_FILE"
: > "$REFRESH_LOG"
run_automatic >/dev/null
[[ ! -s "$REFRESH_LOG" ]] || fail "an active automatic-refresh owner should keep a second check from running"
[[ -d "$SUPPORT_ROOT/AutomaticRefresh/run.lock" ]] || fail "a second check must not remove an active owner's lock"
/bin/rm -f -- "$SUPPORT_ROOT/AutomaticRefresh/run.lock/owner.pid"
/bin/rmdir "$SUPPORT_ROOT/AutomaticRefresh/run.lock"

echo '2026-08-28T12:00:00Z' > "$EXPIRATION_FILE"
: > "$REFRESH_LOG"
run_automatic DESKTOP_WIDGETS_REFRESHED_EXPIRATION='2026-09-03T12:00:00Z' >/dev/null
[[ "$(/usr/bin/grep -c 'refresh' "$REFRESH_LOG")" == "1" ]] || fail "near-expiry profile should invoke one guarded refresh"
assert_equal "refreshed" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "successful refresh should publish status"
run_automatic >/dev/null
[[ "$(/usr/bin/grep -c 'refresh' "$REFRESH_LOG")" == "1" ]] || fail "refreshed profile should make the next check idempotent"

echo '2026-08-28T12:00:00Z' > "$EXPIRATION_FILE"
: > "$NOTIFICATION_LOG"
run_automatic >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "unchanged signing deadline should not be reported as refreshed"
assert_equal "renewal-not-extended" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "unchanged signing deadline should record a stable error code"
[[ -s "$NOTIFICATION_LOG" ]] || fail "unchanged signing deadline should notify the user"

echo '2026-08-28T12:00:00Z' > "$EXPIRATION_FILE"
: > "$NOTIFICATION_LOG"
run_automatic DESKTOP_WIDGETS_TEST_REFRESH_RESULT=failure >/dev/null
run_automatic DESKTOP_WIDGETS_TEST_REFRESH_RESULT=failure >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "failed refresh should publish attention state"
[[ "$(/usr/bin/wc -l < "$NOTIFICATION_LOG" | /usr/bin/tr -d ' ')" == "1" ]] || fail "same failure should notify at most once per day"

/bin/rm -f -- "$EXPIRATION_FILE"
: > "$NOTIFICATION_LOG"
run_automatic >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "missing profile should publish attention state"
assert_equal "invalid-signing-state" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "missing signing fixture should record a stable error code"
[[ -s "$NOTIFICATION_LOG" ]] || fail "missing profile should notify the user"

echo 'not-an-expiration-date' > "$EXPIRATION_FILE"
: > "$NOTIFICATION_LOG"
run_automatic >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "unreadable profile expiration should publish attention state"
assert_equal "invalid-expiration" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "unreadable expiration should record a stable error code"
[[ -s "$NOTIFICATION_LOG" ]] || fail "unreadable profile expiration should notify the user"

profileless_healthy_signed_at="$(desktop_widgets_automatic_expiration_epoch '2026-08-26T12:00:00Z')"
: > "$REFRESH_LOG"
run_profileless_automatic "$profileless_healthy_signed_at" >/dev/null
[[ ! -s "$REFRESH_LOG" ]] || fail "healthy profile-free signature check must not start Xcode"
assert_equal "healthy" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "healthy profile-free build should publish status"

profileless_near_signed_at="$(desktop_widgets_automatic_expiration_epoch '2026-08-22T12:00:00Z')"
: > "$REFRESH_LOG"
run_profileless_automatic "$profileless_near_signed_at" >/dev/null
[[ "$(/usr/bin/grep -c 'refresh' "$REFRESH_LOG")" == "1" ]] || fail "profile-free build inside the precautionary renewal window should refresh"

: > "$NOTIFICATION_LOG"
run_profileless_automatic "$profileless_healthy_signed_at" DESKTOP_WIDGETS_PROFILELESS_SIGNATURE_VALID=0 >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "invalid profile-free signature should publish attention state"
assert_equal "invalid-signing-state" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "invalid profile-free signature should record a stable error code"
[[ -s "$NOTIFICATION_LOG" ]] || fail "invalid profile-free signature should notify the user"

/bin/mv "$LOCAL_CONFIGURATION" "$TEST_ROOT/Local.xcconfig.missing"
: > "$NOTIFICATION_LOG"
run_automatic >/dev/null
assert_equal "needsAttention" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" State)" "missing local configuration should replace stale healthy status"
assert_equal "missing-local-configuration" "$(desktop_widgets_automatic_status_value "$STATUS_PATH" LastErrorCode)" "missing local configuration should record a stable error code"
[[ -s "$NOTIFICATION_LOG" ]] || fail "missing local configuration should notify the user"
/bin/mv "$TEST_ROOT/Local.xcconfig.missing" "$LOCAL_CONFIGURATION"

echo "PASS: Automatic refresh thresholds, no-op behavior, low-resource LaunchAgent, idempotency, failures, and exact-target safety are covered."
