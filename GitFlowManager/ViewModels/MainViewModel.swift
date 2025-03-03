import Combine
import Foundation

@MainActor
class MainViewModel: ObservableObject {
    @Published private(set) var repositories: [GitRepository] = []
    @Published var selectedRepository: GitRepository? {
        didSet {
            if oldValue?.id != selectedRepository?.id {
                hasRepositoryBeenPrepared = false
                Task {
                    await prepareRepository()
                }
            }
        }
    }
    @Published var branchType: BranchType? {
        didSet {
            if oldValue != branchType {
                updateBranchSummary()
            }
        }
    }
    @Published var issueNumber: String = "" {
        didSet {
            if oldValue != issueNumber {
                updateBranchSummary()
            }
        }
    }
    @Published var branchName: String = "" {
        didSet {
            if oldValue != branchName {
                updateBranchSummary()
            }
        }
    }
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var branchSummary: String = ""
    
    private var hasRepositoryBeenPrepared = false
    
    private let repoManager: RepositoryManagerProtocol
    private let branchManager: BranchManagerProtocol
    private let settings: Settings
    
    init(
        repoManager: RepositoryManagerProtocol,
        branchManager: BranchManagerProtocol,
        settings: Settings
    ) {
        self.repoManager = repoManager
        self.branchManager = branchManager
        self.settings = settings
    }
    
    func loadRepositories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            repositories = try await repoManager.discoverRepositories(inDirectory: nil)
            if (repositories.isEmpty) {
                errorMessage = "No git repositories found in '(settings.projectsDirectory.path)'. Please check the directory in Settings or add some Git repositories to this location."
                selectedRepository = nil
            }
        } catch let error as RepositoryManager.RepositoryError {
            errorMessage = error.errorDescription
            repositories = []
            selectedRepository = nil
        } catch {
            errorMessage = error.localizedDescription
            repositories = []
            selectedRepository = nil
        }
        
        isLoading = false
    }
    
    func prepareRepository() async {
        guard let repository = selectedRepository, !hasRepositoryBeenPrepared else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let isMainBranch = await repoManager.checkMainBranchType(for: repository)
            let updatedRepository = GitRepository(
                id: repository.id,
                name: repository.name,
                path: repository.path,
                isMainBranchMain: isMainBranch
            )
            selectedRepository = updatedRepository
            
            try await branchManager.prepareRepository(updatedRepository)
            hasRepositoryBeenPrepared = true
            updateBranchSummary()
        } catch {
            errorMessage = error.localizedDescription
            hasRepositoryBeenPrepared = false
            selectedRepository = nil
            branchSummary = ""
        }
        
        isLoading = false
    }
    
    func createBranch() async {
        guard let repository = selectedRepository,
              let type = branchType,
              !issueNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                !branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await branchManager.createBranch(
                inRepository: repository,
                type: type,
                issueNumber: issueNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                name: branchName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if settings.openInTerminal {
                repoManager.openInTerminal(repository: repository)
            }
            
            if settings.openInTextEditor {
                settings.openInTextEditor(path: repository.path)
            }
            
            reset()
        } catch {
            errorMessage = error.localizedDescription
            selectedRepository = nil
            branchSummary = ""
        }
        
        isLoading = false
    }
    
    func updateBranchSummary() {
        guard let type = branchType,
              let repository = selectedRepository
        else {
            branchSummary = ""
            return
        }
        
        let baseBranch = type == .feature ? "develop" : repository.mainBranchName
        let name = formatBranchName(type: type, issue: issueNumber, name: branchName)
        
        branchSummary = """
            Repository: \(repository.name)
            Base Branch: \(baseBranch)
            New Branch: \(name)
            """
    }
    
    private func formatBranchName(type: BranchType, issue: String, name: String) -> String {
        let components = [issue, name]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: " ", with: "_") }
        
        return "\(type.prefix)/\(components.joined(separator: "-"))"
    }
    
    func reset() {
        selectedRepository = nil
        branchType = nil
        issueNumber = ""
        branchName = ""
        errorMessage = nil
        branchSummary = ""
        hasRepositoryBeenPrepared = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
#if DEBUG
    func setRepositoriesForPreview(_ repos: [GitRepository]) {
        repositories = repos
    }
#endif
}
