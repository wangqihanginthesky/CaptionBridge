#!/bin/zsh
set -eu
cd "${0:A:h:h}"
app_path="$PWD/.build/CaptionBridge.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources" "$PWD/.build/AppIcon.iconset"
xcrun swiftc -swift-version 5 -target arm64-apple-macos27.0 -parse-as-library -O Sources/*.swift -o "$app_path/Contents/MacOS/LiveCaptions"
/usr/bin/say -v Samantha -o "$app_path/Contents/Resources/english-sample.aiff" 'We have seen significant improvements in our ranking model.'
xcrun swift scripts/make-icon.swift "$PWD/.build/AppIcon-1024.png"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$PWD/.build/AppIcon-1024.png" --out "$PWD/.build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$PWD/.build/AppIcon-1024.png" --out "$PWD/.build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$PWD/.build/AppIcon.iconset" -o "$app_path/Contents/Resources/AppIcon.icns"
cp Resources/Translations.json Resources/Guide.html "$app_path/Contents/Resources/"
cp LICENSE "$app_path/Contents/Resources/LICENSE.txt"
python3 - "$app_path" <<'PY'
import plistlib, sys
from pathlib import Path
app = Path(sys.argv[1])
info = {
    'CFBundleIdentifier': 'local.bilingualcaptions.app',
    'CFBundleName': 'CaptionBridge',
    'CFBundleDisplayName': 'CaptionBridge',
    'CFBundleExecutable': 'LiveCaptions',
    'CFBundleIconFile': 'AppIcon',
    'CFBundlePackageType': 'APPL',
    'CFBundleVersion': '2',
    'CFBundleShortVersionString': '0.2.0',
    'CFBundleDevelopmentRegion': 'en',
    'CFBundleLocalizations': ['zh-Hans', 'en', 'ja'],
    'LSMinimumSystemVersion': '27.0',
    'LSUIElement': True,
    'NSHighResolutionCapable': True,
    'NSScreenCaptureUsageDescription': 'CaptionBridge processes computer audio locally to show bilingual captions. It does not save screen images.',
    'NSSpeechRecognitionUsageDescription': 'CaptionBridge transcribes English speech on this Mac to show captions.',
}
(app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
strings = {
'zh-Hans': {
    'CFBundleDisplayName': '听桥 · CaptionBridge',
    'NSScreenCaptureUsageDescription': '听桥在本机处理电脑播放的声音并显示双语字幕，不保存屏幕画面。',
    'NSSpeechRecognitionUsageDescription': '听桥在这台 Mac 上识别英语语音并显示字幕。',
},
'en': {
    'CFBundleDisplayName': 'CaptionBridge',
    'NSScreenCaptureUsageDescription': info['NSScreenCaptureUsageDescription'],
    'NSSpeechRecognitionUsageDescription': info['NSSpeechRecognitionUsageDescription'],
},
'ja': {
    'CFBundleDisplayName': 'ことばブリッジ · CaptionBridge',
    'NSScreenCaptureUsageDescription': 'CaptionBridgeはMacの再生音をデバイス内で処理し、二言語字幕を表示します。画面の画像は保存しません。',
    'NSSpeechRecognitionUsageDescription': 'CaptionBridgeはこのMacで英語の音声を認識し、字幕を表示します。',
}}
for lang, entries in strings.items():
    folder = app / 'Contents/Resources' / (lang + '.lproj')
    folder.mkdir(exist_ok=True)
    (folder / 'InfoPlist.strings').write_bytes(plistlib.dumps(entries, fmt=plistlib.FMT_XML))
PY
signing_identity="${CAPTIONBRIDGE_SIGN_IDENTITY:--}"
if [[ "$signing_identity" == '-' ]]; then
  codesign --force --options runtime --sign - "$app_path"
else
  codesign --force --options runtime --timestamp --sign "$signing_identity" "$app_path"
fi
codesign --verify --deep --strict "$app_path"
echo "$app_path"
