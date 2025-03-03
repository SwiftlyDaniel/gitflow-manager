import SwiftUI

@main
struct GitFlowManagerApp: App {
    private let settings: Settings
    private let windowManager: WindowManager
    private let viewModel: MainViewModel
    
    init() {
        let settings = Settings.shared
        let repoManager = RepositoryManager.shared
        let branchManager = BranchManager(gitService: GitCommandService.shared, repoManager: repoManager)
        
        self.settings = settings
        self.windowManager = WindowManager(settings: settings)
        self.viewModel = MainViewModel(repoManager: repoManager, branchManager: branchManager, settings: settings)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
                .environmentObject(settings)
                .environmentObject(windowManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
