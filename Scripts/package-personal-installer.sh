#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly OUTPUT_PATH="${1:-$PROJECT_ROOT/Desktop-Widgets-Personal-Installer.zip}"
readonly TEMPORARY_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-package.XXXXXX")"
readonly PAYLOAD_ROOT="$TEMPORARY_ROOT/Desktop Widgets"

cleanup() {
    if [[ -n "$TEMPORARY_ROOT" && "$TEMPORARY_ROOT" == *"/desktop-widgets-package."* ]]; then
        /bin/rm -rf -- "$TEMPORARY_ROOT"
    fi
}
trap cleanup EXIT

copy_item() {
    local item="$1"
    local source="$PROJECT_ROOT/$item"
    local destination="$PAYLOAD_ROOT/$item"
    [[ -e "$source" ]] || {
        echo "Missing package input: $item" >&2
        exit 1
    }
    /bin/mkdir -p "$(/usr/bin/dirname "$destination")"
    /usr/bin/ditto "$source" "$destination"
}

/bin/mkdir -p "$PAYLOAD_ROOT"
for item in \
    "Config" \
    "DesktopWidgets.xcodeproj" \
    "DesktopWidgetsApp" \
    "DesktopWidgetsExtension" \
    "Shared" \
    "Scripts" \
    "docs" \
    "Install Desktop Widgets.command" \
    "Refresh Desktop Widgets.command" \
    "Enable Automatic Refresh.command" \
    "Disable Automatic Refresh.command" \
    "Installation Guide.md" \
    "README.md"; do
    copy_item "$item"
done

while IFS= read -r xcode_user_data; do
    case "$xcode_user_data" in
    "$PAYLOAD_ROOT"/*/xcuserdata)
        /bin/rm -rf -- "$xcode_user_data"
        ;;
    *)
        echo "Refusing unexpected Xcode user-data path: $xcode_user_data" >&2
        exit 1
        ;;
    esac
done < <(/usr/bin/find "$PAYLOAD_ROOT" -type d -name xcuserdata -print)

/usr/bin/printf '%s\n' \
    'Desktop Widgets personal installation handoff' \
    '' \
    'Start with Installation Guide.md.' \
    'The installer includes optional low-resource automatic maintenance plus manual enable, disable, and refresh commands.' \
    'No Apple Account, Team ID, certificate, provisioning profile, build product, diagnostic log, or Git history is included.' \
    > "$PAYLOAD_ROOT/Package Contents.txt"

if /usr/bin/find "$PAYLOAD_ROOT" \( \
    -name '.git' -o \
    -name 'xcuserdata' -o \
    -name 'Local.xcconfig' -o \
    -name '*.p12' -o \
    -name '*.mobileprovision' -o \
    -name '*.provisionprofile' -o \
    -name '*.app' -o \
    -name '*.log' \
\) -print -quit | /usr/bin/grep -q .; then
    echo "Refusing to package a credential, build product, log, or Git metadata." >&2
    exit 1
fi

/bin/mkdir -p "$(/usr/bin/dirname "$OUTPUT_PATH")"
/bin/rm -f -- "$OUTPUT_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$PAYLOAD_ROOT" "$OUTPUT_PATH"

echo "Created a clean handoff package:"
echo "$OUTPUT_PATH"
if [[ "${DESKTOP_WIDGETS_PACKAGE_NO_REVEAL:-0}" != "1" ]]; then
    /usr/bin/open -R "$OUTPUT_PATH"
fi
