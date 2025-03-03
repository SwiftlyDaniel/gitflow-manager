import Foundation

protocol GitCommandServiceProtocol {
    func execute(_ command: String, at path: String) async throws -> String
    func checkBranchExists(name: String, at path: String) async -> Bool
    func checkoutAndPull(branch: String, at path: String) async throws -> (checkoutResult: String, pullResult: String)
    func createBranch(name: String, baseBranch: String, at path: String) async throws -> String
}

class GitCommandService: GitCommandServiceProtocol {
    enum GitError: LocalizedError {
        case branchNotFound(String)
        case checkoutFailed(String)
        case pullFailed(String)
        case createBranchFailed(String)
        case invalidRepository(String)
        case executionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .branchNotFound(let branch):
                return "Branch '\(branch)' not found"
            case .checkoutFailed(let message):
                return "Failed to checkout: \(message)"
            case .pullFailed(let message):
                return "Failed to pull: \(message)"
            case .createBranchFailed(let message):
                return "Failed to create branch: \(message)"
            case .invalidRepository(let path):
                return "Invalid git repository at \(path)"
            case .executionFailed(let message):
                return "Git command failed: \(message)"
            }
        }
    }
    
    static let shared = GitCommandService()
    private init() {}
    
    func execute(_ command: String, at path: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.launchPath = "/usr/bin/git"
            task.arguments = command.split(separator: " ").map(String.init)
            task.currentDirectoryPath = path
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                
                if task.terminationStatus != 0 {
                    let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    let error: GitError
                    if errorString.contains("did not match any file(s) known to git") {
                        error = .branchNotFound(command)
                    } else if command.starts(with: "checkout") {
                        if errorString.contains("Please commit your changes or stash them") {
                            error = .checkoutFailed("You have uncommitted changes. Please commit or stash them before switching branches.")
                        } else if errorString.contains("untracked working tree files") {
                            error = .checkoutFailed("You have untracked files that would be overwritten. Please commit, stash, or remove them.")
                        } else {
                            error = .checkoutFailed(errorString)
                        }
                    } else if command == "pull" {
                        if errorString.contains("You have unstaged changes") || errorString.contains("Your local changes to the following files would be overwritten") {
                            error = .pullFailed("You have local changes that would be overwritten by pull. Please commit or stash them.")
                        } else {
                            error = .pullFailed(errorString)
                        }
                    } else if command.starts(with: "checkout -b") {
                        if errorString.contains("already exists") {
                            error = .createBranchFailed("A branch with this name already exists.")
                        } else {
                            error = .createBranchFailed(errorString)
                        }
                    } else {
                        error = .executionFailed(errorString.isEmpty ? "Unknown error" : errorString)
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                continuation.resume(throwing: GitError.executionFailed(error.localizedDescription))
            }
        }
    }
    
    func checkBranchExists(name: String, at path: String) async -> Bool {
        do {
            _ = try await execute("show-ref --verify --quiet refs/heads/\(name)", at: path)
            return true
        } catch {
            return false
        }
    }
    
    func checkoutAndPull(branch: String, at path: String) async throws -> (checkoutResult: String, pullResult: String) {
        let checkoutResult = try await execute("checkout \(branch)", at: path)
        let pullResult = try await execute("pull", at: path)
        return (checkoutResult, pullResult)
    }
    
    func createBranch(name: String, baseBranch: String, at path: String) async throws -> String {
        return try await execute("checkout -b \(name) \(baseBranch)", at: path)
    }
}
