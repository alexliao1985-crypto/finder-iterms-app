import AppKit

/// app 是 LSUIElement 且秒退，出错时弹一个对话框，避免"点了没反应"。
enum ErrorAlert {
    static func showPermissionDenied(target: String) {
        let alert = makeAlert(
            title: "没有控制 \(target) 的权限",
            info: "请在 系统设置 → 隐私与安全性 → 自动化 中，允许本按钮控制 \(target)，然后再点一次。"
        )
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    static func show(title: String, error: AppleScriptError) {
        let alert = makeAlert(title: title, info: "\(error.message)（错误码 \(error.number)）")
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private static func makeAlert(title: String, info: String) -> NSAlert {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = info
        return alert
    }
}
