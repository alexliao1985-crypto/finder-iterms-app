import Foundation

// 从自身 bundle 读取本变体要执行的命令（空字符串 = 只 cd）
let command = Bundle.main.object(forInfoDictionaryKey: "LauncherCommand") as? String ?? ""

let directory = FinderPath.currentDirectory()
ITermController.open(directory: directory, command: command)
