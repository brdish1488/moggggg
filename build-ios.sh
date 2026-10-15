#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Payload/CircleTap.app"
rm -rf build
mkdir -p "$APP"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos swiftc main.swift \
  -parse-as-library -swift-version 5 -O \
  -sdk "$SDK" -target arm64-apple-ios15.0 \
  -framework UIKit -framework Foundation \
  -Xlinker -rpath -Xlinker /usr/lib/swift \
  -o "$APP/CircleTap"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>ru</string>
<key>CFBundleDisplayName</key><string>Лови круг</string>
<key>CFBundleExecutable</key><string>CircleTap</string>
<key>CFBundleIdentifier</key><string>com.circletap.demo</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>CircleTap</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>MinimumOSVersion</key><string>15.0</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UIRequiresFullScreen</key><true/>
<key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string></array>
</dict></plist>
PLIST
plutil -lint "$APP/Info.plist"
# Ad-hoc signature is NOT a distribution signature. LiveContainer must handle signing/loading.
codesign --force --sign - "$APP"
codesign --verify --verbose "$APP"
file "$APP/CircleTap"
(cd build && zip -qr CircleTap.ipa Payload)
unzip -t build/CircleTap.ipa
