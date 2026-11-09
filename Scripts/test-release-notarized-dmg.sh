#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/Scripts/release-notarized-dmg.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/desktop-widgets-release-test.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
bash -n "$SCRIPT"
source "$ROOT/Scripts/release-validation-lib.sh"
printf '{"status":"Accepted"}\n' > "$TMP/accepted.json"
printf '{"status":"Invalid"}\n' > "$TMP/rejected.json"
desktop_widgets_require_accepted_notarization "$TMP/accepted.json" App
if desktop_widgets_require_accepted_notarization "$TMP/rejected.json" App > "$TMP/out" 2>&1; then exit 1; fi

# All Apple commands are replaced by local fixtures. Real plutil and ditto
# still exercise the archive packaging and metadata paths.
cat > "$TMP/mock-tool" <<'MOCK'
#!/bin/bash
set -euo pipefail
kind="${0##*/}"
printf '%s %s\n' "$kind" "$*" >> "$MOCK_LOG"
case "$kind" in
mock-security)
    [[ "${MOCK_FAIL:-}" != missing-certificate ]] || exit 0
    echo '1) 0123456789ABCDEF0123456789ABCDEF01234567 "Developer ID Application: Example"';;
mock-xcodebuild)
    if [[ "${1:-}" == archive ]]; then
        args=("$@")
        for ((i=0; i<${#args[@]}; i++)); do
            if [[ "${args[i]}" == -xcconfig ]]; then
                cp "${args[i+1]}" "$MOCK_LOG.resolved.xcconfig"
                break
            fi
        done
        [[ -s "$MOCK_LOG.resolved.xcconfig" ]]
        [[ "${MOCK_FAIL:-}" != archive ]]
    else
        [[ "${MOCK_FAIL:-}" != export ]] || exit 1
        while (($#)); do
            if [[ "$1" == -exportPath ]]; then export_path="$2"; break; fi
            shift
        done
        app="$export_path/DesktopWidgets.app"
        widget="$app/Contents/PlugIns/DesktopWidgetsExtension.appex"
        mkdir -p "$widget/Contents/MacOS" "$app/Contents/MacOS"
        cp "$MOCK_FIXTURE/app.plist" "$app/Contents/Info.plist"
        cp "$MOCK_FIXTURE/widget.plist" "$widget/Contents/Info.plist"
        touch "$app/Contents/MacOS/DesktopWidgets" "$widget/Contents/MacOS/DesktopWidgetsExtension"
    fi;;
mock-codesign)
    if [[ "$1" == --verify && "${MOCK_FAIL:-}" == signature ]]; then exit 1; fi
    if [[ "$1" == -dv ]]; then
        echo "TeamIdentifier=${MOCK_SIGN_TEAM:-ABC123DE45}" >&2
        echo 'Authority=Developer ID Application: Example' >&2
        echo 'Timestamp=Nov 9, 2026' >&2
        echo 'flags=0x10000(runtime)' >&2
    elif [[ "$1" == -d ]]; then
        last="${!#}"
        if [[ "$last" == *.appex ]]; then
            cat "$MOCK_FIXTURE/widget-entitlements.plist"
        else
            cat "$MOCK_FIXTURE/app-entitlements.plist"
        fi
    fi;;
mock-lipo) echo 'x86_64 arm64';;
mock-xcrun)
    if [[ "$1" == notarytool ]]; then
        if [[ "$2" == submit && "$3" == *.zip && "${MOCK_FAIL:-}" == app-notary ]]; then echo '{"status":"Invalid"}'; exit 0; fi
        if [[ "$2" == submit && "$3" == *.dmg && "${MOCK_FAIL:-}" == dmg-notary ]]; then echo '{"status":"Invalid"}'; exit 0; fi
        echo '{"status":"Accepted"}'
    fi;;
mock-hdiutil)
    printf 'mock disk image\n' > "${!#}";;
mock-spctl) :;;
esac
MOCK
chmod +x "$TMP/mock-tool"
for kind in xcodebuild codesign xcrun hdiutil spctl security lipo; do
    ln -s "$TMP/mock-tool" "$TMP/mock-$kind"
done
mkdir "$TMP/fixtures"
for kind in app widget; do
    plutil -create xml1 "$TMP/fixtures/$kind.plist"
    if [[ "$kind" == app ]]; then bundle=com.joshuawyadao.DesktopWidgets; else bundle=com.joshuawyadao.DesktopWidgets.Widgets; fi
    plutil -insert CFBundleIdentifier -string "$bundle" "$TMP/fixtures/$kind.plist"
    plutil -insert WidgetThemeAppGroupIdentifier -string ABC123DE45.com.joshuawyadao.desktop-widgets "$TMP/fixtures/$kind.plist"
    plutil -insert CFBundleShortVersionString -string 1.0.0 "$TMP/fixtures/$kind.plist"
    plutil -insert CFBundleVersion -string 21 "$TMP/fixtures/$kind.plist"
    plutil -create xml1 "$TMP/fixtures/$kind-entitlements.plist"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.app-sandbox bool true" "$TMP/fixtures/$kind-entitlements.plist"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.personal-information.calendars bool true" "$TMP/fixtures/$kind-entitlements.plist"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups array" "$TMP/fixtures/$kind-entitlements.plist"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string ABC123DE45.com.joshuawyadao.desktop-widgets" "$TMP/fixtures/$kind-entitlements.plist"
done
plutil -insert DesktopWidgetsDistributionChannel -string developer-id "$TMP/fixtures/app.plist"
for key in DesktopWidgetsRefreshCommandPath DesktopWidgetsEnableAutomaticRefreshCommandPath DesktopWidgetsDisableAutomaticRefreshCommandPath; do
    plutil -insert "$key" -string '' "$TMP/fixtures/app.plist"
done
/usr/libexec/PlistBuddy -c "Add :com.apple.security.network.client bool true" "$TMP/fixtures/widget-entitlements.plist"
export MOCK_FIXTURE="$TMP/fixtures"
export RELEASE_XCODEBUILD="$TMP/mock-xcodebuild" RELEASE_CODESIGN="$TMP/mock-codesign" RELEASE_XCRUN="$TMP/mock-xcrun"
export RELEASE_HDIUTIL="$TMP/mock-hdiutil" RELEASE_SPCTL="$TMP/mock-spctl" RELEASE_SECURITY="$TMP/mock-security" RELEASE_LIPO="$TMP/mock-lipo"
run_case() {
    local case_name="$1" result="$2"
    export MOCK_LOG="$TMP/$case_name.log" MOCK_FAIL="$case_name"
    local output="$TMP/$case_name.dmg"
    if "$SCRIPT" --team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$output" --new-install > "$TMP/$case_name.out" 2>&1; then
        [[ "$result" == success ]] || { echo "FAIL: $case_name accepted" >&2; exit 1; }
        [[ -s "$output" && -s "${output%.dmg}.identities.plist" ]]
        /usr/bin/grep -Eq 'mock-xcrun stapler staple .*DesktopWidgets.app' "$MOCK_LOG"
        /usr/bin/grep -Eq 'mock-codesign --force --timestamp --sign .*\.dmg' "$MOCK_LOG"
        /usr/bin/grep -Eq 'mock-xcrun stapler staple .*\.dmg' "$MOCK_LOG"
    else
        [[ "$result" == failure ]] || { cat "$TMP/$case_name.out" >&2; exit 1; }
        [[ ! -e "$output" && ! -e "${output%.dmg}.identities.plist" ]]
    fi
    [[ ! -e "$output.release-lock" ]] || { echo "FAIL: leaked publication lock" >&2; exit 1; }
}
run_case success success
# The signed DMG must precede its notarization, and only accepted images staple.
sign_line="$(/usr/bin/grep -nE 'mock-codesign --force --timestamp --sign .*\.dmg' "$TMP/success.log" | head -1 | cut -d: -f1)"
notary_line="$(/usr/bin/grep -nE 'mock-xcrun notarytool submit .*\.dmg' "$TMP/success.log" | head -1 | cut -d: -f1)"
staple_line="$(/usr/bin/grep -nE 'mock-xcrun stapler staple .*\.dmg' "$TMP/success.log" | head -1 | cut -d: -f1)"
[[ "$sign_line" -lt "$notary_line" && "$notary_line" -lt "$staple_line" ]]
run_case missing-certificate failure
run_case signature failure
run_case export failure
run_case archive failure
run_case app-notary failure
run_case dmg-notary failure
if /usr/bin/grep -Eq 'mock-xcrun notarytool|mock-hdiutil' "$TMP/archive.log"; then echo 'FAIL: continued after archive failure' >&2; exit 1; fi
if /usr/bin/grep -Eq 'mock-hdiutil|mock-xcrun stapler' "$TMP/app-notary.log"; then echo 'FAIL: continued after app rejection' >&2; exit 1; fi
if /usr/bin/grep -Eq 'mock-xcrun stapler staple .*\.dmg' "$TMP/dmg-notary.log"; then echo 'FAIL: continued after DMG rejection' >&2; exit 1; fi
/usr/libexec/PlistBuddy -c "Set :com.apple.security.application-groups:0 ABC123DE45.wrong" "$TMP/fixtures/widget-entitlements.plist"
run_case wrong-entitlement failure
if /usr/bin/grep -Eq 'mock-xcrun notarytool' "$TMP/wrong-entitlement.log"; then echo 'FAIL: notarized mismatched entitlements' >&2; exit 1; fi
# A signed old app is accepted only when its real signing team and App Group
# entitlement match the metadata we intend to preserve.
old="$TMP/old/DesktopWidgets.app"
mkdir -p "$old/Contents/PlugIns/DesktopWidgetsExtension.appex/Contents"
cp "$TMP/fixtures/app.plist" "$old/Contents/Info.plist"
cp "$TMP/fixtures/widget.plist" "$old/Contents/PlugIns/DesktopWidgetsExtension.appex/Contents/Info.plist"
export MOCK_LOG="$TMP/old-team.log" MOCK_SIGN_TEAM=DIFFERENT0
if "$SCRIPT" --team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$TMP/old-team.dmg" --existing-app "$old" > "$TMP/out" 2>&1; then
    echo 'FAIL: different signed team accepted' >&2; exit 1
fi
unset MOCK_SIGN_TEAM
export MOCK_LOG="$TMP/old-group.log"
if "$SCRIPT" --team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$TMP/old-group.dmg" --existing-app "$old" > "$TMP/out" 2>&1; then
    echo 'FAIL: mismatched signed App Group accepted' >&2; exit 1
fi
[[ ! -e "$TMP/old-team.dmg" && ! -e "$TMP/old-group.dmg" ]]
# Preserve nondefault personal-install identities on the first release and on
# subsequent updates using the manifest, even when repository defaults differ.
/usr/libexec/PlistBuddy -c 'Set :com.apple.security.application-groups:0 ABC123DE45.io.desktopwidgets.personal.abc123de45.shared' "$TMP/fixtures/widget-entitlements.plist"
/usr/libexec/PlistBuddy -c 'Set :com.apple.security.application-groups:0 ABC123DE45.io.desktopwidgets.personal.abc123de45.shared' "$TMP/fixtures/app-entitlements.plist"
for kind in app widget; do
    id=io.desktopwidgets.personal.abc123de45.app
    [[ "$kind" != widget ]] || id="$id.widgets"
    plutil -replace CFBundleIdentifier -string "$id" "$TMP/fixtures/$kind.plist"
    plutil -replace WidgetThemeAppGroupIdentifier -string ABC123DE45.io.desktopwidgets.personal.abc123de45.shared "$TMP/fixtures/$kind.plist"
done
cp "$TMP/fixtures/app.plist" "$old/Contents/Info.plist"
cp "$TMP/fixtures/widget.plist" "$old/Contents/PlugIns/DesktopWidgetsExtension.appex/Contents/Info.plist"
export MOCK_LOG="$TMP/preserve.log" MOCK_FAIL=success
"$SCRIPT" --team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$TMP/preserve.dmg" --existing-app "$old" > "$TMP/out" 2>&1
[[ "$(/usr/libexec/PlistBuddy -c 'Print :AppBundleID' "$TMP/preserve.identities.plist")" == io.desktopwidgets.personal.abc123de45.app ]]
export MOCK_LOG="$TMP/replay.log"
"$SCRIPT" --team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$TMP/replay.dmg" --identities-file "$TMP/preserve.identities.plist" > "$TMP/out" 2>&1
/usr/bin/cmp "$TMP/preserve.identities.plist" "$TMP/replay.identities.plist"
/usr/bin/grep -Fq 'DESKTOP_WIDGETS_APP_BUNDLE_IDENTIFIER = io.desktopwidgets.personal.abc123de45.app' "$MOCK_LOG.resolved.xcconfig"
/usr/bin/grep -Fq 'WIDGET_THEME_APP_GROUP = ABC123DE45.io.desktopwidgets.personal.abc123de45.shared' "$MOCK_LOG.resolved.xcconfig"
/usr/bin/grep -Fq 'DEVELOPMENT_TEAM = ABC123DE45' "$MOCK_LOG.resolved.xcconfig"
/usr/bin/grep -Fq 'CODE_SIGN_IDENTITY = 0123456789ABCDEF0123456789ABCDEF01234567' "$MOCK_LOG.resolved.xcconfig"
/usr/bin/grep -Fq 'DESKTOP_WIDGETS_DISTRIBUTION_CHANNEL = developer-id' "$MOCK_LOG.resolved.xcconfig"

# Ambiguous identity selection, a missing argument and cross-team manifests
# must fail before any Apple tool, build or upload is invoked.
for mode in ambiguous missing-value cross-team; do
    export MOCK_LOG="$TMP/preflight-$mode.log"
    args=(--team ABC123DE45 --identity 'Developer ID Application: Example' --notary-profile test --output "$TMP/preflight-$mode.dmg")
    case "$mode" in
        ambiguous) args+=(--new-install --existing-app "$old");;
        missing-value) args+=(--new-install --identity);;
        cross-team)
            cp "$TMP/preserve.identities.plist" "$TMP/other-team.plist"
            plutil -replace TeamID -string DIFFERENT0 "$TMP/other-team.plist"
            args+=(--identities-file "$TMP/other-team.plist");;
    esac
    if "$SCRIPT" "${args[@]}" > "$TMP/out" 2>&1; then
        echo "FAIL: accepted preflight-$mode" >&2; exit 1
    fi
    [[ ! -s "$MOCK_LOG" && ! -e "$TMP/preflight-$mode.dmg" ]]
done
if [[ "${RELEASE_TEST_REAL_XCODEBUILD:-0}" == 1 ]]; then
    # This only resolves settings. It never builds, signs, or uploads anything.
    for target in DesktopWidgets DesktopWidgetsExtension; do
        target_settings="$TMP/$target.settings.txt"
        /usr/bin/xcodebuild -showBuildSettings \
            -project "$ROOT/DesktopWidgets.xcodeproj" -target "$target" \
            -configuration Release -xcconfig "$TMP/replay.log.resolved.xcconfig" \
            > "$target_settings" 2> "$TMP/$target.xcodebuild-settings.log"
        [[ -s "$target_settings" ]]
        /usr/bin/grep -Fq 'DEVELOPMENT_TEAM = ABC123DE45' "$target_settings"
        /usr/bin/grep -Fq 'WIDGET_THEME_APP_GROUP = ABC123DE45.io.desktopwidgets.personal.abc123de45.shared' "$target_settings"
        /usr/bin/grep -Fq 'DESKTOP_WIDGETS_DISTRIBUTION_CHANNEL = developer-id' "$target_settings"
        if [[ "$target" == DesktopWidgets ]]; then
            expected_id=io.desktopwidgets.personal.abc123de45.app
        else
            expected_id=io.desktopwidgets.personal.abc123de45.app.widgets
        fi
        /usr/bin/grep -Fq "PRODUCT_BUNDLE_IDENTIFIER = $expected_id" "$target_settings"
    done
fi
echo 'Release workflow tests passed'
