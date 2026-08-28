#!/usr/bin/env bash
# Build a universal SpeedRead.app and wrap it in a drag-to-install DMG.
#
# Unsigned by default (runs locally, but downloaders hit Gatekeeper). To ship a
# public build, export these first:
#
#   DEVELOPER_ID_APP="Developer ID Application: NAME (TEAMID)"
#   NOTARY_PROFILE="speedread-notary"   # from: xcrun notarytool store-credentials
#
# Usage: scripts/package.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(grep 'MARKETING_VERSION:' project.yml | head -1 | sed 's/.*"\(.*\)".*/\1/')}"
DIST="dist"
ARCHIVE="$DIST/SpeedRead.xcarchive"
APP="$DIST/SpeedRead.app"
DMG="$DIST/SpeedRead-$VERSION.dmg"

echo "==> SpeedRead $VERSION"
rm -rf "$DIST"; mkdir -p "$DIST"

command -v xcodegen >/dev/null || { echo "need xcodegen: brew install xcodegen"; exit 1; }
xcodegen generate

echo "==> Archiving (universal)"
xcodebuild -project SpeedRead.xcodeproj -scheme SpeedRead -configuration Release \
  -destination 'generic/platform=macOS' \
  archive -archivePath "$ARCHIVE" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="${DEVELOPER_ID_APP:--}" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  | grep -E 'error:|warning:|ARCHIVE (SUCCEEDED|FAILED)' || true

cp -R "$ARCHIVE/Products/Applications/SpeedRead.app" "$APP"
echo "==> Binary: $(lipo -archs "$APP/Contents/MacOS/SpeedRead")"

if [[ -n "${DEVELOPER_ID_APP:-}" ]]; then
  echo "==> Signing with Developer ID + hardened runtime"
  codesign --force --deep --options runtime --timestamp \
    --sign "$DEVELOPER_ID_APP" "$APP"
  codesign --verify --strict --verbose=2 "$APP"

  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "==> Notarizing"
    ditto -c -k --keepParent "$APP" "$DIST/SpeedRead.zip"
    xcrun notarytool submit "$DIST/SpeedRead.zip" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    rm -f "$DIST/SpeedRead.zip"
  else
    echo "!! NOTARY_PROFILE unset — skipping notarization (Gatekeeper will block downloads)"
  fi
else
  echo "!! DEVELOPER_ID_APP unset — unsigned build (local use only)"
fi

echo "==> Building DMG"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "SpeedRead $VERSION" -srcfolder "$STAGING" \
  -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

if [[ -n "${DEVELOPER_ID_APP:-}" ]]; then
  codesign --force --sign "$DEVELOPER_ID_APP" "$DMG"
  [[ -n "${NOTARY_PROFILE:-}" ]] && xcrun stapler staple "$DMG" || true
fi

shasum -a 256 "$DMG"
echo "==> Done: $DMG"
