#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"$ROOT/Scripts/build-core.sh"
command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen is required: brew install xcodegen" >&2; exit 1; }
xcodegen generate

rm -rf build/UnsignedIPA build/DerivedData
xcodebuild \
  -project PaopaoLocationSpoofer.xcodeproj \
  -scheme PaopaoLocationSpoofer \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

APP="build/DerivedData/Build/Products/Release-iphoneos/PaopaoLocationSpoofer.app"
if [ ! -d "$APP" ]; then
  echo "App bundle not found" >&2
  exit 1
fi

# A missing launch resource makes iOS use a smaller legacy compatibility viewport.
LAUNCH_STORYBOARD="$(/usr/libexec/PlistBuddy -c 'Print :UILaunchStoryboardName' "$APP/Info.plist")"
if [ -z "$LAUNCH_STORYBOARD" ] || [ ! -d "$APP/$LAUNCH_STORYBOARD.storyboardc" ]; then
  echo "Compiled launch storyboard is missing from the app bundle" >&2
  exit 1
fi

mkdir -p build/UnsignedIPA/Payload dist
ditto "$APP" "build/UnsignedIPA/Payload/PaopaoLocationSpoofer.app"
BUILD_TIMESTAMP="${BUILD_TIMESTAMP:-$(date '+%Y%m%d-%H%M%S')}"
case "$BUILD_TIMESTAMP" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
  *) echo "BUILD_TIMESTAMP must use yyyyMMdd-HHmmss format" >&2; exit 2 ;;
esac
IPA="$ROOT/dist/PaopaoLocationSpoofer-unsigned.ipa"
TIMESTAMPED_IPA="$ROOT/dist/PaopaoLocationSpoofer-${BUILD_TIMESTAMP}-unsigned.ipa"
rm -f "$IPA"
cd build/UnsignedIPA
zip -qry "$IPA" Payload
ditto "$IPA" "$TIMESTAMPED_IPA"
echo "Output: $IPA"
echo "Timestamped output: $TIMESTAMPED_IPA"
