import AppKit
import SwiftUI

protocol WindowManaging: AnyObject {
    func openSettings()
    func closeSettings()
    func getCurrentWindow() -> NSWindow?
}

class WindowManager: WindowManaging, ObservableObject {
    static let shared = WindowManager(settings: Settings.shared)
    
    private let settings: Settings
    private var settingsWindow: NSWindow?
    private var settingsWindowDelegate: WindowDelegate?
    
    init(settings: Settings) {
        self.settings = settings
    }
    
    func openSettings() {
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = createWindow(
            title: "Settings",
            size: NSSize(width: 480, height: 300),
            style: [.titled, .closable, .miniaturizable]
        )
        
        settingsWindowDelegate = WindowDelegate(windowManager: self)
        window.delegate = settingsWindowDelegate
        
        window.contentView = NSHostingView(
            rootView: SettingsView()
                .environmentObject(settings)
        )
        
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSettings() {
        settingsWindow?.delegate = nil
        settingsWindow?.close()
        settingsWindowDelegate = nil
        settingsWindow = nil
    }
    
    func getCurrentWindow() -> NSWindow? {
        settingsWindow
    }
    
    private func createWindow(
        title: String,
        size: NSSize,
        style: NSWindow.StyleMask
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.center()
        window.setFrameAutosaveName(title)
        window.isReleasedWhenClosed = false
        
        return window
    }
}

private class WindowDelegate: NSObject, NSWindowDelegate {
    private weak var windowManager: WindowManaging?
    
    init(windowManager: WindowManaging) {
        self.windowManager = windowManager
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        windowManager?.closeSettings()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
