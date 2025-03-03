import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject private var settings: Settings
    
    enum NavigationItem: String {
        case newBranch = "New Branch"
        case settings = "Settings"
        case about = "About"
        
        var icon: String {
            switch self {
            case .newBranch: return "plus.circle"
            case .settings: return "gear"
            case .about: return "info.circle"
            }
        }
    }
    
    @State private var selection: NavigationItem? = .newBranch
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach([NavigationItem.newBranch, .settings, .about], id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }
            .navigationTitle("GitFlow Manager")
        } detail: {
            NavigationStack {
                switch selection {
                case .newBranch:
                    BranchCreationView(viewModel: viewModel)
                        .navigationTitle("Create Branch")
                case .settings:
                    SettingsView()
                        .navigationTitle("Settings")
                case .about:
                    AboutView()
                        .navigationTitle("About")
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRepositories()
            }
        }
    }
}

struct MainPreview: View {
    var body: some View {
        let settings = Settings.shared
        let repoManager = RepositoryManager.shared
        let branchManager = BranchManager(gitService: GitCommandService.shared, repoManager: repoManager)
        let viewModel = MainViewModel(repoManager: repoManager, branchManager: branchManager, settings: settings)
        
        MainView(viewModel: viewModel)
            .environmentObject(settings)
    }
}

#Preview {
    MainPreview()
}
