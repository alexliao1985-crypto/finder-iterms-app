import Foundation

// 从自身 bundle 读取本变体要执行的命令（空字符串 = 只 cd）
let command = Bundle.main.object(forInfoDictionaryKey: "LauncherCommand") as? String ?? ""

let directory: String = {
    switch FinderPath.currentDirectory() {
    case .success(let path):
        return path
    case .failure(let error):
        if error.isPermissionDenied {
            ErrorAlert.showPermissionDenied(target: "Finder")
            exit(1)
        }
        return NSHomeDirectory()
    }
}()

if case .failure(let error) = ITermController.open(directory: directory, command: command) {
    if error.isPermissionDenied {
        ErrorAlert.showPermissionDenied(target: "iTerm2")
    } else {
        ErrorAlert.show(title: "无法在 iTerm2 中打开目录", error: error)
    }
    exit(1)
}
