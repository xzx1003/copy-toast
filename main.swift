import Cocoa
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    var status: NSStatusItem!
    var monitor: Any?
    var localMonitor: Any?
    var timer: Timer?
    var panel: NSPanel?
    var hideWork: DispatchWorkItem?
    var lastChange = NSPasteboard.general.changeCount
    var pendingBaseline: Int?
    var deadline = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "📋"
        let menu = NSMenu()
        menu.addItem(withTitle: "复制提示已开启", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "测试提示", action: #selector(testToast), keyEquivalent: "").target = self
        menu.addItem(withTitle: "开启输入监控权限…", action: #selector(openPermissions), keyEquivalent: "").target = self
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q").target = self
        status.menu = menu
        let trusted = AXIsProcessTrusted()
        menu.items[0].title = "剪贴板检测已开启"
        menu.insertItem(withTitle: "开启辅助功能权限…", action: #selector(openAccessibility), keyEquivalent: "", at: 1)
        menu.items[1].target = self
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return event
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.poll() }
        NSLog("CopyToast: accessibility=%@ inputMonitoring=%@", String(trusted), String(CGPreflightListenEventAccess()))
        toast("复制提示已开启")
    }

    func handle(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard event.keyCode == 8, modifiers.contains(.command),
              !modifiers.contains(.control), !modifiers.contains(.option),
              !modifiers.contains(.shift), !event.isARepeat else { return }
        // Use the last sampled count: the target app may already have handled copy.
        pendingBaseline = pendingBaseline ?? lastChange
        deadline = Date().addingTimeInterval(1.2)
        poll()
    }

    func poll() {
        let count = NSPasteboard.general.changeCount
        // Clipboard changes work even when macOS blocks global keyboard events.
        if count != lastChange {
            pendingBaseline = nil
            lastChange = count
            if !(NSPasteboard.general.types ?? []).isEmpty {
                toast("复制成功，快去粘贴吧")
            }
            return
        }
        if let baseline = pendingBaseline {
            if count != baseline {
                pendingBaseline = nil
                toast("复制成功，快去粘贴吧")
            } else if Date() >= deadline {
                pendingBaseline = nil
                toast("未检测到剪贴板更新，请再复制一次")
            }
        }
        lastChange = count
    }

    func toast(_ message: String) {
        hideWork?.cancel()
        panel?.orderOut(nil)
        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        let width = max(320, label.intrinsicContentSize.width + 56)
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let screen else { return }
        let frame = NSRect(x: screen.visibleFrame.midX - width / 2, y: screen.visibleFrame.minY + 100, width: width, height: 68)
        let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 16
        background.layer?.masksToBounds = true
        label.frame = NSRect(x: 20, y: 22, width: width - 40, height: 25)
        background.addSubview(label)
        window.contentView = background
        window.orderFrontRegardless()
        panel = window
        let work = DispatchWorkItem { [weak window] in window?.orderOut(nil) }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    @objc func openPermissions() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
    }
    @objc func testToast() { toast("复制成功，快去粘贴吧") }
    @objc func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
