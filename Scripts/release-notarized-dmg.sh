#!/bin/bash
# Archive, notarize and package a Developer ID build. Credentials stay in Keychain.
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RELEASE_XCODEBUILD="${RELEASE_XCODEBUILD:-/usr/bin/xcodebuild}"
RELEASE_CODESIGN="${RELEASE_CODESIGN:-/usr/bin/codesign}"
RELEASE_XCRUN="${RELEASE_XCRUN:-/usr/bin/xcrun}"
RELEASE_HDIUTIL="${RELEASE_HDIUTIL:-/usr/bin/hdiutil}"
RELEASE_SPCTL="${RELEASE_SPCTL:-/usr/sbin/spctl}"
RELEASE_SECURITY="${RELEASE_SECURITY:-/usr/bin/security}"
RELEASE_LIPO="${RELEASE_LIPO:-/usr/bin/lipo}"
# shellcheck source=Scripts/release-validation-lib.sh
source "$ROOT/Scripts/release-validation-lib.sh"
TEAM="" IDENTITY="" PROFILE="" OUTPUT="" EXISTING="" MANIFEST="" MODE="" MODE_COUNT=0
usage() {
    echo "Usage: $0 --team TEAMID --identity 'Developer ID Application: ...' --notary-profile KEYCHAIN_PROFILE --output /path/Desktop-Widgets.dmg (--new-install | --existing-app /path/DesktopWidgets.app | --identities-file /path/previous.identities.plist)" >&2
    exit 2
}
while (($#)); do
    case "$1" in
        --team) TEAM="${2:-}"; shift 2 ;;
        --identity) IDENTITY="${2:-}"; shift 2 ;;
        --notary-profile) PROFILE="${2:-}"; shift 2 ;;
        --output) OUTPUT="${2:-}"; shift 2 ;;
        --existing-app) EXISTING="${2:-}"; MODE=existing; MODE_COUNT=$((MODE_COUNT + 1)); shift 2 ;;
        --identities-file) MANIFEST="${2:-}"; MODE=manifest; MODE_COUNT=$((MODE_COUNT + 1)); shift 2 ;;
        --new-install) MODE=new; MODE_COUNT=$((MODE_COUNT + 1)); shift ;;
        *) usage ;;
    esac
done
[[ "$TEAM" =~ ^[A-Z0-9]{10}$ && "$IDENTITY" == 'Developer ID Application: '* && -n "$PROFILE" && -n "$OUTPUT" && "$MODE_COUNT" == 1 ]] || usage
[[ "$OUTPUT" == /* && "$OUTPUT" == *.dmg && "$OUTPUT" != "$ROOT"/* ]] || { echo 'Output must be an absolute .dmg path' >&2; exit 2; }
[[ ! -e "$OUTPUT" && ! -e "${OUTPUT%.dmg}.identities.plist" ]] || { echo 'Output already exists; choose a new path' >&2; exit 2; }
[[ "$MODE" != existing || -d "$EXISTING" ]] || { echo 'Existing app is missing' >&2; exit 2; }

plist_value() { /usr/libexec/PlistBuddy -c "Print :$2" "$1"; }
signed_team() { "$RELEASE_CODESIGN" -dv --verbose=4 "$1" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -n 1; }
check_existing() {
    local old="$1" widget="$1/Contents/PlugIns/DesktopWidgetsExtension.appex"
    [[ -d "$widget" ]] || { echo 'Existing widget extension is missing' >&2; exit 1; }
    "$RELEASE_CODESIGN" --verify --strict --deep "$old"
    "$RELEASE_CODESIGN" --verify --strict "$widget"
    [[ "$(signed_team "$old")" == "$TEAM" && "$(signed_team "$widget")" == "$TEAM" ]] || { echo 'Existing app belongs to a different signing team; automatic migration is unsafe' >&2; exit 1; }
    APP_ID="$(plist_value "$old/Contents/Info.plist" CFBundleIdentifier)"
    EXT_ID="$(plist_value "$widget/Contents/Info.plist" CFBundleIdentifier)"
    GROUP="$(plist_value "$old/Contents/Info.plist" WidgetThemeAppGroupIdentifier)"
    [[ "$EXT_ID" == "$APP_ID".* && "$GROUP" == "$TEAM".* && "$GROUP" == "$(plist_value "$widget/Contents/Info.plist" WidgetThemeAppGroupIdentifier)" ]] || { echo 'Existing app and widget identities disagree' >&2; exit 1; }
    local app_entitlements widget_entitlements
    app_entitlements="$(mktemp "${TMPDIR:-/tmp}/desktop-widgets-app-entitlements.XXXXXX")"
    widget_entitlements="$(mktemp "${TMPDIR:-/tmp}/desktop-widgets-widget-entitlements.XXXXXX")"
    "$RELEASE_CODESIGN" -d --entitlements :- "$old" > "$app_entitlements" 2>/dev/null
    "$RELEASE_CODESIGN" -d --entitlements :- "$widget" > "$widget_entitlements" 2>/dev/null
    if [[ "$(plist_value "$app_entitlements" 'com.apple.security.application-groups:0')" != "$GROUP" || "$(plist_value "$widget_entitlements" 'com.apple.security.application-groups:0')" != "$GROUP" ]]; then
        /bin/rm -f -- "$app_entitlements" "$widget_entitlements"
        echo 'Existing signed App Group does not match metadata' >&2
        exit 1
    fi
    /bin/rm -f -- "$app_entitlements" "$widget_entitlements"
}
if [[ "$MODE" == existing ]]; then
    check_existing "$EXISTING"
elif [[ "$MODE" == manifest ]]; then
    [[ -f "$MANIFEST" ]] || { echo 'Previous release identity manifest is missing' >&2; exit 2; }
    [[ "$(plist_value "$MANIFEST" TeamID)" == "$TEAM" ]] || { echo 'Previous release belongs to a different signing team' >&2; exit 1; }
    APP_ID="$(plist_value "$MANIFEST" AppBundleID)"
    EXT_ID="$(plist_value "$MANIFEST" WidgetBundleID)"
    GROUP="$(plist_value "$MANIFEST" AppGroupID)"
else
    APP_ID=com.joshuawyadao.DesktopWidgets
    EXT_ID=com.joshuawyadao.DesktopWidgets.Widgets
    GROUP="$TEAM.com.joshuawyadao.desktop-widgets"
fi
[[ "$APP_ID" =~ ^[A-Za-z0-9.-]+$ && "$EXT_ID" == "$APP_ID".* && "$GROUP" == "$TEAM".* && "$EXT_ID" =~ ^[A-Za-z0-9.-]+$ && "$GROUP" =~ ^[A-Za-z0-9.-]+$ ]] || { echo 'Invalid identifiers' >&2; exit 1; }

IDENTITY_RECORD="$("$RELEASE_SECURITY" find-identity -v -p codesigning | /usr/bin/grep -F "\"$IDENTITY\"" | /usr/bin/head -n 1)" || true
CERT_SHA="$(/usr/bin/printf '%s\n' "$IDENTITY_RECORD" | /usr/bin/sed -nE 's/^[[:space:]]*[0-9]+\) ([A-Fa-f0-9]{40}) \".*\"$/\1/p')"
if [[ ! "$CERT_SHA" =~ ^[A-Fa-f0-9]{40}$ ]]; then
    echo "Developer ID Application certificate and private key are unavailable in Keychain" >&2
    exit 1
fi

TMP="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-release.XXXXXX")"
DIAGNOSTICS="${OUTPUT%.dmg}.release-diagnostics.log"
/bin/mkdir -p "$(/usr/bin/dirname "$OUTPUT")"
run_logged() {
    local label="$1"; shift
    if ! "$@" > "$TMP/$label.log" 2>&1; then
        /usr/bin/ditto "$TMP/$label.log" "$DIAGNOSTICS"
        echo "$label failed; inspect $DIAGNOSTICS" >&2
        exit 1
    fi
}
# Hold a lock through publication so two releases cannot publish to the same
# output after both passed the initial no-overwrite check.
OUTPUT_LOCK="$OUTPUT.release-lock"
if ! /bin/mkdir "$OUTPUT_LOCK"; then
    /bin/rm -rf -- "$TMP"
    echo "Another release is publishing to this output; choose a new output path" >&2
    exit 1
fi
PUBLISHED=0
PUBLISH_STARTED=0
STAGED_DMG="$OUTPUT.new.${TMP##*/}"
STAGED_MANIFEST="${OUTPUT%.dmg}.identities.plist.new.${TMP##*/}"
cleanup() {
    /bin/rm -f -- "$STAGED_DMG" "$STAGED_MANIFEST"
    if [[ "$PUBLISH_STARTED" == 1 && "$PUBLISHED" != 1 ]]; then
        /bin/rm -f -- "${OUTPUT%.dmg}.identities.plist"
    fi
    /bin/rmdir "$OUTPUT_LOCK"
    /bin/rm -rf -- "$TMP"
}
trap cleanup EXIT
[[ ! -e "$OUTPUT" && ! -e "${OUTPUT%.dmg}.identities.plist" ]] || {
    echo "Output was created by another release; choose a new path" >&2
    exit 1
}
ARCHIVE="$TMP/DesktopWidgets.xcarchive"
# Xcode gives -xcconfig higher precedence than build-setting arguments. Append
# the reviewed identity after all development includes so Local.xcconfig cannot
# override the distribution Team, identifiers, certificate, or helper paths.
RESOLVED_CONFIG="$TMP/DeveloperID.resolved.xcconfig"
{
    /usr/bin/printf '#include "%s/Config/DeveloperID.xcconfig"\n' "$ROOT"
    /usr/bin/printf 'DEVELOPMENT_TEAM = %s\n' "$TEAM"
    /usr/bin/printf 'CODE_SIGN_STYLE = Manual\nCODE_SIGN_IDENTITY = %s\n' "$CERT_SHA"
    /usr/bin/printf 'DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER = %s\n' "$APP_ID"
    /usr/bin/printf 'DESKTOP_WIDGETS_EXTENSION_BUNDLE_IDENTIFIER = %s\n' "$EXT_ID"
    /usr/bin/printf 'WIDGET_THEME_APP_GROUP = %s\n' "$GROUP"
    /usr/bin/printf 'DESKTOP_WIDGETS_DISTRIBUTION_CHANNEL = developer-id\n'
    /usr/bin/printf 'DESKTOP_WIDGETS_REFRESH_COMMAND_PATH =\nDESKTOP_WIDGETS_ENABLE_AUTOMATIC_REFRESH_COMMAND_PATH =\nDESKTOP_WIDGETS_DISABLE_AUTOMATIC_REFRESH_COMMAND_PATH =\n'
} > "$RESOLVED_CONFIG"
run_logged archive "$RELEASE_XCODEBUILD" archive -project "$ROOT/DesktopWidgets.xcodeproj" -scheme DesktopWidgets -configuration Release -destination 'generic/platform=macOS' -archivePath "$ARCHIVE" -derivedDataPath "$TMP/DerivedData" -xcconfig "$RESOLVED_CONFIG"

/usr/bin/plutil -create xml1 "$TMP/ExportOptions.plist"
/usr/bin/plutil -insert method -string developer-id "$TMP/ExportOptions.plist"
/usr/bin/plutil -insert signingStyle -string manual "$TMP/ExportOptions.plist"
/usr/bin/plutil -insert signingCertificate -string "$CERT_SHA" "$TMP/ExportOptions.plist"
/usr/bin/plutil -insert teamID -string "$TEAM" "$TMP/ExportOptions.plist"
run_logged export "$RELEASE_XCODEBUILD" -exportArchive -archivePath "$ARCHIVE" -exportPath "$TMP/export" -exportOptionsPlist "$TMP/ExportOptions.plist"
APP="$TMP/export/DesktopWidgets.app"
WIDGET="$APP/Contents/PlugIns/DesktopWidgetsExtension.appex"
[[ -d "$WIDGET" ]] || { echo 'Export lacks widget extension' >&2; exit 1; }
verify_product() {
    local product="$1" bundle_id="$2" entitlements="$3"
    "$RELEASE_CODESIGN" --verify --strict "$product"
    [[ "$(signed_team "$product")" == "$TEAM" && "$(plist_value "$product/Contents/Info.plist" CFBundleIdentifier)" == "$bundle_id" ]] || { echo 'Exported identity mismatch' >&2; exit 1; }
    "$RELEASE_CODESIGN" -dv --verbose=4 "$product" 2> "$TMP/signature.txt"
    /usr/bin/grep -Eq '^Authority=Developer ID Application:' "$TMP/signature.txt"
    /usr/bin/grep -Eq '^Timestamp=' "$TMP/signature.txt"
    /usr/bin/grep -Eq '^Runtime Version=|flags=.*runtime' "$TMP/signature.txt"
    "$RELEASE_CODESIGN" -d --entitlements :- "$product" > "$entitlements" 2>/dev/null
    [[ "$(plist_value "$entitlements" com.apple.security.app-sandbox)" == true && "$(plist_value "$entitlements" 'com.apple.security.application-groups:0')" == "$GROUP" && "$(plist_value "$entitlements" com.apple.security.personal-information.calendars)" == true ]] || { echo 'Exported entitlements mismatch' >&2; exit 1; }
    ! /usr/libexec/PlistBuddy -c 'Print :com.apple.security.get-task-allow' "$entitlements" 2>/dev/null | /usr/bin/grep -q true
    [[ "$(plist_value "$product/Contents/Info.plist" WidgetThemeAppGroupIdentifier)" == "$GROUP" ]]
}
verify_product "$APP" "$APP_ID" "$TMP/app-entitlements.plist"
verify_product "$WIDGET" "$EXT_ID" "$TMP/widget-entitlements.plist"
[[ "$(plist_value "$TMP/widget-entitlements.plist" com.apple.security.network.client)" == true ]]
[[ "$(plist_value "$APP/Contents/Info.plist" DesktopWidgetsDistributionChannel)" == developer-id ]]
[[ "$(plist_value "$APP/Contents/Info.plist" CFBundleShortVersionString)" == "$(plist_value "$WIDGET/Contents/Info.plist" CFBundleShortVersionString)" ]]
[[ "$(plist_value "$APP/Contents/Info.plist" CFBundleVersion)" == "$(plist_value "$WIDGET/Contents/Info.plist" CFBundleVersion)" ]]
for binary in "$APP/Contents/MacOS/DesktopWidgets" "$WIDGET/Contents/MacOS/DesktopWidgetsExtension"; do
    architectures="$("$RELEASE_LIPO" -archs "$binary")"
    [[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]] || { echo "Universal architectures missing: $binary" >&2; exit 1; }
done
for key in DesktopWidgetsRefreshCommandPath DesktopWidgetsEnableAutomaticRefreshCommandPath DesktopWidgetsDisableAutomaticRefreshCommandPath; do
    [[ -z "$(plist_value "$APP/Contents/Info.plist" "$key")" ]]
done
"$RELEASE_CODESIGN" --verify --strict --deep "$APP"

/usr/bin/ditto -c -k --keepParent "$APP" "$TMP/app.zip"
run_logged app-notary "$RELEASE_XCRUN" notarytool submit "$TMP/app.zip" --keychain-profile "$PROFILE" --wait --output-format json
desktop_widgets_require_accepted_notarization "$TMP/app-notary.log" App || { /usr/bin/ditto "$TMP/app-notary.log" "$DIAGNOSTICS"; exit 1; }
"$RELEASE_XCRUN" stapler staple "$APP"
"$RELEASE_XCRUN" stapler validate "$APP"
"$RELEASE_SPCTL" --assess --type execute --verbose "$APP"

/bin/mkdir "$TMP/disk"
/usr/bin/ditto "$APP" "$TMP/disk/Desktop Widgets.app"
/bin/ln -s /Applications "$TMP/disk/Applications"
cat > "$TMP/disk/READ ME.txt" <<'INSTRUCTIONS'
DESKTOP WIDGETS — macOS 14 or later

First installation:
Drag Desktop Widgets.app to Applications, open the installed copy once, then eject this disk image. Control-click the desktop, choose Edit Widgets, and add your widgets. Choose a theme in Appearance and a city in the Weather widget editor. Calendar access is optional. No Xcode or developer sign-in is needed.

Manual updates:
Quit Desktop Widgets. Replace the existing app in the SAME Applications folder and open the updated copy. If your old copy is in your home folder's Applications, replace it there instead of using this image's shortcut to /Applications. Keep your widgets and preferences. Settings normally remain when the signing team, app, extension and App Group identities match. Do not delete app data or create a second installed copy.

Switching from the old Xcode/source installer:
Before installing, run Disable Automatic Refresh.command from the old installer. Its saved copy is in ~/Library/Application Support/Desktop Widgets/Installer (Finder > Go > Go to Folder can open that folder). Let any current refresh finish, then quit the app. Ask the sender to confirm that this release preserves your installed identifiers. Different signing accounts can require adding widgets again, reapplying appearance choices, and granting Calendar access. Retain a backup of the old app and its data; stop using its Install/Refresh/Enable commands.

This release has no automatic updater and needs no weekly rebuilding. For a newer version, use the signed download supplied by the release provider.
INSTRUCTIONS
"$RELEASE_HDIUTIL" create -volname 'Desktop Widgets' -srcfolder "$TMP/disk" -format UDZO -ov "$TMP/Desktop-Widgets.dmg"
"$RELEASE_CODESIGN" --force --timestamp --sign "$CERT_SHA" "$TMP/Desktop-Widgets.dmg"
"$RELEASE_CODESIGN" --verify --strict "$TMP/Desktop-Widgets.dmg"
run_logged dmg-notary "$RELEASE_XCRUN" notarytool submit "$TMP/Desktop-Widgets.dmg" --keychain-profile "$PROFILE" --wait --output-format json
desktop_widgets_require_accepted_notarization "$TMP/dmg-notary.log" DMG || { /usr/bin/ditto "$TMP/dmg-notary.log" "$DIAGNOSTICS"; exit 1; }
"$RELEASE_XCRUN" stapler staple "$TMP/Desktop-Widgets.dmg"
"$RELEASE_XCRUN" stapler validate "$TMP/Desktop-Widgets.dmg"
"$RELEASE_SPCTL" --assess --type open --context context:primary-signature --verbose "$TMP/Desktop-Widgets.dmg"

/usr/bin/plutil -create xml1 "$TMP/identities.plist"
/usr/bin/plutil -insert TeamID -string "$TEAM" "$TMP/identities.plist"
/usr/bin/plutil -insert AppBundleID -string "$APP_ID" "$TMP/identities.plist"
/usr/bin/plutil -insert WidgetBundleID -string "$EXT_ID" "$TMP/identities.plist"
/usr/bin/plutil -insert AppGroupID -string "$GROUP" "$TMP/identities.plist"
/usr/bin/plutil -insert MarketingVersion -string "$(plist_value "$APP/Contents/Info.plist" CFBundleShortVersionString)" "$TMP/identities.plist"
/usr/bin/plutil -insert BuildVersion -string "$(plist_value "$APP/Contents/Info.plist" CFBundleVersion)" "$TMP/identities.plist"
/bin/mkdir -p "$(/usr/bin/dirname "$OUTPUT")"
/usr/bin/ditto "$TMP/identities.plist" "$STAGED_MANIFEST"
/usr/bin/ditto "$TMP/Desktop-Widgets.dmg" "$STAGED_DMG"
PUBLISH_STARTED=1
/bin/mv "$STAGED_MANIFEST" "${OUTPUT%.dmg}.identities.plist"
/bin/mv "$STAGED_DMG" "$OUTPUT"
PUBLISHED=1
echo "Notarized disk image: $OUTPUT"
