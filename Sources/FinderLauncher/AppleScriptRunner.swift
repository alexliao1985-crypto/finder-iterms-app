import Foundation

struct AppleScriptError: Error {
    let number: Int
    let message: String

    /// -1743: 用户拒绝了自动化授权；-1744: 需要授权但无法弹窗
    var isPermissionDenied: Bool { number == -1743 || number == -1744 }
}

enum AppleScriptRunner {
    /// 同步执行 AppleScript，返回字符串结果（无返回值时为空串）；失败时记录日志并返回错误。
    @discardableResult
    static func run(_ source: String) -> Result<String, AppleScriptError> {
        guard let script = NSAppleScript(source: source) else {
            NSLog("FinderLauncher: failed to parse AppleScript")
            return .failure(AppleScriptError(number: 0, message: "failed to parse AppleScript"))
        }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("FinderLauncher: AppleScript error: \(error)")
            let number = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? "\(error)"
            return .failure(AppleScriptError(number: number, message: message))
        }
        return .success(result.stringValue ?? "")
    }
}
