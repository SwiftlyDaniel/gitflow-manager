import SwiftUI

struct DirectorySection: View {
    @ObservedObject var settings: Settings
    
    var body: some View {
        Section {
            HStack {
                TextField("Projects Directory", text: .constant(settings.projectsDirectory.path))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                
                Button("Choose...") {
                    _ = settings.selectDirectory()
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Repository Directory")
        } footer: {
            Text("The directory where GitFlow Manager will look for git repositories")
                .font(.caption)
        }
    }
}
