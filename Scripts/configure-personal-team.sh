#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly LOCAL_CONFIGURATION="$PROJECT_ROOT/Local.xcconfig"

usage() {
    cat <<'EOF'
Usage: ./Scripts/configure-personal-team.sh [TEAM_ID]

Configure this checkout to sign with a free Xcode Personal Team without
committing the Team ID. If TEAM_ID is omitted, the script detects it from an
Apple Development certificate already installed by Xcode.

Before running this script:
  1. Open Xcode > Settings > Accounts and add your Apple Account.
  2. Select the account, choose Manage Certificates, and add an
     Apple Development certificate if one is not already listed.
EOF
}

detect_team_id() {
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null \
        | /usr/bin/sed -nE 's/.*"Apple Development: .*\(([A-Z0-9]{10})\)".*/\1/p' \
        | /usr/bin/head -n 1
}

team_id="${1:-}"
if [[ "$team_id" == "-h" || "$team_id" == "--help" ]]; then
    usage
    exit 0
fi

if [[ -z "$team_id" ]]; then
    team_id="$(detect_team_id)"
fi

if [[ ! "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
    echo "Unable to find a valid 10-character Apple Development Team ID." >&2
    echo >&2
    usage >&2
    exit 1
fi

if [[ -e "$LOCAL_CONFIGURATION" ]]; then
    existing_team_id="$(/usr/bin/sed -nE 's/^[[:space:]]*LOCAL_DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*([A-Z0-9]{10})[[:space:]]*$/\1/p' "$LOCAL_CONFIGURATION" | /usr/bin/head -n 1)"
    if [[ "$existing_team_id" == "$team_id" ]]; then
        echo "Personal Team $team_id is already configured in Local.xcconfig."
        exit 0
    fi

    echo "Refusing to overwrite existing $LOCAL_CONFIGURATION." >&2
    echo "Move or update that ignored file, then run this command again." >&2
    exit 1
fi

umask 077
printf '// Local signing identity; ignored by Git.\nLOCAL_DEVELOPMENT_TEAM = %s\n' "$team_id" > "$LOCAL_CONFIGURATION"

echo "Configured Personal Team $team_id in Local.xcconfig."
echo "Open DesktopWidgets.xcodeproj, select My Mac, and run DesktopWidgets."
