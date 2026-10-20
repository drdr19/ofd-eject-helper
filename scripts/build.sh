#!/bin/bash
# OFD 弹出助手 - 一键构建脚本
# 产出：dist/OFD弹出助手.dmg（通用二进制，支持 Apple Silicon + Intel）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="OFD弹出助手"
BUNDLE_ID="cn.cuihao.ofd-eject-helper"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/$APP_NAME.app"
DIST="$ROOT/dist"
DMG="$DIST/$APP_NAME.dmg"

echo "==> 清理旧产物"
rm -rf "$BUILD_DIR" "$DIST/$APP_NAME.dmg"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$DIST"

echo "==> 编译 arm64"
swiftc -O -target arm64-apple-macos13.0 -framework Cocoa \
    src/main.swift -o "$BUILD_DIR/app-arm64" 2>&1 | grep -v "warning:" || true

echo "==> 编译 x86_64"
swiftc -O -target x86_64-apple-macos13.0 -framework Cocoa \
    src/main.swift -o "$BUILD_DIR/app-x86_64" 2>&1 | grep -v "warning:" || true

echo "==> 合并为通用二进制"
lipo -create "$BUILD_DIR/app-arm64" "$BUILD_DIR/app-x86_64" \
     -output "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"
file "$APP/Contents/MacOS/$APP_NAME"

echo "==> 生成图标 (icns)"
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    sips -z $s $s assets/icon-1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z $d $d assets/icon-1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> 复制 Info.plist"
cp src/Info.plist "$APP/Contents/Info.plist"

echo "==> ad-hoc 签名"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose "$APP"

echo "==> 打包 DMG（需要 dmgbuild: pip install dmgbuild）"
python3 -m dmgbuild -s scripts/dmg_settings.py "$APP_NAME" "$DMG" 2>&1 | grep -vi "warning" || true

echo ""
echo "✅ 完成：$DMG"
ls -lh "$DMG"
