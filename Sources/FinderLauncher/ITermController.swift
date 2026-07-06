import Foundation

enum ITermController {
    /// 在 iTerm2 中打开目录并执行命令。
    /// iTerm2 已有窗口时开新 Tab，否则开新窗口；未运行时自动拉起。
    static func open(directory: String, command: String) {
        // shell 层转义：单引号包裹，内部单引号替换为 '\''
        let escapedDir = directory.replacingOccurrences(of: "'", with: "'\\''")
        var shellCommand = "cd '\(escapedDir)'"
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            shellCommand += " && \(trimmed)"
        }

        // AppleScript 字符串字面量转义：\ 和 "
        let asCommand = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "iTerm"
            activate
            if (count of windows) = 0 then
                create window with default profile
            else
                tell current window
                    create tab with default profile
                end tell
            end if
            tell current session of current window
                write text "\(asCommand)"
            end tell
        end tell
        """
        AppleScriptRunner.run(script)
    }
}
