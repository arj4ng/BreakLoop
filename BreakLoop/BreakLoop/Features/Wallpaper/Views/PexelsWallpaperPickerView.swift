import SwiftUI

struct PexelsWallpaperPickerView: View {
    @ObservedObject var viewModel: WallpaperViewModel
    let onSelected: (WallpaperSearchItem) -> Void

    @Environment(\.dismiss) private var dismiss

    private var items: [WallpaperSearchItem] {
        let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? viewModel.curatedItems : viewModel.searchItems
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onSelected(item)
                            dismiss()
                        } label: {
                            AsyncImage(url: item.previewURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    AppColors.surface
                                }
                            }
                            .frame(height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .task {
                            let trimmed = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                await viewModel.loadMoreCuratedIfNeeded(current: item)
                            } else {
                                await viewModel.loadMoreSearchIfNeeded(current: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                attributionFooter
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                if viewModel.isLoadingCurated || viewModel.isSearching {
                    ProgressView()
                        .padding(.bottom, 20)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Pexels")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .searchable(text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateQuery($0) }
            ), placement: .navigationBarDrawer(displayMode: .always), prompt: "Search photos")
            .task {
                await viewModel.loadCuratedIfNeeded()
            }
            .onDisappear {
                viewModel.cancelPendingSearch()
            }
            .onSubmit(of: .search) {
                Task { await viewModel.search(reset: true) }
            }
            .alert("Wallpaper", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })) {
                Button("OK", role: .cancel) { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private var attributionFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link("Photos provided by Pexels", destination: URL(string: "https://www.pexels.com")!)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.accent)

            Text("Please credit photographers when possible.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
