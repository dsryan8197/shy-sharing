#!/usr/bin/env bash
# Builds "build/Shy Sharing.app" from the Swift package.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/Shy Sharing.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/ShySharing" "$APP/Contents/MacOS/ShySharing"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
