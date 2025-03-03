import SwiftUI

struct RepositorySelectionSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Section("Repository") {
            if viewModel.repositories.isEmpty {
                HStack {
                    Text("No git repositories found")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await viewModel.loadRepositories()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                HStack {
                    Menu {
                        ForEach(viewModel.repositories) { repo in
                            Button(repo.name) {
                                viewModel.selectedRepository = repo
                            }
                        }
                    } label: {
                        Text(viewModel.selectedRepository?.name ?? "Select a repository")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .menuStyle(.borderedButton)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        Task {
                            await viewModel.loadRepositories()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}