import Foundation

protocol RepositoryManagerProtocol {
    var defaultRepositoryDirectory: URL { get }
    func discoverRepositories(inDirectory directory: URL?) async throws
    -> [GitRepository]
    func checkMainBranchType(for repository: GitRepository) async -> Bool
    func openInTerminal(repository: GitRepository)
}

class RepositoryManager: RepositoryManagerProtocol {
    enum RepositoryError: Error, LocalizedError {
        case directoryNotFound(String)
        case directoryNotReadable(String)
        case discoveryFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .directoryNotFound(let path):
                return "Directory does not exist at \(path)."
            case .directoryNotReadable(let path):
                return "Cannot read directory at \(path). Check permissions."
            case .discoveryFailed(let error):
                return
                "Failed to discover repositories: \(error.localizedDescription)"
            }
        }
    }
    
    static let shared = RepositoryManager(gitService: GitCommandService.shared)
    
    private let fileManager: FileManagerProtocol
    private let gitService: GitCommandServiceProtocol
    private let settings = Settings.shared
    
    var defaultRepositoryDirectory: URL {
        return settings.projectsDirectory
    }
    
    init(
        fileManager: FileManagerProtocol = FileManager.default,
        gitService: GitCommandServiceProtocol
    ) {
        self.fileManager = fileManager
        self.gitService = gitService
    }
    
    func discoverRepositories(inDirectory directory: URL? = nil) async throws
    -> [GitRepository]
    {
        let directoryURL = directory ?? defaultRepositoryDirectory
        let path = directoryURL.path
        
        guard fileManager.fileExists(atPath: path) else {
            throw RepositoryError.directoryNotFound(path)
        }
        
        guard fileManager.isReadableFile(atPath: path) else {
            throw RepositoryError.directoryNotReadable(path)
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            var repositories: [GitRepository] = []
            
            for dirName in contents {
                let dirPath = directoryURL.appendingPathComponent(dirName)
                let gitDirPath = dirPath.appendingPathComponent(".git").path
                
                if fileManager.fileExists(atPath: gitDirPath) {
                    let repo = GitRepository(name: dirName, path: dirPath.path)
                    let isMainBranch = await checkMainBranchType(for: repo)
                    let repoWithMainType = GitRepository(
                        id: repo.id,
                        name: repo.name,
                        path: repo.path,
                        isMainBranchMain: isMainBranch
                    )
                    repositories.append(repoWithMainType)
                }
            }
            
            return repositories.sorted { $0.name < $1.name }
        } catch {
            throw RepositoryError.discoveryFailed(error)
        }
    }
    
    func checkMainBranchType(for repository: GitRepository) async -> Bool {
        return await gitService.checkBranchExists(
            name: "main", at: repository.path)
    }
    
    func openInTerminal(repository: GitRepository) {
        settings.openInTerminal(path: repository.path)
    }
}

protocol FileManagerProtocol {
    var homeDirectoryForCurrentUser: URL { get }
    func fileExists(atPath path: String) -> Bool
    func isReadableFile(atPath path: String) -> Bool
    func contentsOfDirectory(atPath path: String) throws -> [String]
}

extension FileManager: FileManagerProtocol {
    var homeDirectoryForCurrentUser: URL {
        return URL(fileURLWithPath: NSHomeDirectory())
    }
}
