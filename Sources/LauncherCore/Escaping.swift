import Foundation

public enum Escaping {
    /// shell 层转义：单引号包裹，内部单引号替换为 '\''
    public static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// 拼出在 iTerm2 中执行的整条命令：cd '<dir>' [&& <command>]
    public static func shellCommand(directory: String, command: String) -> String {
        var result = "cd \(shellQuote(directory))"
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result += " && \(trimmed)"
        }
        return result
    }

    /// AppleScript 字符串字面量（含两侧双引号）：转义 \ 和 "
    public static func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
