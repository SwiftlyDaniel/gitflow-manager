import SwiftUI

struct BranchCreationView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showError: Bool = false
    
    var body: some View {
        VStack {
            Form {
                RepositorySelectionSection(viewModel: viewModel)
                BranchTypeSection(viewModel: viewModel)
                BranchDetailsSection(viewModel: viewModel)
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                Button("Create Branch") {
                    Task {
                        await viewModel.createBranch()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(
                    viewModel.selectedRepository == nil
                    || viewModel.branchType == nil
                    || (viewModel.issueNumber.isEmpty && viewModel.branchName.isEmpty)
                )
                .padding()
            }
        }
        .frame(minWidth: 400)
        .onAppear {
            Task {
                await viewModel.loadRepositories()
            }
        }
        .onChange(of: viewModel.selectedRepository) {
            viewModel.updateBranchSummary()
        }
        .onChange(of: viewModel.branchType) {
            viewModel.updateBranchSummary()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { show in
                if !show {
                    viewModel.clearError()
                }
            }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}
