#!/bin/bash

set -euo pipefail

readonly APP_PATH="${1:-}"
readonly EXTENSION_PATH="$APP_PATH/Contents/PlugIns/DesktopWidgetsExtension.appex"

if [[ -z "$APP_PATH" || ! -d "$EXTENSION_PATH" ]]; then
    echo "Widget runtime refresh skipped: built extension not found at $EXTENSION_PATH" >&2
    exit 0
fi

# Xcode replaces the extension executable in place, but chronod can keep the old
# process and descriptor alive. Stop only this app's extension before registering
# the newly built bundle, then restart the current user's widget daemon so the
# executable and App Intents metadata are always discovered as one version.
/usr/bin/pkill -x DesktopWidgetsExtension 2>/dev/null || true
/usr/bin/pluginkit -a "$EXTENSION_PATH"
/usr/bin/pkill -x -u "$(/usr/bin/id -u)" chronod 2>/dev/null || true

echo "Refreshed the Desktop Widgets development runtime."
