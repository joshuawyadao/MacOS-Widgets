#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd -P)"
readonly REQUESTED_OUTPUT_PATH="${1:-$PROJECT_ROOT/Desktop-Widgets-Personal-Installer.zip}"
/bin/mkdir -p "$(/usr/bin/dirname "$REQUESTED_OUTPUT_PATH")"
readonly OUTPUT_PATH="$(cd "$(/usr/bin/dirname "$REQUESTED_OUTPUT_PATH")" && pwd -P)/$(/usr/bin/basename "$REQUESTED_OUTPUT_PATH")"
readonly PACKAGE_ITEMS=(
    "Config"
    "DesktopWidgets.xcodeproj"
    "DesktopWidgetsApp"
    "DesktopWidgetsExtension"
    "DesktopWidgetsTests"
    "Shared"
    "Scripts"
    "docs"
    "Install Desktop Widgets.command"
    "Refresh Desktop Widgets.command"
    "Enable Automatic Refresh.command"
    "Disable Automatic Refresh.command"
    "Package Desktop Widgets for Another Mac.command"
    "Installation Guide.md"
    "README.md"
)
readonly RECIPIENT_EXCLUDED_ITEMS=(
    "docs/App-Icon-Concepts.md"
    "docs/Implementation-Plan.md"
    "docs/images/app-icon-concepts"
)

for item in "${PACKAGE_ITEMS[@]}"; do
    case "$OUTPUT_PATH" in
    "$PROJECT_ROOT/$item"|"$PROJECT_ROOT/$item"/*)
        echo "Refusing an output path inside packaged source: $OUTPUT_PATH" >&2
        exit 1
        ;;
    esac
done

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
for item in "${PACKAGE_ITEMS[@]}"; do
    copy_item "$item"
done
for item in "${RECIPIENT_EXCLUDED_ITEMS[@]}"; do
    excluded_path="$PAYLOAD_ROOT/$item"
    case "$excluded_path" in
    "$PAYLOAD_ROOT"/*)
        /bin/rm -rf -- "$excluded_path"
        ;;
    *)
        echo "Refusing unexpected recipient-exclusion path: $excluded_path" >&2
        exit 1
        ;;
    esac
done

while IFS= read -r local_artifact; do
    case "$local_artifact" in
    "$PAYLOAD_ROOT"/*)
        /bin/rm -rf -- "$local_artifact"
        ;;
    *)
        echo "Refusing unexpected local-artifact path: $local_artifact" >&2
        exit 1
        ;;
    esac
done < <(/usr/bin/find "$PAYLOAD_ROOT" \( \
    -name '.DS_Store' -o -name '.AppleDouble' -o -name '.LSOverride' -o \
    -name 'build' -o -name 'DerivedData' -o -name '.build' -o \
    -name '*.xcarchive' -o -name '*.ipa' -o -name '*.dSYM' -o -name '*.dSYM.zip' -o \
    -name 'xcuserdata' -o -name '*.xcuserstate' -o -name '*.xccheckout' -o -name '*.xcscmblueprint' -o \
    -name '.vscode' -o -name '.idea' -o -name '.brooks-lint-history.json' -o \
    -name '*.swp' -o -name '*.swo' -o -name '*.dmg' -o -name '*.pkg' -o \
    -name 'Desktop-Widgets-Personal-Installer*.zip' -o \
    -name '*.tmp' -o -name '*.temp' -o -name '*.log' -o -name '*~' \
\) -prune -print)

/usr/bin/printf '%s\n' \
    'DESKTOP WIDGETS — START HERE' \
    '' \
    'Already have Xcode installed and signed in? Double-click Install Desktop Widgets.command now.' \
    '' \
    'First time:' \
    '1. Install Xcode from the Mac App Store and open it once.' \
    '2. In Xcode > Settings > Accounts, add your Apple Account.' \
    '3. Double-click Install Desktop Widgets.command and press Return to enable easy automatic maintenance.' \
    '4. When Desktop Widgets opens, Control-click the desktop > Edit Widgets, search for Desktop Widgets, and add the widgets you want.' \
    '' \
    'Then open Appearance in the app, choose your Weather city when editing that widget, and enable Calendar only if you want private event timing.' \
    'If anything stops, open Installation Guide.md for the matching fix.' \
    'The installer never asks for or stores your Apple password.' \
    > "$PAYLOAD_ROOT/START HERE.txt"

if /usr/bin/find "$PAYLOAD_ROOT" \( \
    -name '.git' -o \
    -name 'xcuserdata' -o \
    -name '.env' -o \
    \( -name '.env.*' ! -name '.env.example' ! -name '.env.template' \) -o \
    -name 'Secrets.xcconfig' -o \
    -name 'Local.xcconfig' -o \
    -name '*.private.xcconfig' -o \
    -name 'AuthKey_*.p8' -o \
    -name '*.p12' -o \
    -name '*.mobileprovision' -o \
    -name '*.provisionprofile' -o \
    -name '*.app' -o \
    -name '*.log' \
\) -print -quit | /usr/bin/grep -q .; then
    echo "Refusing to package a local secret, credential, build product, log, or Git metadata." >&2
    exit 1
fi

/bin/mkdir -p "$(/usr/bin/dirname "$OUTPUT_PATH")"
/bin/rm -f -- "$OUTPUT_PATH"
/usr/bin/ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$PAYLOAD_ROOT" "$OUTPUT_PATH"

echo "Created a clean handoff package:"
echo "$OUTPUT_PATH"
if [[ "${DESKTOP_WIDGETS_PACKAGE_NO_REVEAL:-0}" != "1" ]]; then
    /usr/bin/open -R "$OUTPUT_PATH"
fi
