#!/bin/bash

set -euo pipefail

resolve_developer_dir() {
    if [[ -n "${XCODE_DEVELOPER_DIR:-}" ]]; then
        echo "$XCODE_DEVELOPER_DIR"
        return
    fi

    if [[ -n "${DEVELOPER_DIR:-}" ]]; then
        echo "$DEVELOPER_DIR"
        return
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
readonly SELECTED_DEVELOPER_DIR="$(resolve_developer_dir)"
readonly VERIFY_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-verify.XXXXXX")"
readonly DERIVED_DATA_PATH="$VERIFY_DIRECTORY/DerivedData"

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

echo "[1/3] Running the complete Debug test suite"
DEVELOPER_DIR="$SELECTED_DEVELOPER_DIR" xcodebuild test -quiet \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO

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
require_contains "$APP_INTENTS_METADATA" "PresetWeatherConfigurationIntent" "Weather configuration metadata"
require_contains "$APP_INTENTS_METADATA" "detailPreset" "Weather preset editor parameter"

strings "$EXTENSION_BINARY" > "$EXTENSION_STRINGS"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.time-and-date.configurable-v2-string" "Time & Date widget identity"
require_contains "$EXTENSION_STRINGS" "com.joshuawyadao.desktop-widgets.weather.presets-v3" "Weather widget identity"

echo "PASS: Both widgets passed behavior tests, Release compilation, embedding, identity, and editor-metadata checks."
