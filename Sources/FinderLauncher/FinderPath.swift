import Foundation

enum FinderPath {
    /// 返回要打开的目录（POSIX 路径），优先级：
    /// 1. Finder 中恰好选中一个文件夹（或磁盘）→ 该文件夹
    /// 2. Finder 最前窗口的目录
    /// 3. 无窗口或窗口无实际路径（如"最近使用"）→ 用户主目录
    static func currentDirectory() -> Result<String, AppleScriptError> {
        let script = """
        tell application "Finder"
            try
                set sel to selection
                if (count of sel) = 1 then
                    set theItem to item 1 of sel
                    if class of theItem is in {folder, disk} then
                        return POSIX path of (theItem as alias)
                    end if
                end if
            end try
            if (count of Finder windows) > 0 then
                try
                    return POSIX path of (target of front Finder window as alias)
                end try
            end if
            return POSIX path of (path to home folder)
        end tell
        """
        return AppleScriptRunner.run(script).map { $0.isEmpty ? NSHomeDirectory() : $0 }
    }
}
