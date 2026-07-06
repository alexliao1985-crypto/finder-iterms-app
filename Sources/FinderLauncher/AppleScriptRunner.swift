import Foundation

enum AppleScriptRunner {
    /// 同步执行 AppleScript，返回字符串结果；失败时记录日志并返回 nil。
    @discardableResult
    static func run(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else {
            NSLog("FinderLauncher: failed to parse AppleScript")
            return nil
        }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("FinderLauncher: AppleScript error: \(error)")
            return nil
        }
        return result.stringValue
    }
}
