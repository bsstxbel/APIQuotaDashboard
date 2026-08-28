#!/bin/bash
set -euo pipefail

VERSION="${1:-2.1.0}"
BUILD_NUMBER="${2:-25}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"
CURRENT_DIR="$WORKSPACE_DIR/02_发布版本/当前版本"
HISTORY_DIR="$WORKSPACE_DIR/02_发布版本/历史版本"
DERIVED_DATA="$PROJECT_DIR/.build/release-$VERSION-$BUILD_NUMBER"
APP_PATH="$DERIVED_DATA/Build/Products/Release/API额度看板.app"
ARCHIVE_NAME="APIQuotaDashboard-v$VERSION.zip"
ARCHIVE_PATH="$CURRENT_DIR/$ARCHIVE_NAME"
TEMP_ARCHIVE="$PROJECT_DIR/.build/$ARCHIVE_NAME.pending"
SIGNING_DIR="$(mktemp -d /private/tmp/api-quota-release.XXXXXX)"
SIGNED_APP_PATH="$SIGNING_DIR/API额度看板.app"
LEGACY_ICON_SHA256="80d3d3e5ed573cdb10f23b09323278be562a267c6c4ab826c725817f0babeb52"

trap 'rm -rf "$SIGNING_DIR"' EXIT

INFO_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")
INFO_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PROJECT_DIR/Info.plist")
if [[ "$INFO_VERSION" != "$VERSION" || "$INFO_BUILD" != "$BUILD_NUMBER" ]]; then
  echo "Info.plist is $INFO_VERSION ($INFO_BUILD), expected $VERSION ($BUILD_NUMBER)." >&2
  exit 1
fi

mkdir -p "$CURRENT_DIR" "$HISTORY_DIR" "$PROJECT_DIR/.build"

env \
  CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache" \
  SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_DIR/.build/ModuleCache" \
  swift test --package-path "$PROJECT_DIR" --disable-sandbox

xcodebuild \
  -project "$PROJECT_DIR/APIQuotaDashboard.xcodeproj" \
  -scheme APIQuotaDashboard \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Release app was not produced at $APP_PATH" >&2
  exit 1
fi

APP_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
APP_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")
APP_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")
if [[ "$APP_VERSION" != "$VERSION" || "$APP_BUILD" != "$BUILD_NUMBER" ]]; then
  echo "Built app metadata mismatch: $APP_VERSION ($APP_BUILD)." >&2
  exit 1
fi
if [[ "$APP_IDENTIFIER" != "com.bsstxbel.api-quota-dashboard.v3" ]]; then
  echo "Unexpected bundle identifier: $APP_IDENTIFIER" >&2
  exit 1
fi

ARCHITECTURES=$(lipo -archs "$APP_PATH/Contents/MacOS/APIQuotaDashboard")
if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
  echo "Expected a Universal Binary, got: $ARCHITECTURES" >&2
  exit 1
fi

if [[ ! -f "$APP_PATH/Contents/Resources/Assets.car" ]]; then
  echo "Adaptive Icon Composer asset was not compiled." >&2
  exit 1
fi
COMPILED_ICON_SHA256=$(shasum -a 256 "$APP_PATH/Contents/Resources/APIQuotaDashboard.icns" | awk '{print $1}')
if [[ "$COMPILED_ICON_SHA256" == "$LEGACY_ICON_SHA256" ]]; then
  echo "The compiled app still contains the 1.5.x static icon." >&2
  exit 1
fi

# File-provider workspaces may immediately reattach Finder/resource-fork xattrs
# to a freshly built app. Stage the exact build product outside the provider
# workspace, strip metadata there, and sign/package that clean copy.
ditto --norsrc "$APP_PATH" "$SIGNED_APP_PATH"
xattr -cr "$SIGNED_APP_PATH"
codesign --force --deep --sign - "$SIGNED_APP_PATH"
codesign --verify --deep --strict --verbose=2 "$SIGNED_APP_PATH"

ditto -c -k --sequesterRsrc --keepParent "$SIGNED_APP_PATH" "$TEMP_ARCHIVE"
unzip -t "$TEMP_ARCHIVE"

shopt -s nullglob
for existing in "$CURRENT_DIR"/API额度看板-v*.zip "$CURRENT_DIR"/APIQuotaDashboard-v*.zip; do
  if [[ "$existing" != "$ARCHIVE_PATH" ]]; then
    mv "$existing" "$HISTORY_DIR/$(basename "$existing")"
  fi
done
shopt -u nullglob

mv -f "$TEMP_ARCHIVE" "$ARCHIVE_PATH"
CHECKSUM=$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')
printf '%s  %s\n' "$CHECKSUM" "$ARCHIVE_NAME" > "$CURRENT_DIR/SHA256校验值.txt"
printf '%s  %s\n' "$CHECKSUM" "$ARCHIVE_NAME" > "$WORKSPACE_DIR/04_文档/SHA256校验值.txt"

echo "Release ready: $ARCHIVE_PATH"
echo "Version: $APP_VERSION ($APP_BUILD)"
echo "Bundle ID: $APP_IDENTIFIER"
echo "Architectures: $ARCHITECTURES"
echo "SHA-256: $CHECKSUM"
