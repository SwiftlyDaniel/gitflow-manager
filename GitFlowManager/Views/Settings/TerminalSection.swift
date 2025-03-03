import SwiftUI

struct TerminalSection: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Section {
            HStack {
                TextField("Terminal Application",
                          text: .constant(settings.selectedTerminalApp?.lastPathComponent ?? "No terminal selected"))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                
                Button("Choose...") {
                    _ = settings.selectTerminalApp()
                }
            }
            .padding(.vertical, 4)
            
            Toggle("Open directory in terminal after branch creation",
                   isOn: $settings.openInTerminal)
        } header: {
            Text("Terminal Integration")
        } footer: {
            if settings.selectedTerminalApp == nil {
                Text("Select a terminal application to enable terminal integration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
