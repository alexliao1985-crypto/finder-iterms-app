import Foundation
import LauncherCore

enum ITermController {
    /// 在 iTerm2 中打开目录并执行命令。
    /// iTerm2 已有窗口时开新 Tab，否则开新窗口；未运行时自动拉起。
    @discardableResult
    static func open(directory: String, command: String) -> Result<String, AppleScriptError> {
        // 先做 shell 层转义，再整体转成 AppleScript 字符串字面量
        let shellCommand = Escaping.shellCommand(directory: directory, command: command)

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
                write text \(Escaping.appleScriptString(shellCommand))
            end tell
        end tell
        """
        return AppleScriptRunner.run(script)
    }
}
