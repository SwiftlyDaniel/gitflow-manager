import AppKit
import Foundation
import UniformTypeIdentifiers

class Settings: ObservableObject {
    private enum Keys: String {
        case projectsDirectory = "projectsDirectory"
        case terminalApp = "terminalApp"
        case textEditorApp = "textEditorApp"
        case openInTerminal = "openInTerminal"
        case openInTextEditor = "openInTextEditor"
    }
    
    static let shared = Settings()
    private let defaults = UserDefaults.standard
    
    @Published var projectsDirectory: URL {
        didSet { save(Keys.projectsDirectory, projectsDirectory.path) }
    }
    
    @Published var selectedTerminalApp: URL? {
        didSet { 
            if let path = selectedTerminalApp?.path {
                save(Keys.terminalApp, path)
            }
        }
    }
    
    @Published var selectedTextEditorApp: URL? {
        didSet {
            if let path = selectedTextEditorApp?.path {
                save(Keys.textEditorApp, path)
            }
        }
    }
    
    @Published var openInTerminal: Bool {
        didSet { save(Keys.openInTerminal, openInTerminal) }
    }
    
    @Published var openInTextEditor: Bool {
        didSet { save(Keys.openInTextEditor, openInTextEditor) }
    }
    
    private init() {
        self.openInTerminal = false
        self.openInTextEditor = false
        self.projectsDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer")
        self.selectedTerminalApp = nil
        self.selectedTextEditorApp = nil
        
        if let storedPath = defaults.string(forKey: Keys.projectsDirectory.rawValue) {
            self.projectsDirectory = URL(fileURLWithPath: storedPath)
        }
        
        if let terminalPath = defaults.string(forKey: Keys.terminalApp.rawValue) {
            self.selectedTerminalApp = URL(fileURLWithPath: terminalPath)
        } else {
            self.selectedTerminalApp = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
        }
        
        if let editorPath = defaults.string(forKey: Keys.textEditorApp.rawValue) {
            self.selectedTextEditorApp = URL(fileURLWithPath: editorPath)
        } else {
            self.selectedTextEditorApp = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit")
        }
        
        self.openInTerminal = defaults.bool(forKey: Keys.openInTerminal.rawValue)
        self.openInTextEditor = defaults.bool(forKey: Keys.openInTextEditor.rawValue)
    }
    
    private var defaultTerminalApp: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
    }
    
    private var defaultTextEditor: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit")
    }
    
    private func getStoredAppURL(for key: Keys) -> URL? {
        guard let path = defaults.string(forKey: key.rawValue) else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    private func save(_ key: Keys, _ value: Any) {
        defaults.set(value, forKey: key.rawValue)
    }
}

extension Settings {
    func selectDirectory() -> Bool {
        presentOpenPanel(
            title: "Select Projects Directory",
            message: "Choose the directory containing your git repositories",
            canChooseFiles: false,
            canChooseDirectories: true,
            allowedContentTypes: nil
        ) { [weak self] url in
            self?.projectsDirectory = url
        }
    }
    
    func selectTerminalApp() -> Bool {
        presentOpenPanel(
            title: "Select Terminal Application",
            message: "Choose your preferred terminal application",
            canChooseFiles: true,
            canChooseDirectories: false,
            allowedContentTypes: [UTType.application],
            directoryURL: URL(fileURLWithPath: "/Applications")
        ) { [weak self] url in
            self?.selectedTerminalApp = url
        }
    }
    
    func selectTextEditor() -> Bool {
        presentOpenPanel(
            title: "Select Text Editor Application",
            message: "Choose your preferred text editor",
            canChooseFiles: true,
            canChooseDirectories: false,
            allowedContentTypes: [UTType.application],
            directoryURL: URL(fileURLWithPath: "/Applications")
        ) { [weak self] url in
            self?.selectedTextEditorApp = url
        }
    }
    
    private func presentOpenPanel(
        title: String,
        message: String,
        canChooseFiles: Bool,
        canChooseDirectories: Bool,
        allowedContentTypes: [UTType]?,
        directoryURL: URL? = nil,
        completion: @escaping (URL) -> Void
    ) -> Bool {
        let openPanel = NSOpenPanel()
        openPanel.title = title
        openPanel.message = message
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = canChooseFiles
        openPanel.canChooseDirectories = canChooseDirectories
        openPanel.allowsMultipleSelection = false
        
        if let types = allowedContentTypes {
            openPanel.allowedContentTypes = types
        }
        
        if let directory = directoryURL {
            openPanel.directoryURL = directory
        }
        
        guard let window = NSApp.keyWindow else { return false }
        
        openPanel.level = window.level + 1
        positionPanel(openPanel, relativeTo: window)
        
        openPanel.beginSheetModal(for: window) { response in
            if response == .OK, let url = openPanel.url {
                completion(url)
            }
        }
        
        return true
    }
    
    private func positionPanel(_ panel: NSPanel, relativeTo window: NSWindow) {
        let windowFrame = window.frame
        let panelFrame = panel.frame
        let x = windowFrame.origin.x + (windowFrame.width - panelFrame.width) / 2
        let y = windowFrame.origin.y + (windowFrame.height - panelFrame.height) / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

extension Settings {
    func openInTerminal(path: String) {
        openPath(path, withApp: selectedTerminalApp, requiresTerminal: true)
    }
    
    func openInTextEditor(path: String) {
        openPath(path, withApp: selectedTextEditorApp, requiresTerminal: false)
    }
    
    private func openPath(_ path: String, withApp app: URL?, requiresTerminal: Bool) {
        guard requiresTerminal ? openInTerminal : openInTextEditor,
              let appURL = app else { return }
        
        let url = URL(fileURLWithPath: path)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration)
    }
}
