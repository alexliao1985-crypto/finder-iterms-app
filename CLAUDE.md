# FinderLauncher

macOS 工具：Finder 工具栏按钮，一键在 iTerm2 中打开当前文件夹并可选执行命令（如 `claude`）。架构详见 [DESIGN.md](DESIGN.md)。

## 常用命令

```bash
./build.sh                       # swift build + 打包全部变体到 dist/（会清空 dist/）
./build.sh --install             # 打包并复制到 ~/Applications/
./build.sh --install <变体名>    # 只打包指定变体，不清空 dist/
./add-button.sh <名称> <命令> [图标] [显示名]   # 添加自定义按钮（生成 JSON + 打包 + 安装）
swift build -c release           # 只编译二进制
```

## 架构要点

- **一份二进制 + N 个 App 变体**：所有 `.app` 共享 `.build/release/FinderLauncher`，差异只在 Info.plist 的 `LauncherCommand` 字段和图标。变体由 `variants/*.json` 定义，`build.sh` 负责打包。
- 运行流程：读自身 bundle 的 `LauncherCommand` → AppleScript 取 Finder 最前窗口路径（失败 fallback `~`）→ AppleScript 驱动 iTerm2 开新 Tab/窗口并 `write text "cd '<dir>' && <cmd>"` → 退出。
- 核心代码在 `Sources/FinderLauncher/`（约 100 行）：`main.swift`（入口）、`FinderPath.swift`（取路径）、`ITermController.swift`（驱动 iTerm2，含 shell 和 AppleScript 双层转义）、`AppleScriptRunner.swift`。

## 约束与注意事项

- **shell 脚本必须兼容 bash 3.2**（macOS 自带 `/bin/bash`，用户可能用 `sh build.sh` 运行）：不要用关联数组、`${var,,}` 等 bash 4+ 特性。
- 签名是 ad-hoc（`codesign -s -`），仅本机使用；重新编译后 TCC（自动化授权）可能要求用户重新允许，属正常现象。
- app 是 `LSUIElement`（无窗口无 Dock 图标），生命周期不足 1 秒，出错只写统一日志（`log show --predicate 'eventMessage CONTAINS "FinderLauncher"'` 可查）。
- `dist/` 和 `.build/` 已 gitignore，不要提交。

## 手动验证方式

```bash
open dist/OpenIniTerm.app   # 应打开 iTerm2 并 cd 到 Finder 最前窗口目录
osascript -e 'tell application "iTerm" to tell current session of current window to get variable named "path"'
```

首次运行会弹"自动化"授权（控制 Finder / iTerm2），需在真机上人工点允许，无法自动化测试。
