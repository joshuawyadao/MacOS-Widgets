#!/bin/bash

set -euo pipefail

readonly APP_PATH="${1:-}"
readonly EXTENSION_PATH="$APP_PATH/Contents/PlugIns/DesktopWidgetsExtension.appex"
readonly PLUGINKIT_COMMAND="${WIDGET_REFRESH_PLUGINKIT_COMMAND:-/usr/bin/pluginkit}"
readonly PKILL_COMMAND="${WIDGET_REFRESH_PKILL_COMMAND:-/usr/bin/pkill}"
readonly ID_COMMAND="${WIDGET_REFRESH_ID_COMMAND:-/usr/bin/id}"
readonly PLISTBUDDY_COMMAND="${WIDGET_REFRESH_PLISTBUDDY_COMMAND:-/usr/libexec/PlistBuddy}"
readonly DERIVED_DATA_ROOTS="${WIDGET_REFRESH_DERIVED_DATA_ROOTS:-${WIDGET_REFRESH_DERIVED_DATA_ROOT:-${HOME}/Library/Developer/Xcode/DerivedData}}"
readonly HISTORIC_DEFAULT_EXTENSION_BUNDLE_IDENTIFIER="com.joshuawyadao.DesktopWidgets.Widgets"

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
    local derived_data_root

    [[ "$registered_path" != "$current_path" ]] || return 1
    while IFS= read -r derived_data_root; do
        derived_data_root="${derived_data_root%/}"
        [[ -n "$derived_data_root" ]] || continue
        if [[ -d "$derived_data_root" ]]; then
            derived_data_root="$(canonical_directory "$derived_data_root")"
        fi
        [[ "$registered_path" == "$derived_data_root/"* ]] && return 0
    done < <(/usr/bin/printf '%s\n' "$DERIVED_DATA_ROOTS" | /usr/bin/tr ':' '\n')
    return 1
}

is_legacy_registration_to_remove() {
    local registered_path="$1"
    local current_path="$2"

    [[ "$registered_path" == "$current_path" ]] && return 0
    is_stale_development_registration "$registered_path" "$current_path"
}

unregister_matching_copies() {
    local current_path="$1"
    local bundle_identifier="$2"
    local path_predicate="$3"
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
            if "$path_predicate" "$comparison_path" "$current_path"; then
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

legacy_extension_bundle_identifiers() {
    local current_identifier="$1"

    /usr/bin/printf '%s\n' "$HISTORIC_DEFAULT_EXTENSION_BUNDLE_IDENTIFIER"
    case "$current_identifier" in
    io.desktopwidgets.personal.*.app.widgets)
        /usr/bin/printf '%s\n' "${current_identifier%.app.widgets}.widgets"
        ;;
    esac
}

readonly CURRENT_EXTENSION_PATH="$(canonical_directory "$EXTENSION_PATH")"
readonly EXTENSION_BUNDLE_IDENTIFIER="$("$PLISTBUDDY_COMMAND" -c 'Print :CFBundleIdentifier' "$CURRENT_EXTENSION_PATH/Contents/Info.plist")"

# Xcode replaces the extension executable in place, but chronod can keep the old
# process and descriptor alive. Multiple Xcode worktrees can also register the
# same or a retired Desktop Widgets bundle identifier from different DerivedData
# directories. Remove only those stale development registrations, then register
# the current bundle and restart the current user's widget daemon. Installed
# copies outside DerivedData and all placed-widget configuration remain untouched.
unregister_matching_copies "$CURRENT_EXTENSION_PATH" "$EXTENSION_BUNDLE_IDENTIFIER" is_stale_development_registration
while IFS= read -r legacy_identifier; do
    [[ -n "$legacy_identifier" && "$legacy_identifier" != "$EXTENSION_BUNDLE_IDENTIFIER" ]] || continue
    unregister_matching_copies "$CURRENT_EXTENSION_PATH" "$legacy_identifier" is_legacy_registration_to_remove
done < <(legacy_extension_bundle_identifiers "$EXTENSION_BUNDLE_IDENTIFIER")
"$PKILL_COMMAND" -x DesktopWidgetsExtension 2>/dev/null || true
"$PLUGINKIT_COMMAND" -a "$CURRENT_EXTENSION_PATH"
"$PKILL_COMMAND" -x -u "$("$ID_COMMAND" -u)" chronod 2>/dev/null || true

echo "Refreshed the Desktop Widgets development runtime."
