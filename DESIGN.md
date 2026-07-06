# FinderLauncher 设计文档

在 Finder 工具栏放置多个按钮，一键在 iTerm2 中打开当前文件夹，并可选自动执行命令（如 `claude`、`hermes`）。

## 1. 背景与目标

**痛点**：在 Finder 中浏览到某个目录后，想快速打开 iTerm2 并 `cd` 到该目录，甚至直接启动 claude code / hermes 会话，目前需要手动操作多步。

**目标**：
- Finder 工具栏一键：打开 iTerm2 并 cd 到当前 Finder 目录
- 支持多个按钮变体：纯打开 / 打开并执行 `claude` / 打开并执行 `hermes`
- 易扩展：新增按钮只需加一个 JSON 配置，无需改代码

**非目标**：不做右键菜单（Finder Sync 扩展）、不分发（仅本机自用，ad-hoc 签名）。

## 2. 总体架构

Finder 工具栏的每个"按钮"本质是一个被 `Cmd+拖` 上去的 `.app`。因此采用 **一份核心二进制 + N 个 App 变体** 的架构：

```
finder-iterms-app/
├── DESIGN.md
├── README.md
├── Package.swift               # SPM 可执行工程
├── Sources/FinderLauncher/
│   ├── main.swift              # 入口：读配置 → 取路径 → 驱动 iTerm2 → 退出
│   ├── FinderPath.swift        # 读取 Finder 最前窗口的目录
│   └── ITermController.swift   # 驱动 iTerm2（新建窗口/Tab + 执行命令）
├── variants/                   # 每个按钮一个配置文件
│   ├── OpenIniTerm.json
│   ├── OpenClaude.json
│   └── OpenHermes.json
├── build.sh                    # 编译一次，按配置批量打出 N 个 .app
└── dist/                       # 产物（git 忽略）
    ├── OpenIniTerm.app
    ├── OpenClaude.app
    └── OpenHermes.app
```

所有变体共享同一个二进制，差异只体现在各自 `Info.plist` 的自定义字段 `LauncherCommand` 和图标上。程序启动时读取自己 bundle 中的 `LauncherCommand` 来决定 cd 之后执行什么。

## 3. 运行流程

```
点击工具栏图标
  → app 启动（LSUIElement=YES，无窗口不占 Dock）
  → 读 Bundle 的 LauncherCommand 字段
  → AppleScript 问 Finder：最前窗口的目录路径（无窗口/特殊视图时 fallback 到 ~）
  → AppleScript 驱动 iTerm2：
      - iTerm2 无窗口 → 新建窗口；已有窗口 → 当前窗口新建 Tab
      - 在新 session 中 write text "cd '<路径>' && <命令>"
  → app 立即退出（生命周期 < 1 秒）
```

## 4. 变体配置 Schema（variants/*.json）

```json
{
  "name": "OpenClaude",
  "display_name": "Claude Code Here",
  "bundle_id": "com.alex.finderlauncher.claude",
  "command": "claude",
  "icon": "/Applications/Claude.app/Contents/Resources/electron.icns"
}
```

| 字段 | 说明 |
|---|---|
| `name` | 产物 app 名（`dist/<name>.app`） |
| `display_name` | Finder 中显示的名称 |
| `bundle_id` | 每个变体唯一，用于系统自动化授权（TCC）记录 |
| `command` | cd 之后要执行的命令，空字符串表示只 cd |
| `icon` | `.icns` 文件路径，或 `.app` 路径（打包时自动提取该应用图标）；留空/找不到时用默认 iTerm2 图标 |

### 自定义按钮（add-button.sh）

用户无需手写 JSON，一条命令完成"生成配置 → 打包 → 安装"：

```bash
./add-button.sh <名称> <命令> [图标] [显示名]   # 或不带参数进入交互式
```

脚本校验名称合法性（字母数字），自动生成 `bundle_id`，写入 `variants/<名称>.json`，然后调用 `./build.sh --install <名称>` 只打包这一个变体（不影响已装的其他按钮）。

## 5. 关键技术决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 工程形态 | SPM（`swift build`），不用 Xcode 工程 | 核心代码约 100 行，脚本打包更适合批量出变体 |
| Finder/iTerm2 通信 | Apple Events（NSAppleScript） | 官方支持、无需额外依赖；iTerm2 的 AppleScript API 支持 `write text`，可在 cd 后接任意命令 |
| 打开方式 | iTerm2 已有窗口开新 Tab，否则开新窗口 | 符合日常使用直觉，避免窗口泛滥 |
| 命令执行 | `write text "cd 'dir' && cmd"` | 在用户的交互式 shell 中执行，PATH 等环境与手敲一致（`~/.local/bin/claude` 可直接找到） |
| 签名 | ad-hoc（`codesign -s -`） | 仅本机自用，无需开发者账号/公证 |
| 路径转义 | 目录中的 `'` 转义为 `'\''`；整条命令再按 AppleScript 字符串规则转义 `\` 和 `"` | 防止特殊字符目录名破坏命令 |

## 6. 权限（TCC）

`Info.plist` 声明 `NSAppleEventsUsageDescription`。每个变体首次点击时，系统会弹两次"自动化"授权（控制 Finder、控制 iTerm2），各点一次"允许"即可，之后记录在 系统设置 → 隐私与安全性 → 自动化。

注意：ad-hoc 签名的 app 重新编译后签名变化，TCC 可能要求重新授权，属正常现象。

## 7. 边界情况

| 场景 | 行为 |
|---|---|
| Finder 没有打开任何窗口 | fallback 到 `~` |
| 最前窗口是"最近使用/AirDrop"等无实际路径的视图 | AppleScript 取 alias 失败，fallback 到 `~` |
| 目录名含单引号/空格/中文 | 已转义，正常工作 |
| 用户拒绝自动化授权 | 静默失败，日志写入统一日志（Console.app 可查）；到系统设置手动开启后恢复 |
| iTerm2 未启动 | `tell application "iTerm"` 自动拉起 |

## 8. 构建与安装

```bash
./build.sh                      # 编译 + 打包全部变体到 dist/
./build.sh --install            # 额外复制到 ~/Applications/
./build.sh --install OpenVSCode # 只打包并安装指定变体
./add-button.sh <名称> <命令> [图标] [显示名]  # 一键添加自定义按钮
```

安装：打开 `~/Applications`，按住 `Cmd` 把 app 拖到 Finder 工具栏。建议从 `~/Applications` 拖（路径稳定，重新构建覆盖同路径即可，工具栏引用不失效）。

## 9. 里程碑

- **M1**：单个"打开 iTerm2 并 cd"按钮跑通（取路径 + iTerm2 联动 + 工具栏拖放）
- **M2**：`LauncherCommand` 配置机制，验证 cd 后自动执行 `claude`
- **M3**：`build.sh` 批量出包三个变体 + 官方图标复用

## 10. 未来扩展

- 新增按钮（如 VS Code、Warp）：在 `variants/` 加一个 JSON，重跑 `build.sh`
- 支持"新窗口 vs 新 Tab"策略配置化（变体 JSON 加 `window_mode` 字段）
- 支持选中文件夹优先于当前窗口目录（读 Finder selection）
