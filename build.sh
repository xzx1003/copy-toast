#!/bin/zsh
set -eu
cd "${0:A:h}"
APP="$PWD/复制提示.app"
mkdir -p "$APP/Contents/MacOS"
xcrun swiftc CopyToast/main.swift -o "$APP/Contents/MacOS/CopyToast" -framework Cocoa -framework ApplicationServices
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CopyToast</string>
<key>CFBundleIdentifier</key><string>local.copytoast.app</string>
<key>CFBundleName</key><string>复制提示</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
<key>NSInputMonitoringUsageDescription</key><string>识别 Command+C，并在剪贴板更新后显示复制提示。</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
print "已生成：$APP"
