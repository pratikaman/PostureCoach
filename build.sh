#!/bin/bash
# Builds Posture Malone.app without Xcode (Command Line Tools are enough).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Posture Malone.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O \
    -target "$(uname -m)-apple-macos14.0" \
    PostureMalone/*.swift \
    -o "$APP/Contents/MacOS/Posture Malone"

# Xcode substitutes the $(...) placeholders at build time; do it by hand here.
cp PostureMalone/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleExecutable Posture Malone" \
    -c "Set :CFBundleIdentifier com.pratikaman.PostureMalone" \
    -c "Set :CFBundleName Posture Malone" \
    -c "Set :CFBundleDevelopmentRegion en" \
    "$APP/Contents/Info.plist"
cp PostureMalone/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "Built $APP"
echo "Run it with: open \"$APP\""
