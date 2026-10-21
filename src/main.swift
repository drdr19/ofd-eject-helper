import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 激活本 App，确保弹窗出现在最前面
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)

        // 1. 检测是否有 OFD 缩略图进程卡住占用
        let diagnosis = Self.diagnose()
        showResultDialog(diagnosis)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 窗口关闭即退出
        return true
    }

    // MARK: - 检测逻辑

    private struct Diagnosis {
        var isProblem: Bool
        var pids: [Int32]
        var message: String
    }

    private static func diagnose() -> Diagnosis {
        // 用 libproc 原生枚举进程（纯内存，不依赖 /bin/ps，零阻塞零权限）
        let pids = runningOFDPIDs()
        if pids.isEmpty {
            return Diagnosis(
                isProblem: false,
                pids: [],
                message: "检测正常 ✅\n\n当前没有卡住的 OFD 缩略图进程，\n移动硬盘应该可以正常弹出。\n\n如果仍然弹不出，可能是其他程序占用，\n可以再告诉我帮你看。"
            )
        }
        return Diagnosis(
            isProblem: true,
            pids: pids,
            message: "检测到 OFD 缩略图进程卡住 🛑\n\n有 \(pids.count) 个后台进程占用着文件句柄，\n导致移动硬盘无法弹出。\n\n是否清理此进程？"
        )
    }

    /// 用 libproc 的 proc_listpids + proc_name 找出所有 OFD 缩略图进程的 PID。
    /// 纯内存操作，不调用外部命令，不会被系统权限拦截。
    private static func runningOFDPIDs() -> [Int32] {
        // 第一次调用获取进程数量
        let count = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard count > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(count))
        let bytes = Int(count) * MemoryLayout<pid_t>.size
        let got = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(bytes))
        guard got > 0 else { return [] }

        let actualCount = Int(got) / MemoryLayout<pid_t>.size

        var result: [Int32] = []
        var nameBuf = [CChar](repeating: 0, count: 256)

        for i in 0..<actualCount {
            let pid = pids[i]
            guard pid > 0 else { continue }
            // proc_name 获取进程名（含完整命令路径）
            let len = proc_name(pid, &nameBuf, UInt32(nameBuf.count))
            guard len > 0 else { continue }
            let name = String(cString: nameBuf)
            if name.contains("OFD_Thumbnail") || name.contains("OFD_Thumb") {
                result.append(pid)
            }
        }
        return result
    }

    // MARK: - 弹窗 UI

    private func showResultDialog(_ diag: Diagnosis) {
        let alert = NSAlert()

        if diag.isProblem {
            alert.messageText = "检测到占用"
            alert.informativeText = diag.message
            alert.alertStyle = .warning
            // 清理按钮（默认）
            alert.addButton(withTitle: "清理此进程")
            alert.addButton(withTitle: "不清理此进程")
        } else {
            alert.messageText = "一切正常"
            alert.informativeText = diag.message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "好的")
        }

        // 用独立窗口承载，确保能正常关闭
        alert.window.title = "WH-1：OFD弹出助手"
        alert.window.level = .floating

        let response = alert.runModal()

        if diag.isProblem {
            if response == .alertFirstButtonReturn {
                // 用户选择「清理此进程」
                let cleaned = Self.killPIDs(diag.pids)
                showDoneDialog(cleaned: cleaned, pids: diag.pids)
            } else {
                // 用户选择「不清理此进程」—— 直接退出
                NSApp.terminate(nil)
            }
        } else {
            // 一切正常，点了「好的」直接退出
            NSApp.terminate(nil)
        }
    }

    private func showDoneDialog(cleaned: Bool, pids: [Int32]) {
        let alert = NSAlert()
        alert.messageText = "好的"
        alert.informativeText = cleaned
            ? "清理完成 ✅\n\n已结束 \(pids.count) 个占用进程，\n现在可以去手动弹出移动硬盘了。"
            : "清理过程中遇到问题，\n不过可能已经无进程占用了，\n你可以先试试手动弹出。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "完成")
        alert.window.title = "WH-1：OFD弹出助手"
        alert.window.level = .floating

        alert.runModal()
        // 点击「完成」后退出 App
        NSApp.terminate(nil)
    }

    /// 结束指定 PID 的进程
    private static func killPIDs(_ pids: [Int32]) -> Bool {
        var allOK = true
        for pid in pids {
            let r = kill(pid, SIGTERM)
            if r != 0 { allOK = false }
        }
        return allOK
    }
}

// MARK: - 入口

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
