#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repository_root="${script_dir:h}"
preview_source="/private/tmp/DesktopWidgetsPortfolioPreview.png"
preview_request="/private/tmp/DesktopWidgetsPortfolioPreview.request"
preview_destination="$repository_root/docs/images/widgets-preview.png"
derived_data="$(mktemp -d /private/tmp/DesktopWidgetsPortfolioDerived.XXXXXX)"

cleanup() {
  rm -rf "$derived_data"
  rm -f "$preview_source"
  rm -f "$preview_request"
}
trap cleanup EXIT

cd "$repository_root"
mkdir -p "${preview_destination:h}"
touch "$preview_request"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcodebuild test \
  -project DesktopWidgets.xcodeproj \
  -scheme DesktopWidgets \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data" \
  -only-testing:DesktopWidgetsTests/WidgetRenderingSmokeTests/testPortfolioPreviewRendersWithSyntheticData \
  CODE_SIGNING_ALLOWED=NO

cp "$preview_source" "$preview_destination"
echo "Generated $preview_destination"
