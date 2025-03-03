import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GitFlow Manager")
                        .font(.title)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                    
                    Text("A macOS utility for streamlining Git Flow branch management in your projects.")
                        .foregroundStyle(.secondary)
                    
                    Link("View on GitHub", destination: URL(string: "https://github.com/SwiftlyDaniel")!)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AboutView()
}
