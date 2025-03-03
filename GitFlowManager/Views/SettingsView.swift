import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings
    
    var body: some View {
        Form {
            DirectorySection(settings: settings)
            TerminalSection(settings: settings)
            TextEditorSection(settings: settings)
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
        .environmentObject(Settings.shared)
}
