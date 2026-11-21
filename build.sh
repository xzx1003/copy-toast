#!/bin/zsh
set -eu
cd "${0:A:h}"
APP="$PWD/复制提示.app"
BIN="$APP/Contents/MacOS/CopyToast"
MIN_MACOS="13.0"
mkdir -p "$APP/Contents/MacOS"

# Build both slices so the app also runs on Intel Macs, then merge them.
build_slice() {
  xcrun swiftc main.swift -O \
    -target "$1-apple-macos$MIN_MACOS" \
    -o "$APP/Contents/MacOS/CopyToast-$1" \
    -framework Cocoa -framework ApplicationServices
}
build_slice arm64
build_slice x86_64
lipo -create "$APP/Contents/MacOS/CopyToast-arm64" "$APP/Contents/MacOS/CopyToast-x86_64" -output "$BIN"
rm -f "$APP/Contents/MacOS/CopyToast-arm64" "$APP/Contents/MacOS/CopyToast-x86_64"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CopyToast</string>
<key>CFBundleIdentifier</key><string>local.copytoast.app</string>
<key>CFBundleName</key><string>复制提示</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSInputMonitoringUsageDescription</key><string>识别 Command+C，并在剪贴板更新后显示复制提示。</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
print "已生成：$APP"
