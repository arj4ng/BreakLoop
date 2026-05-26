import SwiftUI
import PhotosUI
import UIKit

struct WallpaperSettingsView: View {
    @ObservedObject var viewModel: WallpaperViewModel

    @State private var showsSourceDialog = false
    @State private var showsLibraryPicker = false
    @State private var showsCameraPicker = false
    @State private var showsPexelsPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editorDraft: WallpaperEditorDraft?
    @State private var localErrorMessage: String?
    @State private var isPreparingEditor = false

    var body: some View {
        List {
            Section("Current Wallpaper") {
                previewCard

                HStack {
                    Text("Status")
                    Spacer()
                    Text(viewModel.statusText)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if let photographer = viewModel.settings.photographerName,
                   let photographerURL = viewModel.settings.photographerURL {
                    Link("Photo by \(photographer) on Pexels", destination: photographerURL)
                        .font(.footnote)
                }
            }

            Section {
                Button(viewModel.settings.isEnabled ? "Change Wallpaper" : "Set Wallpaper") {
                    showsSourceDialog = true
                }

                if viewModel.settings.isEnabled {
                    Button("Remove Wallpaper", role: .destructive) {
                        viewModel.removeWallpaper()
                    }
                }
            }
        }
        .navigationTitle("Wallpaper")
        .confirmationDialog("Choose Wallpaper Source", isPresented: $showsSourceDialog, titleVisibility: .visible) {
            Button("Choose from Library") { showsLibraryPicker = true }
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showsCameraPicker = true
                } else {
                    localErrorMessage = "Camera not available on this device"
                }
            }
            Button("Choose from Pexels") { showsPexelsPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showsLibraryPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showsCameraPicker) {
            CameraImagePicker(
                onImagePicked: { image in
                    showsCameraPicker = false
                    guard let data = image.jpegData(compressionQuality: 0.9) else {
                        localErrorMessage = "Could not read captured photo"
                        return
                    }
                    prepareLocalDraft(data: data, source: .camera)
                },
                onCancel: {
                    showsCameraPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showsPexelsPicker) {
            PexelsWallpaperPickerView(viewModel: viewModel) { item in
                Task {
                    isPreparingEditor = true
                    let draft = viewModel.makeDraftFromPexels(item)
                    let prepared = await viewModel.prepareDraftForEditor(draft)
                    editorDraft = prepared
                    isPreparingEditor = false
                }
            }
        }
        .fullScreenCover(item: $editorDraft) { draft in
            WallpaperEditorView(
                draft: draft,
                isSaving: viewModel.isSaving,
                onCancel: {
                    editorDraft = nil
                },
                onSave: { outputDraft in
                    Task {
                        await viewModel.applyDraft(outputDraft)
                        if viewModel.errorMessage == nil {
                            editorDraft = nil
                        }
                    }
                }
            )
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                do {
                    guard let data = try await newValue.loadTransferable(type: Data.self) else {
                        localErrorMessage = "Could not read selected photo"
                        selectedPhotoItem = nil
                        return
                    }
                    await MainActor.run {
                        prepareLocalDraft(data: data, source: .library)
                        selectedPhotoItem = nil
                    }
                } catch {
                    await MainActor.run {
                        localErrorMessage = error.localizedDescription
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        .alert("Wallpaper", isPresented: Binding(get: { localErrorMessage != nil }, set: { if !$0 { localErrorMessage = nil } })) {
            Button("OK", role: .cancel) { localErrorMessage = nil }
        } message: {
            Text(localErrorMessage ?? "Unknown error")
        }
        .overlay {
            if isPreparingEditor {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView("Preparing image")
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .alert("Wallpaper", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.clearError() } })) {
            Button("OK", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var previewCard: some View {
        let displayURL: URL? = {
            if let path = viewModel.settings.cachedLocalPath {
                if FileManager.default.fileExists(atPath: path) {
                    return URL(filePath: path)
                }
            }
            return viewModel.settings.sourceURL
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)

            if viewModel.settings.isEnabled, let displayURL {
                AsyncImage(url: displayURL) { phase in
                    switch phase {
                    case .success(let image):
                        let previewSize = CGSize(width: 320, height: 150)
                        let transform = WallpaperTransform.resolve(
                            imagePixelSize: CGSize(width: viewModel.settings.imagePixelWidth, height: viewModel.settings.imagePixelHeight),
                            canvasSize: previewSize,
                            zoom: CGFloat(viewModel.settings.zoomScale),
                            panXNorm: CGFloat(viewModel.settings.panXNorm),
                            panYNorm: CGFloat(viewModel.settings.panYNorm)
                        )

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(CGFloat(viewModel.settings.zoomScale))
                            .offset(x: transform.offsetX, y: transform.offsetY)
                            .blur(radius: viewModel.settings.blurRadius)
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(Color.black.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("No wallpaper set")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func prepareLocalDraft(data: Data, source: WallpaperSourceType) {
        do {
            editorDraft = try viewModel.makeDraftFromLocalImageData(data, sourceType: source)
        } catch {
            localErrorMessage = error.localizedDescription
        }
    }
}
