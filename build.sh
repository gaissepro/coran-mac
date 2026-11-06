#!/bin/zsh
# Compile et assemble Coran.app (signature ad hoc, aucun compte Apple requis).
set -e
cd "$(dirname "$0")"
mkdir -p .build
swiftc -O -parse-as-library -swift-version 5 -target arm64-apple-macosx14.0 Sources/Coran/*.swift -o .build/Coran
APP="build/Coran.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Fonts"
cp .build/Coran "$APP/Contents/MacOS/Coran"
cp Data/quran.json Data/hadith.json Data/extra.json Data/context.json Data/glossary.json "$APP/Contents/Resources/"
cp Fonts/*.ttf "$APP/Contents/Resources/Fonts/"
cp Icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Coran</string>
<key>CFBundleDisplayName</key><string>Coran</string>
<key>CFBundleIdentifier</key><string>local.gaisse.coran</string>
<key>CFBundleExecutable</key><string>Coran</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.5.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSMicrophoneUsageDescription</key><string>Pour vérifier ta récitation et ta lecture à voix haute.</string>
<key>NSSpeechRecognitionUsageDescription</key><string>Pour comparer ce que tu récites avec le texte du Coran.</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "OK -> $APP"
