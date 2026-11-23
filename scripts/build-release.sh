#!/bin/zsh
# Release 構成の arm64 .app をビルドし、ad-hoc 署名を確認して dist/ に .app と .zip を作る。
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED=build/DerivedData
APP_NAME=PointerOverlay
DIST=dist

xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
  -destination "platform=macOS,arch=arm64" -derivedDataPath "$DERIVED" clean build -quiet

SRC="$DERIVED/Build/Products/Release/$APP_NAME.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$SRC/Contents/Info.plist")

rm -rf "$DIST" && mkdir -p "$DIST"
ditto "$SRC" "$DIST/$APP_NAME.app"
codesign --verify --deep --strict "$DIST/$APP_NAME.app"
ditto -c -k --keepParent "$DIST/$APP_NAME.app" "$DIST/$APP_NAME-$VERSION-arm64.zip"

echo "arch:    $(lipo -archs "$DIST/$APP_NAME.app/Contents/MacOS/$APP_NAME")"
echo "version: $VERSION"
echo "app:     $DIST/$APP_NAME.app"
echo "zip:     $DIST/$APP_NAME-$VERSION-arm64.zip"
