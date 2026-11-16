"""Check parity, required resource files, and translated UI source keys."""
import json
import pathlib
import plistlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
entries = json.loads((root / 'Resources/Translations.json').read_text())
assert set(entries['en']) == set(entries['ja'])
for lang, values in entries.items():
    assert all(isinstance(value, str) and value.strip() for value in values.values()), lang
keys = set()
for file in (root / 'Sources').glob('*.swift'):
    source = file.read_text()
    keys.update(re.findall(r'\btr\("([^"\n]*)"\)', source))
    for heading, body in re.findall(r'section\("([^"\n]*)", "([^"\n]*)"', source):
        keys.update([heading, body])
    keys.update(re.findall(r'(?:status|statusSource)\s*=\s*"([^"\n]*)"', source))
missing = keys - set(entries['en'])
assert not missing, f'Missing translations: {missing}'
app = root / '.build/CaptionBridge.app'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleShortVersionString'] == '0.2.0'
assert info['LSMinimumSystemVersion'] == '27.0'
for lang in ('zh-Hans', 'en', 'ja'):
    data = plistlib.loads((app / f'Contents/Resources/{lang}.lproj/InfoPlist.strings').read_bytes())
    assert data['CFBundleDisplayName']
    assert data['NSScreenCaptureUsageDescription']
assert (app / 'Contents/Resources/Guide.html').exists()
assert (app / 'Contents/Resources/AppIcon.icns').exists()
print(f'PASS: {len(entries["en"])} translated strings; three permission localizations; bundled guide and icon')
