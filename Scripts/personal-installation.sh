#!/bin/bash

set -euo pipefail

readonly MODE="${1:-install}"
readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly LIBRARY_SCRIPT="$SCRIPT_DIRECTORY/personal-installation-lib.sh"
readonly AUTOMATIC_LIBRARY_SCRIPT="$SCRIPT_DIRECTORY/automatic-refresh-lib.sh"

if [[ "$MODE" != "install" && "$MODE" != "refresh" ]]; then
    echo "Usage: $0 install|refresh" >&2
    exit 64
fi

# shellcheck source=Scripts/personal-installation-lib.sh
source "$LIBRARY_SCRIPT"
# shellcheck source=Scripts/automatic-refresh-lib.sh
source "$AUTOMATIC_LIBRARY_SCRIPT"

readonly USER_HOME="${DESKTOP_WIDGETS_HOME:-$HOME}"
readonly SUPPORT_ROOT="${DESKTOP_WIDGETS_SUPPORT_ROOT:-$USER_HOME/Library/Application Support/Desktop Widgets}"
readonly STABLE_SOURCE_ROOT="$SUPPORT_ROOT/Installer"
readonly BUILD_ROOT="$SUPPORT_ROOT/Build"
readonly LOG_DIRECTORY="${DESKTOP_WIDGETS_LOG_DIRECTORY:-$USER_HOME/Library/Logs/Desktop Widgets}"
readonly DIAGNOSTIC_LOG="$LOG_DIRECTORY/installation.log"
readonly INSTALL_DESTINATION="${DESKTOP_WIDGETS_INSTALL_DESTINATION:-$(desktop_widgets_expected_install_destination)}"
readonly LOCAL_CONFIGURATION="${DESKTOP_WIDGETS_LOCAL_CONFIGURATION:-$SOURCE_ROOT/Local.xcconfig}"
readonly DRY_RUN="${DESKTOP_WIDGETS_DRY_RUN:-0}"
readonly SCHEDULED_RUN="${DESKTOP_WIDGETS_SCHEDULED:-0}"
APP_WAS_REPLACED=0

/bin/mkdir -p "$LOG_DIRECTORY"

failure_report() {
    local status=$?
    echo
    desktop_widgets_installation_failure_message "$APP_WAS_REPLACED"
    echo "Diagnostic log: $DIAGNOSTIC_LOG"
    echo "If the message above does not explain the fix, open the log and share it; Apple Account addresses and credential-like values are redacted."
    exit "$status"
}
trap failure_report ERR

step() {
    echo
    echo "[$1/7] $2"
}

configure_automatic_refresh() {
    local choice="${DESKTOP_WIDGETS_AUTOMATIC_REFRESH_CHOICE:-}"
    local manager="$SOURCE_ROOT/Scripts/manage-automatic-refresh.sh"
    local prompt_was_shown=0

    if [[ "$MODE" != "install" ]]; then
        echo "Automatic maintenance schedule is unchanged."
        return 0
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN: offer optional automatic maintenance after installation"
        return 0
    fi

    if [[ -z "$choice" && -t 0 ]]; then
        prompt_was_shown=1
        choice="$(desktop_widgets_read_interactive_choice 'Turn on low-resource automatic maintenance? [Y/n] ')"
    fi
    choice="$(desktop_widgets_resolve_automatic_refresh_choice "$choice" "$prompt_was_shown")"

    case "$choice" in
    y|Y|yes|YES|Yes)
        if ! /bin/bash "$manager" enable; then
            echo "Automatic maintenance could not be enabled, but Desktop Widgets is installed." >&2
            echo "You can retry with Enable Automatic Refresh.command." >&2
        fi
        ;;
    n|N|no|NO|No)
        /bin/bash "$manager" disable || true
        ;;
    unchanged)
        echo "Automatic maintenance was left unchanged because no interactive choice was available."
        echo "Double-click Enable Automatic Refresh.command whenever you want to turn it on."
        ;;
    *)
        echo "Automatic maintenance was left unchanged because the answer was not recognized." >&2
        ;;
    esac
}

sync_installation_source() {
    local item
    local source_path
    local destination_path
    local items=(
        "Config"
        "DesktopWidgets.xcodeproj"
        "DesktopWidgetsApp"
        "DesktopWidgetsExtension"
        "Shared"
        "Scripts"
        "docs"
        "Install Desktop Widgets.command"
        "Refresh Desktop Widgets.command"
        "Enable Automatic Refresh.command"
        "Disable Automatic Refresh.command"
        "Installation Guide.md"
        "README.md"
    )

    if [[ "$SOURCE_ROOT" == "$STABLE_SOURCE_ROOT" || "$DRY_RUN" == "1" || "${DESKTOP_WIDGETS_SKIP_SOURCE_SYNC:-0}" == "1" ]]; then
        return 0
    fi

    /bin/mkdir -p "$STABLE_SOURCE_ROOT"
    for item in "${items[@]}"; do
        source_path="$SOURCE_ROOT/$item"
        [[ -e "$source_path" ]] || continue
        destination_path="$STABLE_SOURCE_ROOT/$item"
        /bin/mkdir -p "$(/usr/bin/dirname "$destination_path")"
        /usr/bin/ditto "$source_path" "$destination_path"
    done
    desktop_widgets_preserve_local_configuration "$LOCAL_CONFIGURATION" "$STABLE_SOURCE_ROOT/Local.xcconfig"

    echo "Kept a private refresh copy at $STABLE_SOURCE_ROOT"
    exec /usr/bin/env \
        DESKTOP_WIDGETS_HOME="$USER_HOME" \
        DESKTOP_WIDGETS_SUPPORT_ROOT="$SUPPORT_ROOT" \
        DESKTOP_WIDGETS_LOG_DIRECTORY="$LOG_DIRECTORY" \
        DESKTOP_WIDGETS_AUTOMATIC_REFRESH_CHOICE="${DESKTOP_WIDGETS_AUTOMATIC_REFRESH_CHOICE:-}" \
        /bin/bash "$STABLE_SOURCE_ROOT/Scripts/personal-installation.sh" "$MODE"
}

validate_signed_product() {
    local app_path="$1"
    local expected_team="$2"
    local expected_group="$3"
    local extension_path="$app_path/Contents/PlugIns/DesktopWidgetsExtension.appex"
    local validation_directory="$BUILD_ROOT/Validation"
    local app_entitlements="$validation_directory/app-entitlements.plist"
    local extension_entitlements="$validation_directory/extension-entitlements.plist"
    local app_team
    local extension_team
    local app_authority
    local extension_authority
    local bundle_path
    local profile_path
    local decoded_profile
    local profile_team
    local profile_group
    local embedded_profile_count=0

    [[ -d "$extension_path" ]] || {
        echo "The built app is missing its Desktop Widgets extension." >&2
        return 1
    }

    /usr/bin/codesign --verify --deep --strict "$app_path"
    /usr/bin/codesign --verify --strict "$extension_path"
    /bin/mkdir -p "$validation_directory"
    /usr/bin/codesign -d --entitlements :- "$app_path" > "$app_entitlements" 2>/dev/null
    /usr/bin/codesign -d --entitlements :- "$extension_path" > "$extension_entitlements" 2>/dev/null

    app_team="$(/usr/bin/codesign -dv --verbose=4 "$app_path" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -n 1)"
    extension_team="$(/usr/bin/codesign -dv --verbose=4 "$extension_path" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -n 1)"
    app_authority="$(/usr/bin/codesign -dv --verbose=4 "$app_path" 2>&1 | /usr/bin/sed -n 's/^Authority=//p' | /usr/bin/head -n 1)"
    extension_authority="$(/usr/bin/codesign -dv --verbose=4 "$extension_path" 2>&1 | /usr/bin/sed -n 's/^Authority=//p' | /usr/bin/head -n 1)"

    if [[ "$app_team" != "$expected_team" || "$extension_team" != "$expected_team" ]]; then
        echo "The app and widget were not signed by the selected Personal Team." >&2
        return 1
    fi
    if [[ "$app_authority" != Apple\ Development:* || "$extension_authority" != Apple\ Development:* ]]; then
        echo "The app and widget do not both have an Apple Development signature." >&2
        return 1
    fi
    if ! desktop_widgets_validate_required_entitlements "$app_entitlements" "$expected_group" app; then
        echo "The signed app is missing its required sandbox, App Group, or Calendar entitlement." >&2
        return 1
    fi
    if ! desktop_widgets_validate_required_entitlements "$extension_entitlements" "$expected_group" extension; then
        echo "The signed widget is missing its required sandbox, App Group, Calendar, or network entitlement." >&2
        return 1
    fi

    for bundle_path in "$app_path" "$extension_path"; do
        profile_path="$bundle_path/Contents/embedded.provisionprofile"
        [[ -f "$profile_path" ]] || continue
        embedded_profile_count=$((embedded_profile_count + 1))
        decoded_profile="$validation_directory/$(/usr/bin/basename "$bundle_path").profile.plist"
        /usr/bin/security cms -D -i "$profile_path" -o "$decoded_profile" >/dev/null
        profile_team="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$decoded_profile" 2>/dev/null || true)"
        profile_group="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.security.application-groups:0' "$decoded_profile" 2>/dev/null || true)"
        if [[ "$profile_team" != "$expected_team" || "$profile_group" != "$expected_group" ]]; then
            echo "The embedded profile does not grant the selected team and required App Group." >&2
            return 1
        fi
        if ! /usr/bin/plutil -extract ExpirationDate raw -o - "$decoded_profile" >/dev/null 2>&1; then
            echo "The embedded Personal Team profile has no readable expiration date." >&2
            return 1
        fi
    done

    if [[ "$embedded_profile_count" -eq 1 ]]; then
        echo "Xcode embedded a profile in only one product; refusing inconsistent provisioning state." >&2
        return 1
    elif [[ "$embedded_profile_count" -eq 2 ]]; then
        echo "Verified the Apple Development signatures, embedded profiles, and all required entitlements."
    else
        echo "Verified Xcode's profile-free macOS Apple Development signatures and all required entitlements."
    fi
}

install_built_app() {
    local built_app="$1"
    local destination="$2"
    local staging="${destination}.installing"
    local backup="${destination}.previous"

    desktop_widgets_is_safe_install_destination "$destination" || {
        echo "Refusing unsafe installation destination: $destination" >&2
        return 1
    }

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN: install $built_app at $destination"
        return 0
    fi

    /bin/mkdir -p "$(/usr/bin/dirname "$destination")"
    /bin/rm -rf -- "$staging" "$backup"
    /usr/bin/ditto "$built_app" "$staging"

    if [[ -e "$destination" ]]; then
        /bin/mv -- "$destination" "$backup"
    fi

    if ! /bin/mv -- "$staging" "$destination"; then
        [[ ! -e "$backup" ]] || /bin/mv -- "$backup" "$destination"
        return 1
    fi
    /bin/rm -rf -- "$backup"
    APP_WAS_REPLACED=1
    echo "Installed Desktop Widgets in your Applications folder."
}

run_xcode_build() {
    local developer_dir="$1"
    local project_path="$2"
    local derived_data_path="$3"
    local build_log="$BUILD_ROOT/latest-build.log"
    local arguments=()
    local status

    while IFS= read -r argument; do
        arguments+=("$argument")
    done < <(desktop_widgets_print_build_arguments "$project_path" "$derived_data_path")

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY RUN: DEVELOPER_DIR=$developer_dir xcodebuild ${arguments[*]}"
        return 0
    fi

    /bin/mkdir -p "$BUILD_ROOT"
    : > "$build_log"
    set +e
    DEVELOPER_DIR="$developer_dir" "$developer_dir/usr/bin/xcodebuild" "${arguments[@]}" 2>&1 \
        | desktop_widgets_redact \
        | /usr/bin/tee "$build_log"
    status="${PIPESTATUS[0]}"
    set -e

    if [[ "$status" -ne 0 ]]; then
        desktop_widgets_classify_build_failure "$build_log" >&2
        return "$status"
    fi
    echo "Xcode finished building Desktop Widgets."
}

desktop_widgets_run() {
echo "Desktop Widgets — friendly ${MODE}"
echo "Nothing here asks for, prints, or stores your Apple password or token."
echo "Diagnostic log: $DIAGNOSTIC_LOG"

step 1 "Preparing the reusable installer"
sync_installation_source

step 2 "Checking Xcode"
if ! SELECTED_DEVELOPER_DIR="$(desktop_widgets_resolve_developer_dir)"; then
    echo "Full Xcode is not installed." >&2
    echo "Install Xcode from the Mac App Store, open it once, then run this command again." >&2
    exit 1
fi
readonly SELECTED_DEVELOPER_DIR
if ! desktop_widgets_xcode_is_initialized "$SELECTED_DEVELOPER_DIR"; then
    echo "Xcode still needs its one-time setup." >&2
    echo "Open Xcode, accept its license, let it finish installing components, then run this command again." >&2
    exit 1
fi
echo "Xcode is installed and ready."

step 3 "Finding your free Personal Team"
PERSONAL_TEAMS="$(desktop_widgets_read_personal_teams || true)"
readonly PERSONAL_TEAMS
if [[ -z "$PERSONAL_TEAMS" ]]; then
    echo "No free Personal Team is available yet." >&2
    echo "Open Xcode > Settings > Accounts, press +, and sign in with your Apple Account." >&2
    echo "Xcode handles the sign-in securely; this installer never sees your password." >&2
    exit 1
fi
if ! PERSONAL_TEAM_ID="$(desktop_widgets_select_personal_team "$PERSONAL_TEAMS")"; then
    echo "A Personal Team could not be selected." >&2
    exit 1
fi
readonly PERSONAL_TEAM_ID
echo "Selected Personal Team $PERSONAL_TEAM_ID."

if [[ "${DESKTOP_WIDGETS_CAPABILITY_STATUS:-supported}" != "supported" ]]; then
    echo "Personal Team provisioning did not grant the required App Group capability. Desktop Widgets cannot safely run without it." >&2
    exit 1
fi

step 4 "Saving private signing settings"
desktop_widgets_write_local_configuration "$LOCAL_CONFIGURATION" "$PERSONAL_TEAM_ID"
readonly EXPECTED_APP_GROUP="$(desktop_widgets_local_value WIDGET_THEME_APP_GROUP "$LOCAL_CONFIGURATION")"

step 5 "Building and installing Desktop Widgets"
readonly DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
run_xcode_build "$SELECTED_DEVELOPER_DIR" "$SOURCE_ROOT/DesktopWidgets.xcodeproj" "$DERIVED_DATA_PATH"
readonly BUILT_APP="$DERIVED_DATA_PATH/Build/Products/Release/DesktopWidgets.app"
if [[ "$DRY_RUN" != "1" ]]; then
    [[ -d "$BUILT_APP" ]] || {
        echo "Xcode reported success but the built app was not found." >&2
        exit 1
    }
    validate_signed_product "$BUILT_APP" "$PERSONAL_TEAM_ID" "$EXPECTED_APP_GROUP"
fi
install_built_app "$BUILT_APP" "$INSTALL_DESTINATION"

step 6 "Refreshing the widget"
if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY RUN: refresh the installed widget runtime"
else
    WIDGET_REFRESH_DERIVED_DATA_ROOT="$DERIVED_DATA_PATH" \
        /bin/bash "$SOURCE_ROOT/Scripts/refresh-widget-runtime.sh" "$INSTALL_DESTINATION"
fi

step 7 "Setting up easy maintenance"
configure_automatic_refresh
if [[ "$SCHEDULED_RUN" == "1" ]]; then
    [[ "$DRY_RUN" != "1" ]] || echo "DRY RUN: scheduled maintenance leaves the app closed"
elif [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY RUN: open $INSTALL_DESTINATION"
else
    /usr/bin/open "$INSTALL_DESTINATION"
fi

trap - ERR
echo
echo "Desktop Widgets is ready."
echo "To add one: Control-click the desktop > Edit Widgets > search for Desktop Widgets."
echo "macOS requires you to place widgets yourself; the app cannot arrange the desktop."
echo "When enabled, automatic maintenance checks briefly each day and refreshes near free-signing expiration."
echo "Refresh Desktop Widgets.command remains the manual fallback."
echo "Diagnostic log: $DIAGNOSTIC_LOG"
}

desktop_widgets_automatic_rotate_log "$DIAGNOSTIC_LOG"
set +e
desktop_widgets_run 2>&1 | desktop_widgets_redact | /usr/bin/tee -a "$DIAGNOSTIC_LOG"
readonly INSTALLATION_STATUS="${PIPESTATUS[0]}"
set -e
exit "$INSTALLATION_STATUS"
