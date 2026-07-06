#!/bin/bash
# 添加一个自定义 Finder 工具栏按钮，并打包安装到 ~/Applications/
#
# 用法:
#   ./add-button.sh                                    # 交互式
#   ./add-button.sh <名称> <命令> [图标] [显示名]      # 命令行
#
# 示例:
#   ./add-button.sh OpenVSCode "code ." "/Applications/Visual Studio Code.app"
#   ./add-button.sh OpenLazygit "lazygit"
#
# 图标可以是 .icns 文件，也可以直接给 .app 路径（自动提取图标）；留空用默认 iTerm2 图标。
set -euo pipefail
cd "$(dirname "$0")"

NAME="${1:-}"
COMMAND="${2:-}"
ICON="${3:-}"
DISPLAY_NAME="${4:-}"

if [[ -z "$NAME" ]]; then
    read -rp "按钮名称（英文字母数字，如 OpenVSCode）: " NAME
    read -rp "cd 到目录后要执行的命令（留空 = 只打开 iTerm2）: " COMMAND
    read -rp "图标（.icns 或 .app 路径，留空用默认）: " ICON
    read -rp "显示名（留空 = 同按钮名称）: " DISPLAY_NAME
fi

if [[ ! "$NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
    echo "ERROR: 名称只能是英文字母和数字，且以字母开头: $NAME"
    exit 1
fi

[[ -z "$DISPLAY_NAME" ]] && DISPLAY_NAME="$NAME"
BUNDLE_ID="com.finderlauncher.$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"
CFG="variants/$NAME.json"

if [[ -f "$CFG" ]]; then
    echo "注意: $CFG 已存在，将覆盖"
fi

jq -n \
    --arg name "$NAME" \
    --arg dn "$DISPLAY_NAME" \
    --arg bid "$BUNDLE_ID" \
    --arg cmd "$COMMAND" \
    --arg icon "$ICON" \
    '{name: $name, display_name: $dn, bundle_id: $bid, command: $cmd, icon: $icon}' \
    > "$CFG"

echo "==> 已生成 $CFG"
./build.sh --install "$NAME"

echo ""
echo "完成！按住 Cmd 把 ~/Applications/$NAME.app 拖到 Finder 工具栏即可。"
