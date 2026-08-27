#!/bin/bash

set -euo pipefail

readonly APP_PATH="${1:-}"
readonly EXTENSION_PATH="$APP_PATH/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly PLUGINKIT_COMMAND="${WIDGET_REFRESH_PLUGINKIT_COMMAND:-/usr/bin/pluginkit}"
readonly PKILL_COMMAND="${WIDGET_REFRESH_PKILL_COMMAND:-/usr/bin/pkill}"
readonly ID_COMMAND="${WIDGET_REFRESH_ID_COMMAND:-/usr/bin/id}"
readonly PLISTBUDDY_COMMAND="${WIDGET_REFRESH_PLISTBUDDY_COMMAND:-/usr/libexec/PlistBuddy}"
readonly DERIVED_DATA_ROOT="${WIDGET_REFRESH_DERIVED_DATA_ROOT:-${HOME}/Library/Developer/Xcode/DerivedData}"

if [[ -z "$APP_PATH" || ! -d "$EXTENSION_PATH" ]]; then
    echo "Widget runtime refresh skipped: built extension not found at $EXTENSION_PATH" >&2
    exit 0
fi

canonical_directory() {
    (cd "$1" && pwd -P)
}

is_stale_development_registration() {
    local registered_path="$1"
    local current_path="$2"
    local derived_data_root="${DERIVED_DATA_ROOT%/}"

    if [[ -d "$derived_data_root" ]]; then
        derived_data_root="$(canonical_directory "$derived_data_root")"
    fi
    [[ "$registered_path" != "$current_path" ]] || return 1
    [[ "$registered_path" == "$derived_data_root/"* ]]
}

unregister_stale_development_copies() {
    local current_path="$1"
    local bundle_identifier="$2"
    local registrations
    local line
    local registered_path
    local comparison_path

    registrations="$("$PLUGINKIT_COMMAND" -m -A -D -i "$bundle_identifier" -vv 2>/dev/null || true)"
    while IFS= read -r line; do
        case "$line" in
        *"Path = "*)
            registered_path="${line#*Path = }"
            registered_path="${registered_path%$'\r'}"
            comparison_path="$registered_path"
            if [[ -d "$comparison_path" ]]; then
                comparison_path="$(canonical_directory "$comparison_path")"
            fi
            if is_stale_development_registration "$comparison_path" "$current_path"; then
                if "$PLUGINKIT_COMMAND" -r "$registered_path"; then
                    echo "Unregistered stale Desktop Widgets extension at $registered_path"
                else
                    echo "Warning: could not unregister stale Desktop Widgets extension at $registered_path" >&2
                fi
            fi
            ;;
        esac
    done <<< "$registrations"
}

readonly CURRENT_EXTENSION_PATH="$(canonical_directory "$EXTENSION_PATH")"
readonly EXTENSION_BUNDLE_IDENTIFIER="$("$PLISTBUDDY_COMMAND" -c 'Print :CFBundleIdentifier' "$CURRENT_EXTENSION_PATH/Contents/Info.plist")"

# Xcode replaces the extension executable in place, but chronod can keep the old
# process and descriptor alive. Multiple Xcode worktrees can also register the
# same bundle identifier from different DerivedData directories. Remove only
# those stale development registrations, then register the current bundle and
# restart the current user's widget daemon. Installed copies outside DerivedData
# and all placed-widget configuration remain untouched.
unregister_stale_development_copies "$CURRENT_EXTENSION_PATH" "$EXTENSION_BUNDLE_IDENTIFIER"
"$PKILL_COMMAND" -x DesktopWidgetsExtension 2>/dev/null || true
"$PLUGINKIT_COMMAND" -a "$CURRENT_EXTENSION_PATH"
"$PKILL_COMMAND" -x -u "$("$ID_COMMAND" -u)" chronod 2>/dev/null || true

echo "Refreshed the Desktop Widgets development runtime."
