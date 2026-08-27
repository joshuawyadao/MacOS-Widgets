#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_SCRIPT="$SCRIPT_DIRECTORY/package-personal-installer.sh"
readonly TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-package-test.XXXXXX")"
readonly OUTPUT_PATH="$TEST_ROOT/Desktop-Widgets-Personal-Installer.zip"
readonly CONTENTS_PATH="$TEST_ROOT/contents.txt"

cleanup() {
    if [[ -n "$TEST_ROOT" && "$TEST_ROOT" == *"/desktop-widgets-package-test."* ]]; then
        /bin/rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

DESKTOP_WIDGETS_PACKAGE_NO_REVEAL=1 /bin/bash "$PACKAGE_SCRIPT" "$OUTPUT_PATH" >/dev/null
[[ -s "$OUTPUT_PATH" ]] || {
    echo "FAIL: handoff archive was not created" >&2
    exit 1
}

/usr/bin/unzip -l "$OUTPUT_PATH" > "$CONTENTS_PATH"
for required in \
    "Desktop Widgets/Install Desktop Widgets.command" \
    "Desktop Widgets/Refresh Desktop Widgets.command" \
    "Desktop Widgets/Enable Automatic Refresh.command" \
    "Desktop Widgets/Disable Automatic Refresh.command" \
    "Desktop Widgets/Installation Guide.md" \
    "Desktop Widgets/DesktopWidgets.xcodeproj/project.pbxproj"; do
    /usr/bin/grep -Fq "$required" "$CONTENTS_PATH" || {
        echo "FAIL: package is missing $required" >&2
        exit 1
    }
done

if /usr/bin/grep -Eq '(^|/)(\.git|Local\.xcconfig|DerivedData|build)(/|$)|\.(app|p12|mobileprovision|provisionprofile|log)(/|$)' "$CONTENTS_PATH"; then
    echo "FAIL: package contains local metadata, credentials, logs, or build products" >&2
    /bin/cat "$CONTENTS_PATH" >&2
    exit 1
fi

echo "PASS: Handoff package contains the guided source installer and excludes local/private artifacts."
