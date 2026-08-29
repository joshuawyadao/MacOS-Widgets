#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly LIBRARY_SCRIPT="$SCRIPT_DIRECTORY/personal-installation-lib.sh"
readonly INSTALLATION_SCRIPT="$SCRIPT_DIRECTORY/personal-installation.sh"
readonly TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-install-test.XXXXXX")"
readonly TEST_HOME="$TEST_ROOT/Home"
readonly LOCAL_CONFIGURATION="$TEST_ROOT/Local.xcconfig"
readonly TEAM_FIXTURE="$TEST_ROOT/teams.txt"
readonly FAKE_DEVELOPER_DIR="$TEST_ROOT/Xcode.app/Contents/Developer"
readonly FAKE_XCODEBUILD="$FAKE_DEVELOPER_DIR/usr/bin/xcodebuild"
readonly TEAM_ID="ABC123DE45"

cleanup() {
    if [[ -n "$TEST_ROOT" && "$TEST_ROOT" == *"/desktop-widgets-install-test."* ]]; then
        /bin/rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

# shellcheck source=Scripts/personal-installation-lib.sh
source "$LIBRARY_SCRIPT"

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

assert_rejects() {
    local description="$1"
    shift
    if "$@"; then
        fail "$description"
    fi
}

/bin/mkdir -p "$TEST_HOME" "$FAKE_DEVELOPER_DIR/usr/bin"
/usr/bin/printf '%s\n' \
    '{' \
    '    "ACCOUNT-ONE" = (' \
    '        {' \
    '            isFreeProvisioningTeam = 1;' \
    "            teamID = $TEAM_ID;" \
    '            teamName = "Friendly Person (Personal Team)";' \
    '        },' \
    '        {' \
    '            isFreeProvisioningTeam = 0;' \
    '            teamID = PAID123456;' \
    '            teamName = "Paid Team";' \
    '        }' \
    '    );' \
    '}' > "$TEAM_FIXTURE"

parsed_teams="$(desktop_widgets_parse_personal_teams < "$TEAM_FIXTURE")"
assert_equal "$TEAM_ID" "$(/usr/bin/printf '%s\n' "$parsed_teams" | /usr/bin/awk -F '\t' '{ print $1 }')" "Personal Team parser should return the free team"
assert_contains "$parsed_teams" "Friendly Person (Personal Team)" "Personal Team parser should retain the friendly team name"
[[ "$parsed_teams" != *"PAID123456"* ]] || fail "Personal Team parser included a paid team"

choice_prompt_log="$TEST_ROOT/choice-prompt.log"
choice_output="$(/usr/bin/printf '2\n' | desktop_widgets_read_interactive_choice 'Choose a team [1-2]: ' 2> "$choice_prompt_log")"
assert_equal "2" "$choice_output" "interactive choices should accept a piped fallback when no terminal is attached"
assert_contains "$(/bin/cat "$choice_prompt_log")" "Choose a team [1-2]:" "interactive choices should keep their prompt visible"

multiple_personal_teams="$(/usr/bin/printf '%s\t%s\n%s\t%s\n' \
    "$TEAM_ID" 'Friendly Person (Personal Team)' \
    'ZYX987WV65' 'Second Person (Personal Team)')"
selected_team="$(DESKTOP_WIDGETS_TEAM_SELECTION=2 desktop_widgets_select_personal_team "$multiple_personal_teams" 2> "$TEST_ROOT/team-selection.log")"
assert_equal "ZYX987WV65" "$selected_team" "multiple Personal Teams should honor the supplied numbered choice"
assert_contains "$(/bin/cat "$TEST_ROOT/team-selection.log")" "Choose a team [1-2]: 2" "supplied team choices should be logged without hiding the prompt"

identifier_values="$(desktop_widgets_identifier_values "$TEAM_ID")"
generated_app_identifier="$(echo "$identifier_values" | /usr/bin/sed -n '1p')"
generated_extension_identifier="$(echo "$identifier_values" | /usr/bin/sed -n '2p')"
assert_equal "io.desktopwidgets.personal.abc123de45.app" "$generated_app_identifier" "app identifier should be stable and team-derived"
assert_equal "io.desktopwidgets.personal.abc123de45.app.widgets" "$generated_extension_identifier" "extension identifier should be stable, team-derived, and prefixed by its parent app"
[[ "$generated_extension_identifier" == "$generated_app_identifier".* ]] || fail "embedded extension identifier must begin with the parent app identifier"
assert_equal "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" "$(echo "$identifier_values" | /usr/bin/sed -n '3p')" "App Group should be stable and team-prefixed"

desktop_widgets_write_local_configuration "$LOCAL_CONFIGURATION" "$TEAM_ID" >/dev/null
first_configuration="$(/bin/cat "$LOCAL_CONFIGURATION")"
desktop_widgets_write_local_configuration "$LOCAL_CONFIGURATION" "$TEAM_ID" >/dev/null
second_configuration="$(/bin/cat "$LOCAL_CONFIGURATION")"
assert_equal "$first_configuration" "$second_configuration" "repeated local configuration should be idempotent"
assert_contains "$first_configuration" "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" "local configuration should include the selected team"
assert_contains "$first_configuration" "DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER = io.desktopwidgets.personal.abc123de45.app" "local configuration should include the stable app identifier"
assert_contains "$first_configuration" 'DESKTOP_WIDGETS_ENABLE_AUTOMATIC_REFRESH_COMMAND_PATH = $(HOME)/Library/Application Support/Desktop Widgets/Installer/Enable Automatic Refresh.command' "local configuration should expose the stable automatic-refresh helper"
assert_contains "$first_configuration" 'DESKTOP_WIDGETS_DISABLE_AUTOMATIC_REFRESH_COMMAND_PATH = $(HOME)/Library/Application Support/Desktop Widgets/Installer/Disable Automatic Refresh.command' "local configuration should expose the stable disable helper"
[[ "$(/usr/bin/stat -f '%Lp' "$LOCAL_CONFIGURATION")" == "600" ]] || fail "local configuration should be private"

legacy_configuration="$TEST_ROOT/Legacy.xcconfig"
/usr/bin/printf '%s\n' "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" > "$legacy_configuration"
desktop_widgets_write_local_configuration "$legacy_configuration" "$TEAM_ID" >/dev/null
assert_equal "com.joshuawyadao.DesktopWidgets" "$(desktop_widgets_local_value DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER "$legacy_configuration")" "legacy configuration should preserve the established app identifier"
assert_equal "$TEAM_ID.com.joshuawyadao.desktop-widgets" "$(desktop_widgets_local_value WIDGET_THEME_APP_GROUP "$legacy_configuration")" "legacy configuration should preserve the established App Group suffix"
assert_rejects "configuration must not overwrite another team" desktop_widgets_write_local_configuration "$legacy_configuration" ZYX987WV65

stable_legacy_configuration="$TEST_ROOT/StableInstaller/Local.xcconfig"
desktop_widgets_preserve_local_configuration "$legacy_configuration" "$stable_legacy_configuration"
assert_equal "$(/bin/cat "$legacy_configuration")" "$(/bin/cat "$stable_legacy_configuration")" "stable installer copy should retain legacy signing identifiers"
[[ "$(/usr/bin/stat -f '%Lp' "$stable_legacy_configuration")" == "600" ]] || fail "preserved stable signing configuration should remain private"
/usr/bin/printf '%s\n' 'LOCAL_DEVELOPMENT_TEAM = ZYX987WV65' > "$TEST_ROOT/replacement.xcconfig"
desktop_widgets_preserve_local_configuration "$TEST_ROOT/replacement.xcconfig" "$stable_legacy_configuration"
assert_equal "$TEAM_ID" "$(desktop_widgets_local_value LOCAL_DEVELOPMENT_TEAM "$stable_legacy_configuration")" "stable installer copy should not overwrite existing signing settings"

generated_old_configuration="$TEST_ROOT/GeneratedOld.xcconfig"
/usr/bin/printf '%s\n' \
    "LOCAL_DEVELOPMENT_TEAM = $TEAM_ID" \
    "DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER = io.desktopwidgets.personal.abc123de45.app" \
    "DESKTOP_WIDGETS_EXTENSION_BUNDLE_IDENTIFIER = io.desktopwidgets.personal.abc123de45.widgets" \
    "WIDGET_THEME_APP_GROUP = $TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" > "$generated_old_configuration"
desktop_widgets_write_local_configuration "$generated_old_configuration" "$TEAM_ID" >/dev/null
assert_equal "io.desktopwidgets.personal.abc123de45.app" "$(desktop_widgets_local_value DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER "$generated_old_configuration")" "generated configuration migration should preserve the app identifier"
assert_equal "io.desktopwidgets.personal.abc123de45.app.widgets" "$(desktop_widgets_local_value DESKTOP_WIDGETS_EXTENSION_BUNDLE_IDENTIFIER "$generated_old_configuration")" "generated configuration migration should repair the embedded extension prefix"
assert_equal "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" "$(desktop_widgets_local_value WIDGET_THEME_APP_GROUP "$generated_old_configuration")" "generated configuration migration should preserve the App Group"

app_entitlements_fixture="$TEST_ROOT/app-entitlements.plist"
extension_entitlements_fixture="$TEST_ROOT/extension-entitlements.plist"
/usr/bin/plutil -create xml1 "$app_entitlements_fixture"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.app-sandbox bool true' "$app_entitlements_fixture"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.application-groups array' "$app_entitlements_fixture"
/usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string $TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" "$app_entitlements_fixture"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.personal-information.calendars bool true' "$app_entitlements_fixture"
/bin/cp "$app_entitlements_fixture" "$extension_entitlements_fixture"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.network.client bool true' "$extension_entitlements_fixture"
desktop_widgets_validate_required_entitlements "$app_entitlements_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" app || fail "profile-free app should accept the complete unrestricted entitlement contract"
desktop_widgets_validate_required_entitlements "$extension_entitlements_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" extension || fail "profile-free widget should accept the complete unrestricted entitlement contract"

missing_group_fixture="$TEST_ROOT/missing-group-entitlements.plist"
/bin/cp "$app_entitlements_fixture" "$missing_group_fixture"
/usr/libexec/PlistBuddy -c 'Delete :com.apple.security.application-groups' "$missing_group_fixture"
assert_rejects "profile-free validation must reject a missing App Group" desktop_widgets_validate_required_entitlements "$missing_group_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" app

missing_sandbox_fixture="$TEST_ROOT/missing-sandbox-entitlements.plist"
/bin/cp "$app_entitlements_fixture" "$missing_sandbox_fixture"
/usr/libexec/PlistBuddy -c 'Delete :com.apple.security.app-sandbox' "$missing_sandbox_fixture"
assert_rejects "profile-free validation must reject a missing sandbox" desktop_widgets_validate_required_entitlements "$missing_sandbox_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" app

missing_calendar_fixture="$TEST_ROOT/missing-calendar-entitlements.plist"
/bin/cp "$app_entitlements_fixture" "$missing_calendar_fixture"
/usr/libexec/PlistBuddy -c 'Delete :com.apple.security.personal-information.calendars' "$missing_calendar_fixture"
assert_rejects "profile-free validation must reject missing Calendar access" desktop_widgets_validate_required_entitlements "$missing_calendar_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" app

missing_network_fixture="$TEST_ROOT/missing-network-entitlements.plist"
/bin/cp "$app_entitlements_fixture" "$missing_network_fixture"
assert_rejects "profile-free widget validation must reject missing network access" desktop_widgets_validate_required_entitlements "$missing_network_fixture" "$TEAM_ID.io.desktopwidgets.personal.abc123de45.shared" extension

expected_destination="$TEST_HOME/Applications/Desktop Widgets.app"
DESKTOP_WIDGETS_HOME="$TEST_HOME" desktop_widgets_is_safe_install_destination "$expected_destination" || fail "user Applications destination should be allowed"
assert_rejects "system Applications destination must be rejected" env DESKTOP_WIDGETS_HOME="$TEST_HOME" bash -c 'source "$1"; desktop_widgets_is_safe_install_destination "/Applications/Desktop Widgets.app"' _ "$LIBRARY_SCRIPT"
assert_rejects "another app destination must be rejected" env DESKTOP_WIDGETS_HOME="$TEST_HOME" bash -c 'source "$1"; desktop_widgets_is_safe_install_destination "$2"' _ "$LIBRARY_SCRIPT" "$TEST_HOME/Applications/Other.app"

build_arguments="$(desktop_widgets_print_build_arguments "$PROJECT_ROOT/DesktopWidgets.xcodeproj" "$TEST_ROOT/DerivedData")"
assert_contains "$build_arguments" "-allowProvisioningUpdates" "build command should allow automatic provisioning updates"
assert_contains "$build_arguments" "-quiet" "friendly build command should suppress routine Xcode noise"
assert_contains "$build_arguments" "Release" "build command should use Release configuration"
[[ "$build_arguments" != *"$TEAM_ID"* ]] || fail "build command should obtain the team from ignored configuration"
assert_contains "$(/bin/cat "$INSTALLATION_SCRIPT")" "desktop_widgets_read_interactive_choice 'Turn on low-resource automatic maintenance? [Y/n] '" "interactive maintenance choice should use the shared visible prompt helper"
assert_contains "$(/bin/cat "$LIBRARY_SCRIPT")" 'selection="$(desktop_widgets_read_interactive_choice' "Personal Team selection should use the shared visible prompt helper"

capability_log="$TEST_ROOT/capability.log"
echo "Personal Teams do not support the App Groups capability" > "$capability_log"
assert_contains "$(desktop_widgets_classify_build_failure "$capability_log")" "cannot safely run" "capability failures should explain why functionality is not removed"
provisioning_log="$TEST_ROOT/provisioning.log"
echo "Provisioning profile could not be created" > "$provisioning_log"
assert_contains "$(desktop_widgets_classify_build_failure "$provisioning_log")" "free provisioning" "provisioning failures should provide an Xcode recovery step"

write_fake_xcodebuild() {
    local mode="$1"
    /usr/bin/printf '%s\n' \
        '#!/bin/bash' \
        'set -euo pipefail' \
        'if [[ "${1:-}" == "-checkFirstLaunchStatus" ]]; then' \
        "    [[ \"$mode\" != \"uninitialized\" ]]" \
        '    exit' \
        'fi' \
        "if [[ \"$mode\" == \"provisioning-failure\" ]]; then" \
        '    echo "Provisioning profile could not be created" >&2' \
        '    exit 65' \
        'fi' \
        'exit 0' > "$FAKE_XCODEBUILD"
    /bin/chmod +x "$FAKE_XCODEBUILD"
}

run_installer() {
    local mode="$1"
    shift
    env \
        DESKTOP_WIDGETS_HOME="$TEST_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$TEST_ROOT/Support" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$TEST_ROOT/Logs" \
        DESKTOP_WIDGETS_LOCAL_CONFIGURATION="$LOCAL_CONFIGURATION" \
        DESKTOP_WIDGETS_XCODE_DEVELOPER_DIR="$FAKE_DEVELOPER_DIR" \
        DESKTOP_WIDGETS_TEAM_PREFERENCES_FIXTURE="$TEAM_FIXTURE" \
        DESKTOP_WIDGETS_SKIP_SOURCE_SYNC=1 \
        "$@" \
        /bin/bash "$INSTALLATION_SCRIPT" "$mode" 2>&1
}

missing_xcode_output="$(env DESKTOP_WIDGETS_HOME="$TEST_HOME" DESKTOP_WIDGETS_XCODE_DEVELOPER_DIR="$TEST_ROOT/Missing.app/Contents/Developer" DESKTOP_WIDGETS_SKIP_SOURCE_SYNC=1 /bin/bash "$INSTALLATION_SCRIPT" install 2>&1 || true)"
assert_contains "$missing_xcode_output" "Full Xcode is not installed" "missing Xcode should fail with an actionable message"

write_fake_xcodebuild uninitialized
uninitialized_output="$(run_installer install DESKTOP_WIDGETS_DRY_RUN=1 || true)"
assert_contains "$uninitialized_output" "one-time setup" "uninitialized Xcode should explain the required action"

write_fake_xcodebuild ready
empty_fixture="$TEST_ROOT/no-teams.txt"
echo '{}' > "$empty_fixture"
no_team_output="$(env DESKTOP_WIDGETS_HOME="$TEST_HOME" DESKTOP_WIDGETS_XCODE_DEVELOPER_DIR="$FAKE_DEVELOPER_DIR" DESKTOP_WIDGETS_TEAM_PREFERENCES_FIXTURE="$empty_fixture" DESKTOP_WIDGETS_SKIP_SOURCE_SYNC=1 DESKTOP_WIDGETS_DRY_RUN=1 /bin/bash "$INSTALLATION_SCRIPT" install 2>&1 || true)"
assert_contains "$no_team_output" "No free Personal Team" "missing account should explain how to sign into Xcode"

unsupported_output="$(run_installer install DESKTOP_WIDGETS_DRY_RUN=1 DESKTOP_WIDGETS_CAPABILITY_STATUS=unsupported || true)"
assert_contains "$unsupported_output" "required App Group capability" "unavailable capability should stop without removing functionality"

write_fake_xcodebuild provisioning-failure
failed_provisioning_output="$(run_installer install || true)"
assert_contains "$failed_provisioning_output" "free provisioning" "failed provisioning should be classified"

write_fake_xcodebuild ready
/bin/mkdir -p "$expected_destination"
before_refresh="$(/bin/cat "$LOCAL_CONFIGURATION")"
first_refresh_output="$(run_installer refresh DESKTOP_WIDGETS_DRY_RUN=1)"
second_refresh_output="$(run_installer refresh DESKTOP_WIDGETS_DRY_RUN=1)"
install_dry_run_output="$(run_installer install DESKTOP_WIDGETS_DRY_RUN=1)"
after_refresh="$(/bin/cat "$LOCAL_CONFIGURATION")"
assert_equal "$before_refresh" "$after_refresh" "repeated refresh should not churn signing configuration"
assert_contains "$first_refresh_output" "DRY RUN: install" "existing installation refresh should use the safe dry-run install path"
assert_contains "$second_refresh_output" "Desktop Widgets is ready" "a repeated refresh should remain successful"
maintenance_line="$(/usr/bin/printf '%s\n' "$install_dry_run_output" | /usr/bin/grep -n -F 'DRY RUN: offer optional automatic maintenance' | /usr/bin/cut -d: -f1)"
open_line="$(/usr/bin/printf '%s\n' "$install_dry_run_output" | /usr/bin/grep -n -F 'DRY RUN: open' | /usr/bin/cut -d: -f1)"
[[ -n "$maintenance_line" && -n "$open_line" && "$maintenance_line" -lt "$open_line" ]] \
    || fail "the companion app should open only after installer maintenance setup completes"

scheduled_refresh_output="$(run_installer refresh DESKTOP_WIDGETS_DRY_RUN=1 DESKTOP_WIDGETS_SCHEDULED=1)"
assert_contains "$scheduled_refresh_output" "scheduled maintenance leaves the app closed" "scheduled refresh should not interrupt the user by opening the app"
[[ "$scheduled_refresh_output" != *"DRY RUN: open"* ]] || fail "scheduled refresh should not construct an app-open action"

redacted="$(echo 'account person@example.com token=super-secret' | desktop_widgets_redact)"
assert_contains "$redacted" "[redacted Apple Account]" "diagnostic logging should redact Apple Account addresses"
[[ "$redacted" != *"super-secret"* ]] || fail "diagnostic logging should redact credential-like values"

echo "PASS: Personal installation parsing, configuration, safety, failures, and idempotent refresh behavior are covered."
