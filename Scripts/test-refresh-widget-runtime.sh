#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REFRESH_SCRIPT="$SCRIPT_DIRECTORY/refresh-widget-runtime.sh"
readonly TEMPORARY_ROOT="${TMPDIR:-/tmp}"
readonly TEST_DIRECTORY="$(cd "$(mktemp -d "${TEMPORARY_ROOT%/}/desktop-widget-refresh-test.XXXXXX")" && pwd -P)"
readonly DERIVED_DATA_ROOT="$TEST_DIRECTORY/DerivedData"
readonly LEGACY_DERIVED_DATA_ROOT="$TEST_DIRECTORY/LegacyDerivedData"
readonly CURRENT_EXTENSION="$DERIVED_DATA_ROOT/Current/Build/Products/Debug/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly STALE_EXTENSION="$DERIVED_DATA_ROOT/Stale/Build/Products/Debug/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly SECOND_ROOT_EXTENSION="$LEGACY_DERIVED_DATA_ROOT/Old/Build/Products/Debug/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly HISTORIC_DEFAULT_EXTENSION="$LEGACY_DERIVED_DATA_ROOT/HistoricDefault/Build/Products/Debug/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly OLD_PERSONAL_EXTENSION="$DERIVED_DATA_ROOT/OldPersonal/Build/Products/Debug/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly EXTERNAL_EXTENSION="$TEST_DIRECTORY/Applications/DesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly EXTERNAL_LEGACY_EXTENSION="$TEST_DIRECTORY/Applications/LegacyDesktopWidgets.app/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly CURRENT_APP="${CURRENT_EXTENSION%/Contents/PlugIns/DesktopWidgetsExtension.appex}"
readonly COMMAND_LOG="$TEST_DIRECTORY/commands.log"
readonly REGISTRATION_DIRECTORY="$TEST_DIRECTORY/registrations"
readonly FAKE_COMMAND="$TEST_DIRECTORY/fake-runtime-command.sh"
readonly BUNDLE_IDENTIFIER="io.desktopwidgets.personal.abc123de45.app.widgets"
readonly HISTORIC_DEFAULT_BUNDLE_IDENTIFIER="com.joshuawyadao.DesktopWidgets.Widgets"
readonly OLD_PERSONAL_BUNDLE_IDENTIFIER="io.desktopwidgets.personal.abc123de45.widgets"

cleanup() {
    if [[ -n "$TEST_DIRECTORY" && "$TEST_DIRECTORY" == *"/desktop-widget-refresh-test."* ]]; then
        rm -rf -- "$TEST_DIRECTORY"
    fi
}
trap cleanup EXIT

mkdir -p \
    "$CURRENT_EXTENSION/Contents" \
    "$STALE_EXTENSION" \
    "$SECOND_ROOT_EXTENSION" \
    "$HISTORIC_DEFAULT_EXTENSION" \
    "$OLD_PERSONAL_EXTENSION" \
    "$EXTERNAL_EXTENSION" \
    "$EXTERNAL_LEGACY_EXTENSION" \
    "$REGISTRATION_DIRECTORY"

printf '%s\n' \
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
    '<plist version="1.0">' \
    '<dict>' \
    '  <key>CFBundleIdentifier</key>' \
    "  <string>$BUNDLE_IDENTIFIER</string>" \
    '</dict>' \
    '</plist>' > "$CURRENT_EXTENSION/Contents/Info.plist"

printf '%s\n' \
    "     $BUNDLE_IDENTIFIER(1.0.0)" \
    "                 Path = $CURRENT_EXTENSION" \
    "     $BUNDLE_IDENTIFIER(1.0.0)" \
    "                 Path = $STALE_EXTENSION" \
    "     $BUNDLE_IDENTIFIER(1.0.0)" \
    "                 Path = $SECOND_ROOT_EXTENSION" \
    "     $BUNDLE_IDENTIFIER(1.0.0)" \
    "                 Path = $EXTERNAL_EXTENSION" > "$REGISTRATION_DIRECTORY/$BUNDLE_IDENTIFIER.txt"

printf '%s\n' \
    "     $HISTORIC_DEFAULT_BUNDLE_IDENTIFIER(0.1.0)" \
    "                 Path = $HISTORIC_DEFAULT_EXTENSION" \
    "     $HISTORIC_DEFAULT_BUNDLE_IDENTIFIER(0.1.0)" \
    "                 Path = $EXTERNAL_LEGACY_EXTENSION" > "$REGISTRATION_DIRECTORY/$HISTORIC_DEFAULT_BUNDLE_IDENTIFIER.txt"

printf '%s\n' \
    "     $OLD_PERSONAL_BUNDLE_IDENTIFIER(0.1.0)" \
    "                 Path = $OLD_PERSONAL_EXTENSION" > "$REGISTRATION_DIRECTORY/$OLD_PERSONAL_BUNDLE_IDENTIFIER.txt"

printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'printf "%s" "${1:-}" >> "$WIDGET_REFRESH_TEST_COMMAND_LOG"' \
    'for argument in "${@:2}"; do printf "\t%s" "$argument" >> "$WIDGET_REFRESH_TEST_COMMAND_LOG"; done' \
    'printf "\n" >> "$WIDGET_REFRESH_TEST_COMMAND_LOG"' \
    'if [[ "${1:-}" == "-m" ]]; then' \
    '    requested_identifier=""' \
    '    for ((index = 1; index <= $#; index += 1)); do' \
    '        if [[ "${!index}" == "-i" ]]; then' \
    '            next_index=$((index + 1))' \
    '            requested_identifier="${!next_index}"' \
    '            break' \
    '        fi' \
    '    done' \
    '    registration_file="$WIDGET_REFRESH_TEST_REGISTRATION_DIRECTORY/$requested_identifier.txt"' \
    '    [[ ! -f "$registration_file" ]] || /bin/cat "$registration_file"' \
    'fi' > "$FAKE_COMMAND"
chmod +x "$FAKE_COMMAND"

WIDGET_REFRESH_PLUGINKIT_COMMAND="$FAKE_COMMAND" \
WIDGET_REFRESH_PKILL_COMMAND="$FAKE_COMMAND" \
WIDGET_REFRESH_DERIVED_DATA_ROOTS="$DERIVED_DATA_ROOT:$LEGACY_DERIVED_DATA_ROOT" \
WIDGET_REFRESH_TEST_COMMAND_LOG="$COMMAND_LOG" \
WIDGET_REFRESH_TEST_REGISTRATION_DIRECTORY="$REGISTRATION_DIRECTORY" \
    /bin/bash "$REFRESH_SCRIPT" "$CURRENT_APP"

require_command() {
    local expected="$1"
    local description="$2"
    if ! grep -Fqx -- "$expected" "$COMMAND_LOG"; then
        echo "FAIL: $description" >&2
        echo "Expected command: $expected" >&2
        echo "Recorded commands:" >&2
        /bin/cat "$COMMAND_LOG" >&2
        exit 1
    fi
}

reject_command() {
    local rejected="$1"
    local description="$2"
    if grep -Fqx -- "$rejected" "$COMMAND_LOG"; then
        echo "FAIL: $description" >&2
        echo "Rejected command: $rejected" >&2
        echo "Recorded commands:" >&2
        /bin/cat "$COMMAND_LOG" >&2
        exit 1
    fi
}

require_command $'-r\t'"$STALE_EXTENSION" "stale DerivedData extension was not unregistered"
require_command $'-r\t'"$SECOND_ROOT_EXTENSION" "stale extension under the second DerivedData root was not unregistered"
require_command $'-r\t'"$HISTORIC_DEFAULT_EXTENSION" "historic default-ID extension was not unregistered"
require_command $'-r\t'"$OLD_PERSONAL_EXTENSION" "old Personal Team ID extension was not unregistered"
require_command $'-a\t'"$CURRENT_EXTENSION" "current extension was not registered"
reject_command $'-r\t'"$CURRENT_EXTENSION" "current extension must never be unregistered"
reject_command $'-r\t'"$EXTERNAL_EXTENSION" "extension outside DerivedData must remain registered"
reject_command $'-r\t'"$EXTERNAL_LEGACY_EXTENSION" "legacy extension outside DerivedData must remain registered"

echo "PASS: Runtime refresh removes only stale DerivedData widget registrations."
