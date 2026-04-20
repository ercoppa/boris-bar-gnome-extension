#!/bin/bash
set -e
cd "$(dirname "$0")"

APP="BorisBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/clips"

swiftc boris_bar.swift -O \
  -o "$APP/Contents/MacOS/BorisBar" \
  -framework Cocoa \
  -framework AVFoundation \
  -framework ServiceManagement

cp Info.plist         "$APP/Contents/Info.plist"
cp assets/fish.svg    "$APP/Contents/Resources/fish.svg"
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
for ext in mp3 mp4 m4a wav aiff aif caf; do
  cp assets/clips/*.$ext "$APP/Contents/Resources/clips/" 2>/dev/null || true
done

codesign --force --deep --sign - "$APP"
echo "Built $APP"
