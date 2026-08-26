#!/bin/bash

set -euo pipefail

resolve_developer_dir() {
    if [[ -n "${XCODE_DEVELOPER_DIR:-}" ]]; then
        if [[ -x "$XCODE_DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
            echo "$XCODE_DEVELOPER_DIR"
            return
        fi
        echo "FAIL: XCODE_DEVELOPER_DIR does not point to a full Xcode installation." >&2
        return 1
    fi

    if [[ -n "${DEVELOPER_DIR:-}" ]]; then
        if [[ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
            echo "$DEVELOPER_DIR"
            return
        fi
        echo "FAIL: DEVELOPER_DIR does not point to a full Xcode installation." >&2
        return 1
    fi

    local system_selected
    system_selected="$(xcode-select --print-path 2>/dev/null || true)"
    if [[ -x "$system_selected/usr/bin/xcodebuild" ]]; then
        echo "$system_selected"
        return
    fi

    if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
        echo "/Applications/Xcode.app/Contents/Developer"
        return
    fi

    echo "FAIL: Select a full Xcode installation or set DEVELOPER_DIR." >&2
    return 1
}

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly PROJECT_PATH="$PROJECT_ROOT/DesktopWidgets.xcodeproj"
readonly SCHEME="DesktopWidgets"
readonly SHARED_SCHEME="$PROJECT_PATH/xcshareddata/xcschemes/DesktopWidgets.xcscheme"
readonly RUNTIME_REFRESH_SCRIPT="$PROJECT_ROOT/Scripts/refresh-widget-runtime.sh"
readonly PERSONAL_TEAM_SCRIPT="$PROJECT_ROOT/Scripts/configure-personal-team.sh"
readonly SIGNING_CONFIGURATION="$PROJECT_ROOT/Config/Signing.xcconfig"
SELECTED_DEVELOPER_DIR="$(resolve_developer_dir)"
readonly SELECTED_DEVELOPER_DIR
readonly VERIFY_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-verify.XXXXXX")"
readonly DERIVED_DATA_PATH="$VERIFY_DIRECTORY/DerivedData"
readonly TEST_RESULT_BUNDLE="$VERIFY_DIRECTORY/DesktopWidgetsTests.xcresult"

cleanup() {
    if [[ "${KEEP_WIDGET_VERIFY_ARTIFACTS:-0}" == "1" ]]; then
        echo "Verification artifacts kept at: $VERIFY_DIRECTORY"
        return
    fi

    if [[ -n "$VERIFY_DIRECTORY" && "$VERIFY_DIRECTORY" == *"/desktop-widgets-verify."* ]]; then
        rm -rf -- "$VERIFY_DIRECTORY"
    fi
}
trap cleanup EXIT

require_file() {
    local path="$1"
    local description="$2"

    if [[ ! -s "$path" ]]; then
        echo "FAIL: Missing $description at $path" >&2
        exit 1
    fi
}

require_contains() {
    local path="$1"
    local expected="$2"
    local description="$3"

    if ! grep -Fq "$expected" "$path"; then
        echo "FAIL: $description was not found in $path" >&2
        exit 1
    fi
}

require_file "$RUNTIME_REFRESH_SCRIPT" "widget runtime refresh script"
if [[ ! -x "$RUNTIME_REFRESH_SCRIPT" ]]; then
    echo "FAIL: Widget runtime refresh script is not executable" >&2
    exit 1
fi
DEVELOPER_DIR="$SELECTED_DEVELOPER_DIR" /bin/bash -n "$RUNTIME_REFRESH_SCRIPT"
require_contains "$SHARED_SCHEME" "refresh-widget-runtime.sh" "Xcode Run widget runtime refresh action"

require_file "$PERSONAL_TEAM_SCRIPT" "Personal Team setup script"
if [[ ! -x "$PERSONAL_TEAM_SCRIPT" ]]; then
    echo "FAIL: Personal Team setup script is not executable" >&2
    exit 1
fi
/bin/bash -n "$PERSONAL_TEAM_SCRIPT"
require_file "$SIGNING_CONFIGURATION" "shared signing configuration"
require_contains "$SIGNING_CONFIGURATION" "#include? \"../Local.xcconfig\"" "optional local signing include"
require_contains "$SIGNING_CONFIGURATION" "CODE_SIGN_STYLE = Automatic" "automatic signing policy"
require_contains "$SIGNING_CONFIGURATION" 'DEVELOPMENT_TEAM = $(LOCAL_DEVELOPMENT_TEAM)' "local Personal Team setting"

readonly CERTIFICATE_SUBJECT_FIXTURE='subject=UID=ABC123DE45,CN=Apple Development: Example Developer (ABC123DE45),OU=ZYX987WV65,O=Example Developer,C=US'
readonly FIXTURE_TEAM_ID="$("$PERSONAL_TEAM_SCRIPT" --parse-certificate-subject "$CERTIFICATE_SUBJECT_FIXTURE")"
if [[ "$FIXTURE_TEAM_ID" != "ZYX987WV65" ]]; then
    echo "FAIL: Personal Team setup must read the certificate OU instead of its display-name identifier" >&2
    exit 1
fi

readonly SIGNING_REFERENCE_COUNT="$(grep -c 'baseConfigurationReference = F00000000000000000000019 /\* Signing.xcconfig \*/;' "$PROJECT_PATH/project.pbxproj")"
if [[ "$SIGNING_REFERENCE_COUNT" != "4" ]]; then
    echo "FAIL: Expected app and extension Debug/Release configurations to share Signing.xcconfig" >&2
    exit 1
fi
if grep -Eq 'DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*[A-Z0-9]{10}' "$PROJECT_PATH/project.pbxproj" "$SIGNING_CONFIGURATION"; then
    echo "FAIL: A machine-specific Apple Team ID is present in tracked signing configuration" >&2
    exit 1
fi
if ! git -C "$PROJECT_ROOT" check-ignore --quiet Local.xcconfig; then
    echo "FAIL: Local.xcconfig must remain ignored by Git" >&2
    exit 1
fi

echo "[1/3] Running the complete Debug test suite"
DEVELOPER_DIR="$SELECTED_DEVELOPER_DIR" xcodebuild test -quiet \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -resultBundlePath "$TEST_RESULT_BUNDLE" \
    -enableCodeCoverage YES \
    CODE_SIGNING_ALLOWED=NO

echo "Test coverage by target"
DEVELOPER_DIR="$SELECTED_DEVELOPER_DIR" xcrun xccov view \
    --report \
    --only-targets \
    "$TEST_RESULT_BUNDLE"

echo "[2/3] Building a fresh unsigned Release app and widget extension"
DEVELOPER_DIR="$SELECTED_DEVELOPER_DIR" xcodebuild build -quiet \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO

readonly APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/DesktopWidgets.app"
readonly EXTENSION_PATH="$APP_PATH/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly EXTENSION_INFO="$EXTENSION_PATH/Contents/Info.plist"
readonly EXTENSION_BINARY="$EXTENSION_PATH/Contents/MacOS/DesktopWidgetsExtension"
readonly APP_INTENTS_METADATA="$EXTENSION_PATH/Contents/Resources/Metadata.appintents/extract.actionsdata"
readonly EXTENSION_STRINGS="$VERIFY_DIRECTORY/extension-strings.txt"

echo "[3/3] Checking the embedded extension, widget identities, and editor metadata"
require_file "$APP_PATH/Contents/Info.plist" "Release app bundle"
require_file "$EXTENSION_INFO" "embedded WidgetKit extension"
require_file "$EXTENSION_BINARY" "widget extension executable"
require_file "$APP_INTENTS_METADATA" "App Intents metadata"

readonly EXTENSION_POINT="$(/usr/libexec/PlistBuddy -c "Print :NSExtension:NSExtensionPointIdentifier" "$EXTENSION_INFO")"
if [[ "$EXTENSION_POINT" != "com.apple.widgetkit-extension" ]]; then
    echo "FAIL: Expected a WidgetKit extension, found $EXTENSION_POINT" >&2
    exit 1
fi

require_contains "$APP_INTENTS_METADATA" "TimeAndDateStringConfigurationIntent" "Time & Date configuration metadata"
require_contains "$APP_INTENTS_METADATA" "WeatherV8ConfigurationIntent" "Weather configuration metadata"
require_contains "$APP_INTENTS_METADATA" "WeatherV8CityEntity" "Weather searchable city entity"
require_contains "$APP_INTENTS_METADATA" "BatteryConfigurationIntent" "Battery configuration metadata"
require_contains "$APP_INTENTS_METADATA" "PreviousCalendarMonthIntent" "Calendar previous-month interaction metadata"
require_contains "$APP_INTENTS_METADATA" "NextCalendarMonthIntent" "Calendar next-month interaction metadata"
require_contains "$APP_INTENTS_METADATA" "CurrentCalendarMonthIntent" "Calendar current-month interaction metadata"
require_contains "$APP_INTENTS_METADATA" "CalendarConfigurationIntent" "Calendar configuration metadata"
if ! jq -e '.actions.CalendarConfigurationIntent.parameters[] | select(.name == "viewMode" and .dynamicOptionsSupport > 0)' "$APP_INTENTS_METADATA" >/dev/null; then
    echo "FAIL: Calendar View is not exported as a dynamic configuration option" >&2
    exit 1
fi
if ! jq -e '.actions.CalendarConfigurationIntent.parameters[] | select(.name == "showEvents" and .valueType.primitive.wrapper.typeIdentifier == 1)' "$APP_INTENTS_METADATA" >/dev/null; then
    echo "FAIL: Calendar event indicator toggle is missing from App Intents metadata" >&2
    exit 1
fi
for parameter in showPower showStatus showEstimate showUpdated; do
    if ! jq -e --arg parameter "$parameter" '.actions.BatteryConfigurationIntent.parameters[] | select(.name == $parameter and .valueType.primitive.wrapper.typeIdentifier == 1 and .typeSpecificMetadata[1].int.wrapper == 1)' "$APP_INTENTS_METADATA" >/dev/null; then
        echo "FAIL: Battery $parameter toggle is missing from App Intents metadata" >&2
        exit 1
    fi
done
if grep -Fq 'citySearch' "$APP_INTENTS_METADATA"; then
    echo "FAIL: Weather metadata still exposes the retired Search City field" >&2
    exit 1
fi
if ! jq -e '.actions.WeatherV8ConfigurationIntent.parameters[] | select(.name == "city") | (.dynamicOptionsSupport > 0 and .valueType.entity.wrapper.typeName == "WeatherV8CityEntity")' "$APP_INTENTS_METADATA" >/dev/null; then
    echo "FAIL: Weather City parameter is not exported as a searchable city entity" >&2
    exit 1
fi
if ! jq -e '.entities.WeatherV8CityEntity.defaultQueryIdentifier | endswith(".WeatherV8CityQuery")' "$APP_INTENTS_METADATA" >/dev/null; then
    echo "FAIL: Weather city entity does not export its string-search query" >&2
    exit 1
fi
if grep -Fq 'WeatherV7ConfigurationIntent' "$APP_INTENTS_METADATA"; then
    echo "FAIL: Weather metadata still contains the retired two-field city configuration" >&2
    exit 1
fi
require_contains "$APP_INTENTS_METADATA" "detailPreset" "Weather preset editor parameter"

strings "$EXTENSION_BINARY" > "$EXTENSION_STRINGS"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.time-and-date.configurable-v2-string" "Time & Date widget identity"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.weather.entity-search-v8" "Weather widget identity"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.battery.configurable-v2" "Battery widget identity"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.calendar.configurable-v2" "Calendar widget identity"
readonly APP_CALENDAR_USAGE="$(/usr/libexec/PlistBuddy -c 'Print :NSCalendarsFullAccessUsageDescription' "$APP_PATH/Contents/Info.plist")"
readonly EXTENSION_CALENDAR_USAGE="$(/usr/libexec/PlistBuddy -c 'Print :NSCalendarsFullAccessUsageDescription' "$EXTENSION_INFO")"
if [[ -z "$APP_CALENDAR_USAGE" || -z "$EXTENSION_CALENDAR_USAGE" ]]; then
    echo "FAIL: Calendar full-access usage descriptions must be present in app and extension" >&2
    exit 1
fi
require_contains "$PROJECT_ROOT/DesktopWidgetsApp/DesktopWidgetsApp.entitlements" "com.apple.security.personal-information.calendars" "app Calendar sandbox entitlement"
require_contains "$PROJECT_ROOT/DesktopWidgetsExtension/DesktopWidgetsExtension.entitlements" "com.apple.security.personal-information.calendars" "extension Calendar sandbox entitlement"

echo "PASS: All four widgets passed behavior tests, Release compilation, embedding, identity, and editor-metadata checks."
