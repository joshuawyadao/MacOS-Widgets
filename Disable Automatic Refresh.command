#!/bin/bash

set -euo pipefail
readonly COMMAND_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
exec /bin/bash "$COMMAND_DIRECTORY/Scripts/manage-automatic-refresh.sh" disable
