import Foundation

protocol BranchManagerProtocol {
    func prepareRepository(_ repository: GitRepository) async throws
    func createBranch(
        inRepository repository: GitRepository,
        type: BranchType,
        issueNumber: String,
        name: String
    ) async throws -> String
}

enum BranchType: String {
    case feature = "f"
    case hotfix = "h"
    
    var prefix: String {
        rawValue == "f" ? "feature" : "hotfix"
    }
    
    var baseBranch: String {
        self == .feature ? "develop" : "main"
    }
}

class BranchManager: BranchManagerProtocol {
    private let gitService: GitCommandServiceProtocol
    private let repoManager: RepositoryManagerProtocol
    
    init(
        gitService: GitCommandServiceProtocol = GitCommandService.shared,
        repoManager: RepositoryManagerProtocol = RepositoryManager.shared
    ) {
        self.gitService = gitService
        self.repoManager = repoManager
    }
    
    func prepareRepository(_ repository: GitRepository) async throws {
        do {
            _ = try await gitService.checkoutAndPull(branch: "develop", at: repository.path)
        } catch GitCommandService.GitError.branchNotFound {
            throw GitCommandService.GitError.branchNotFound("This repository doesn't have a 'develop' branch. Feature branches require a develop branch to be present.")
        } catch GitCommandService.GitError.checkoutFailed(let message) {
            throw GitCommandService.GitError.checkoutFailed("Failed to checkout develop branch: \(message)")
        } catch GitCommandService.GitError.pullFailed(let message) {
            throw GitCommandService.GitError.pullFailed("Failed to update develop branch: \(message)")
        }
        
        let mainBranch = await repoManager.checkMainBranchType(for: repository) ? "main" : "master"
        do {
            _ = try await gitService.checkoutAndPull(branch: mainBranch, at: repository.path)
        } catch GitCommandService.GitError.branchNotFound {
            throw GitCommandService.GitError.branchNotFound("This repository doesn't have a '\(mainBranch)' branch.")
        } catch GitCommandService.GitError.checkoutFailed(let message) {
            throw GitCommandService.GitError.checkoutFailed("Failed to checkout \(mainBranch) branch: \(message)")
        } catch GitCommandService.GitError.pullFailed(let message) {
            throw GitCommandService.GitError.pullFailed("Failed to update \(mainBranch) branch: \(message)")
        }
    }
    
    func createBranch(
        inRepository repository: GitRepository,
        type: BranchType,
        issueNumber: String,
        name: String
    ) async throws -> String {
        let baseBranch = type == .feature ? "develop" : 
        (await repoManager.checkMainBranchType(for: repository) ? "main" : "master")
        
        let branchName = formatBranchName(type: type, issueNumber: issueNumber, name: name)
        
        _ = try await gitService.createBranch(
            name: branchName,
            baseBranch: baseBranch,
            at: repository.path
        )
        
        return branchName
    }
    
    private func formatBranchName(type: BranchType, issueNumber: String, name: String) -> String {
        let components = [issueNumber, name]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        
        let suffix = components.joined(separator: "-")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_-]", with: "", options: .regularExpression)
        
        return "\(type.prefix)/\(suffix)"
    }
}
