#!/bin/bash
# Builds PostureCoach.app without Xcode (Command Line Tools are enough).
set -euo pipefail
cd "$(dirname "$0")"

APP=build/PostureCoach.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O \
    -target "$(uname -m)-apple-macos14.0" \
    PostureCoach/*.swift \
    -o "$APP/Contents/MacOS/PostureCoach"

# Xcode substitutes the $(...) placeholders at build time; do it by hand here.
cp PostureCoach/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleExecutable PostureCoach" \
    -c "Set :CFBundleIdentifier com.pratikaman.PostureCoach" \
    -c "Set :CFBundleName PostureCoach" \
    -c "Set :CFBundleDevelopmentRegion en" \
    "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
echo "Run it with: open $APP"
