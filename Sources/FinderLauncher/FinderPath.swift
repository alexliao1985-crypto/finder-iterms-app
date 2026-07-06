import Foundation

enum FinderPath {
    /// 返回 Finder 最前窗口的目录（POSIX 路径）。
    /// 无窗口或窗口无实际路径（如"最近使用"）时 fallback 到用户主目录。
    static func currentDirectory() -> String {
        let script = """
        tell application "Finder"
            if (count of Finder windows) > 0 then
                try
                    return POSIX path of (target of front Finder window as alias)
                on error
                    return POSIX path of (path to home folder)
                end try
            else
                return POSIX path of (path to home folder)
            end if
        end tell
        """
        guard let result = AppleScriptRunner.run(script), !result.isEmpty else {
            return NSHomeDirectory()
        }
        return result
    }
}
