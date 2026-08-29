#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_SCRIPT="$SCRIPT_DIRECTORY/package-personal-installer.sh"
readonly TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-package-test.XXXXXX")"
readonly OUTPUT_PATH="$TEST_ROOT/Desktop-Widgets-Personal-Installer.zip"
readonly CONTENTS_PATH="$TEST_ROOT/contents.txt"
readonly TEST_XCUSERDATA_ROOT="$SCRIPT_DIRECTORY/../DesktopWidgets.xcodeproj/xcuserdata"
readonly TEST_XCUSERDATA="$TEST_XCUSERDATA_ROOT/codex-package-test.xcuserdatad"
readonly SECRET_TEST_ROOT="$SCRIPT_DIRECTORY/../Config"
readonly SECRET_FIXTURES=(
    "$SECRET_TEST_ROOT/Secrets.xcconfig"
    "$SECRET_TEST_ROOT/codex.private.xcconfig"
    "$SECRET_TEST_ROOT/.env"
    "$SECRET_TEST_ROOT/.env.local"
    "$SECRET_TEST_ROOT/AuthKey_codex.p8"
)

cleanup() {
    /bin/rm -rf -- "$TEST_XCUSERDATA"
    /bin/rmdir "$TEST_XCUSERDATA_ROOT" 2>/dev/null || true
    /bin/rm -f -- "${SECRET_FIXTURES[@]}"
    if [[ -n "$TEST_ROOT" && "$TEST_ROOT" == *"/desktop-widgets-package-test."* ]]; then
        /bin/rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

/bin/mkdir -p "$TEST_XCUSERDATA"
/usr/bin/printf '%s\n' 'private Xcode workspace state' > "$TEST_XCUSERDATA/UserInterfaceState.xcuserstate"
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
    "Desktop Widgets/DesktopWidgets.xcodeproj/project.pbxproj" \
    "Desktop Widgets/DesktopWidgetsTests/WidgetContractTests.swift"; do
    /usr/bin/grep -Fq "$required" "$CONTENTS_PATH" || {
        echo "FAIL: package is missing $required" >&2
        exit 1
    }
done

if /usr/bin/grep -Eq '(^|/)(\.git|xcuserdata|Local\.xcconfig|DerivedData|build)(/|$)|\.(app|p12|mobileprovision|provisionprofile|log)(/|$)' "$CONTENTS_PATH"; then
    echo "FAIL: package contains local metadata, credentials, logs, or build products" >&2
    /bin/cat "$CONTENTS_PATH" >&2
    exit 1
fi

for secret_fixture in "${SECRET_FIXTURES[@]}"; do
    /usr/bin/printf '%s\n' 'test-only secret material' > "$secret_fixture"
    rejected_output="$(DESKTOP_WIDGETS_PACKAGE_NO_REVEAL=1 /bin/bash "$PACKAGE_SCRIPT" "$OUTPUT_PATH" 2>&1 || true)"
    [[ "$rejected_output" == *"Refusing to package a local secret"* ]] || {
        echo "FAIL: package accepted ignored secret pattern $(/usr/bin/basename "$secret_fixture")" >&2
        exit 1
    }
    /bin/rm -f -- "$secret_fixture"
done

echo "PASS: Handoff package contains the guided source installer and excludes local/private artifacts."
