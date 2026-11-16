#!/bin/zsh
set -eu
cd "${0:A:h:h}"
zsh scripts/build.sh
mkdir -p dist
stage="$(mktemp -d "$PWD/.build/dmg.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
ditto "$PWD/.build/CaptionBridge.app" "$stage/CaptionBridge.app"
ln -s /Applications "$stage/Applications"
cp Resources/Guide.html "$stage/Start Here - 开始使用 - はじめに.html"
cp LICENSE "$stage/LICENSE.txt"
dmg="$PWD/dist/CaptionBridge-0.2.0-macOS-arm64.dmg"
hdiutil create -volname CaptionBridge -srcfolder "$stage" -ov -format UDZO -fs HFS+ "$dmg"
if [[ -n "${CAPTIONBRIDGE_NOTARY_PROFILE:-}" ]]; then
  if [[ "${CAPTIONBRIDGE_SIGN_IDENTITY:--}" == '-' ]]; then
    echo 'Notarization requires CAPTIONBRIDGE_SIGN_IDENTITY (Developer ID Application).' >&2
    exit 1
  fi
  xcrun notarytool submit "$dmg" --keychain-profile "$CAPTIONBRIDGE_NOTARY_PROFILE" --wait
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
fi
hdiutil verify "$dmg"
cp Resources/Guide.html dist/CaptionBridge-Guide-zh-en-ja.html
(cd dist && shasum -a 256 "${dmg:t}") > dist/SHA256SUMS.txt
echo "$dmg"
