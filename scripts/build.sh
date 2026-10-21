#!/bin/bash
# WH-1：OFD弹出助手 - 一键构建脚本
# 产出：dist/WH-1-OFD-Eject-Helper.dmg（通用二进制，支持 Apple Silicon + Intel）
# 注：DMG 文件名用 ASCII，因为 GitHub Release 会把中文文件名剥成纯英文；
#     挂载后显示的磁盘卷名仍是中文「WH-1：OFD弹出助手」。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="WH-1：OFD弹出助手"
BUNDLE_ID="cn.cuihao.wh-1-ofd-eject-helper"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/$APP_NAME.app"
DIST="$ROOT/dist"
DMG="$DIST/WH-1-OFD-Eject-Helper.dmg"

echo "==> 清理旧产物"
rm -rf "$BUILD_DIR"
rm -f "$DIST"/*.dmg 2>/dev/null || true
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
# 注意：这里不能用 `| grep -vi warning || true` 包起来。
# 那样会把 dmgbuild 的失败吞掉——镜像挂载成功但文件没拷进去，
# 结果是一个 1MB 的空壳 DMG 却打印"完成"。踩过一次。
python3 -m dmgbuild -s scripts/dmg_settings.py "$APP_NAME" "$DMG"

echo "==> 自检 DMG 内容（防止空壳镜像）"
MOUNT="$(mktemp -d)"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT" >/dev/null
if [ ! -x "$MOUNT/$APP_NAME.app/Contents/MacOS/$APP_NAME" ]; then
    echo "❌ DMG 里没有可执行文件：$APP_NAME.app/Contents/MacOS/$APP_NAME"
    hdiutil detach "$MOUNT" >/dev/null 2>&1 || true
    exit 1
fi
codesign --verify --verbose "$MOUNT/$APP_NAME.app"
hdiutil detach "$MOUNT" >/dev/null
rmdir "$MOUNT" 2>/dev/null || true

echo ""
echo "✅ 完成：$DMG"
ls -lh "$DMG"
