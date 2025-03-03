import SwiftUI

struct BranchTypeSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Section("Branch Type") {
            Picker("Branch Type", selection: $viewModel.branchType) {
                Text("Feature").tag(Optional(BranchType.feature))
                Text("Hotfix").tag(Optional(BranchType.hotfix))
            }
            .pickerStyle(.radioGroup)
        }
    }
}