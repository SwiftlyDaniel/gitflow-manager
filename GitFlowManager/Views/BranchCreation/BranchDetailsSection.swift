import SwiftUI

struct BranchDetailsSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Section("Branch Details") {
            TextField("Issue Number", text: $viewModel.issueNumber)
                .onChange(of: viewModel.issueNumber) { viewModel.updateBranchSummary() }
            
            TextField("Branch Name", text: $viewModel.branchName)
                .onChange(of: viewModel.branchName) { viewModel.updateBranchSummary() }
            
            if !viewModel.branchSummary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.branchSummary)
                        .monospaced()
                }
                .padding(.top, 4)
            }
        }
    }
}