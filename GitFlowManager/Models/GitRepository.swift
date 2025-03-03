import Foundation

struct GitRepository: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    private let _isMainBranchMain: Bool?
    
    var isMainBranchMain: Bool {
        _isMainBranchMain ?? false
    }
    
    var mainBranchName: String {
        isMainBranchMain ? "main" : "master"
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        isMainBranchMain: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self._isMainBranchMain = isMainBranchMain
    }
    
    var fullPath: URL {
        URL(fileURLWithPath: path)
    }
    
    mutating func setMainBranchType(_ isMain: Bool) {
        self = GitRepository(id: id, name: name, path: path, isMainBranchMain: isMain)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GitRepository, rhs: GitRepository) -> Bool {
        lhs.id == rhs.id
    }
}
