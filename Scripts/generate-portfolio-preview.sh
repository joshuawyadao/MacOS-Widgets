#!/bin/zsh

set -euo pipefail

resolve_developer_dir() {
  if [[ -n "${XCODE_DEVELOPER_DIR:-}" ]]; then
    if [[ -x "$XCODE_DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
      echo "$XCODE_DEVELOPER_DIR"
      return
    fi
    echo "FAIL: XCODE_DEVELOPER_DIR does not point to a full Xcode installation." >&2
    return 1
  fi

  if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    if [[ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
      echo "$DEVELOPER_DIR"
      return
    fi
    echo "FAIL: DEVELOPER_DIR does not point to a full Xcode installation." >&2
    return 1
  fi

  local system_selected
  system_selected="$(xcode-select --print-path 2>/dev/null || true)"
  if [[ -x "$system_selected/usr/bin/xcodebuild" ]]; then
    echo "$system_selected"
    return
  fi

  if [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
    echo "/Applications/Xcode.app/Contents/Developer"
    return
  fi

  echo "FAIL: Select a full Xcode installation or set DEVELOPER_DIR." >&2
  return 1
}

script_dir="${0:A:h}"
repository_root="${script_dir:h}"
preview_source="/private/tmp/DesktopWidgetsPortfolioPreview.png"
preview_request="/private/tmp/DesktopWidgetsPortfolioPreview.request"
preview_destination="$repository_root/docs/images/widgets-preview.png"
social_crop="/private/tmp/DesktopWidgetsSocialPreviewCrop.png"
social_destination="$repository_root/docs/images/widgets-social-preview.jpg"
derived_data="$(mktemp -d /private/tmp/DesktopWidgetsPortfolioDerived.XXXXXX)"
selected_developer_dir="$(resolve_developer_dir)"

cleanup() {
  rm -rf "$derived_data"
  rm -f "$preview_source"
  rm -f "$preview_request"
  rm -f "$social_crop"
}
trap cleanup EXIT

cd "$repository_root"
mkdir -p "${preview_destination:h}"
touch "$preview_request"

DEVELOPER_DIR="$selected_developer_dir" \
  xcodebuild test \
  -project DesktopWidgets.xcodeproj \
  -scheme DesktopWidgets \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data" \
  -only-testing:DesktopWidgetsTests/WidgetRenderingSmokeTests/testPortfolioPreviewRendersWithSyntheticData \
  CODE_SIGNING_ALLOWED=NO

cp "$preview_source" "$preview_destination"
sips \
  --cropToHeightWidth 716 1432 \
  --cropOffset 180 24 \
  "$preview_source" \
  --out "$social_crop" >/dev/null
sips \
  --resampleHeightWidth 640 1280 \
  --setProperty format jpeg \
  --setProperty formatOptions 88 \
  "$social_crop" \
  --out "$social_destination" >/dev/null

social_width="$(sips -g pixelWidth "$social_destination" | awk '/pixelWidth:/ { print $2 }')"
social_height="$(sips -g pixelHeight "$social_destination" | awk '/pixelHeight:/ { print $2 }')"
social_size="$(stat -f '%z' "$social_destination")"
if [[ "$social_width" != "1280" || "$social_height" != "640" ]]; then
  echo "FAIL: Social preview must be exactly 1280 x 640 pixels." >&2
  exit 1
fi
if (( social_size >= 1000000 )); then
  echo "FAIL: Social preview must be smaller than 1 MB." >&2
  exit 1
fi

echo "Generated $preview_destination"
echo "Generated $social_destination ($social_size bytes)"
