#!/bin/bash
set -e
cd "$(dirname "$0")"

APP="BorisBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/clips"

# Universal binary (arm64 + x86_64) pinned to macOS 13.0 deployment target.
# Forces Swift to only emit symbols available on Sequoia (15) and below,
# avoiding "symbol not found" crashes on older OS versions when the host
# SDK is newer.
TARGETS=("arm64-apple-macos13.0" "x86_64-apple-macos13.0")
TMP=$(mktemp -d)
for t in "${TARGETS[@]}"; do
  swiftc boris_bar.swift -O \
    -target "$t" \
    -o "$TMP/BorisBar-${t%%-*}" \
    -framework Cocoa \
    -framework AVFoundation \
    -framework ServiceManagement
done
lipo -create "$TMP"/BorisBar-* -output "$APP/Contents/MacOS/BorisBar"
rm -rf "$TMP"

cp Info.plist         "$APP/Contents/Info.plist"
cp assets/fish.svg    "$APP/Contents/Resources/fish.svg"
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp DISCLAIMER.txt     "$APP/Contents/Resources/DISCLAIMER.txt"
cp LICENSE            "$APP/Contents/Resources/LICENSE.txt"
for ext in mp3 mp4 m4a wav aiff aif caf; do
  cp assets/clips/*.$ext "$APP/Contents/Resources/clips/" 2>/dev/null || true
done

codesign --force --deep --sign - "$APP"
echo "Built $APP"
