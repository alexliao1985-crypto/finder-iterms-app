#!/bin/bash
# 编译核心二进制，并按 variants/*.json 打包 .app
# 用法: ./build.sh [--install] [变体名...]
#   不带变体名: 打包全部变体（会清空 dist/）
#   带变体名:   只打包指定变体，如 ./build.sh --install OpenVSCode
#   --install:  额外复制到 ~/Applications/
set -euo pipefail
cd "$(dirname "$0")"

INSTALL=false
VARIANTS=()
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=true ;;
        *) VARIANTS+=("$arg") ;;
    esac
done

echo "==> swift build -c release"
swift build -c release
BIN=".build/release/FinderLauncher"

DEFAULT_ICON="/Applications/iTerm.app/Contents/Resources/iTerm2 App Icon for Release.icns"

# 解析图标: 支持 .icns 文件路径，或 .app 路径（自动提取其图标）
resolve_icon() {
    local icon="$1"
    [[ -z "$icon" || "$icon" == "null" ]] && return 1
    if [[ "$icon" == *.icns && -f "$icon" ]]; then
        echo "$icon"; return 0
    fi
    if [[ "$icon" == *.app && -d "$icon" ]]; then
        local res="$icon/Contents/Resources"
        local file
        file=$(defaults read "$icon/Contents/Info" CFBundleIconFile 2>/dev/null || true)
        [[ -n "$file" && "$file" != *.icns ]] && file="$file.icns"
        if [[ -n "$file" && -f "$res/$file" ]]; then
            echo "$res/$file"; return 0
        fi
        local first
        first=$(ls "$res"/*.icns 2>/dev/null | head -1 || true)
        [[ -n "$first" ]] && { echo "$first"; return 0; }
    fi
    return 1
}

PACKAGED=()

package_variant() {
    local cfg="$1"
    local name display_name bundle_id command icon
    name=$(jq -r '.name' "$cfg")
    display_name=$(jq -r '.display_name' "$cfg")
    bundle_id=$(jq -r '.bundle_id' "$cfg")
    command=$(jq -r '.command' "$cfg")
    icon=$(jq -r '.icon // ""' "$cfg")

    local app="dist/$name.app"
    echo "==> packaging $app (command='$command')"

    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$BIN" "$app/Contents/MacOS/$name"

    local icns
    if icns=$(resolve_icon "$icon"); then
        cp "$icns" "$app/Contents/Resources/AppIcon.icns"
    else
        echo "    WARN: 图标未找到 ($icon)，使用默认 iTerm2 图标"
        cp "$DEFAULT_ICON" "$app/Contents/Resources/AppIcon.icns"
    fi

    cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$name</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_id</string>
    <key>CFBundleName</key>
    <string>$display_name</string>
    <key>CFBundleDisplayName</key>
    <string>$display_name</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>需要控制 Finder 获取当前目录，并控制 iTerm2 打开终端。</string>
    <key>LauncherCommand</key>
    <string>$command</string>
</dict>
</plist>
EOF

    codesign --force -s - "$app"
    PACKAGED+=("$name")
}

if [[ ${#VARIANTS[@]} -gt 0 ]]; then
    mkdir -p dist
    for v in "${VARIANTS[@]}"; do
        if [[ ! -f "variants/$v.json" ]]; then
            echo "ERROR: variants/$v.json 不存在。已有变体:"
            ls variants/ | sed 's/\.json$//; s/^/  - /'
            exit 1
        fi
        package_variant "variants/$v.json"
    done
else
    rm -rf dist
    mkdir -p dist
    for cfg in variants/*.json; do
        package_variant "$cfg"
    done
fi

echo ""
echo "==> Done. Packaged: ${PACKAGED[*]}"

if $INSTALL; then
    echo ""
    echo "==> Installing to ~/Applications/"
    mkdir -p ~/Applications
    for name in "${PACKAGED[@]}"; do
        target="$HOME/Applications/$name.app"
        # Finder 工具栏通过 alias(含 inode) 引用 app，保留 .app 目录本身只替换内容，
        # 避免整目录 rm -rf 导致重装后工具栏引用失效
        if [[ -d "$target" ]]; then
            rm -rf "$target/Contents"
            ditto "dist/$name.app/Contents" "$target/Contents"
        else
            ditto "dist/$name.app" "$target"
        fi
        echo "    $target"
    done
    echo ""
    echo "打开 ~/Applications，按住 Cmd 把 app 拖到 Finder 工具栏即可。"
fi
