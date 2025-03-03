import SwiftUI

struct TextEditorSection: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Section {
            HStack {
                TextField("Text Editor",
                          text: .constant(settings.selectedTextEditorApp?.lastPathComponent ?? "No editor selected"))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                
                Button("Choose...") {
                    _ = settings.selectTextEditor()
                }
            }
            .padding(.vertical, 4)
            
            Toggle("Open directory in editor after branch creation",
                   isOn: $settings.openInTextEditor)
        } header: {
            Text("Text Editor Integration")
        } footer: {
            if settings.selectedTextEditorApp == nil {
                Text("Select a text editor to enable editor integration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
