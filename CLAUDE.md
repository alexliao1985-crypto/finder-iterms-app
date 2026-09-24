# FinderLauncher

macOS 工具：Finder 工具栏按钮，一键在 iTerm2 中打开当前文件夹并可选执行命令（如 `claude`）。架构详见 [DESIGN.md](DESIGN.md)。

## 常用命令

```bash
./build.sh                       # swift build + 打包全部变体到 dist/（会清空 dist/）
./build.sh --install             # 打包并复制到 ~/Applications/
./build.sh --install <变体名>    # 只打包指定变体，不清空 dist/
./add-button.sh <名称> <命令> [图标] [显示名]   # 添加自定义按钮（生成 JSON + 打包 + 安装）
swift build -c release           # 只编译二进制
swift test                       # 转义逻辑单元测试
```

## 架构要点

- **一份二进制 + N 个 App 变体**：所有 `.app` 共享 `.build/release/FinderLauncher`，差异只在 Info.plist 的 `LauncherCommand` 字段和图标。变体由 `variants/*.json` 定义，`build.sh` 负责打包。
- 运行流程：读自身 bundle 的 `LauncherCommand` → AppleScript 取 Finder 选中的文件夹或最前窗口路径（失败 fallback `~`）→ AppleScript 驱动 iTerm2 开新 Tab/窗口并 `write text "cd '<dir>' && <cmd>"` → 退出。
- 核心代码在 `Sources/FinderLauncher/`：`main.swift`（入口，出错弹框）、`FinderPath.swift`（取路径：选中的文件夹 > 最前窗口 > `~`）、`ITermController.swift`（驱动 iTerm2）、`AppleScriptRunner.swift`（返回结果或错误码）、`ErrorAlert.swift`。
- 转义逻辑在 `Sources/LauncherCore/Escaping.swift`（shell 和 AppleScript 双层转义），单测在 `Tests/LauncherCoreTests/`，`swift test` 运行。
- `build.sh` 用 heredoc 写 Info.plist，所有值必须经 `xml_escape`，写完会 `plutil -lint`。

## 约束与注意事项

- **shell 脚本必须兼容 bash 3.2**（macOS 自带 `/bin/bash`，用户可能用 `sh build.sh` 运行）：不要用关联数组、`${var,,}` 等 bash 4+ 特性。
- 签名是 ad-hoc（`codesign -s -`），仅本机使用；重新编译后 TCC（自动化授权）可能要求用户重新允许，属正常现象。
- app 是 `LSUIElement`（无窗口无 Dock 图标），生命周期不足 1 秒；自动化授权被拒或 iTerm2 报错时弹框（`ErrorAlert`），错误同时写统一日志（`log show --predicate 'eventMessage CONTAINS "FinderLauncher"'` 可查）。
- `dist/` 和 `.build/` 已 gitignore，不要提交。
- CI（`.github/workflows/ci.yml`，macOS runner）跑单测、用系统 bash 3.2 打包全部变体、校验特殊字符变体和 plist/签名。

## 手动验证方式

```bash
open dist/OpenIniTerm.app   # 应打开 iTerm2 并 cd 到 Finder 选中的文件夹（无选中则最前窗口目录）
osascript -e 'tell application "iTerm" to tell current session of current window to get variable named "path"'
```

首次运行会弹"自动化"授权（控制 Finder / iTerm2），需在真机上人工点允许，无法自动化测试。
