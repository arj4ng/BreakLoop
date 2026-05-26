import Foundation
import Combine
import CoreGraphics

@MainActor
final class WallpaperViewModel: ObservableObject {
    @Published private(set) var settings: WallpaperSettings
    @Published private(set) var curatedItems: [WallpaperSearchItem] = []
    @Published private(set) var searchItems: [WallpaperSearchItem] = []
    @Published var query: String = ""
    @Published private(set) var isLoadingCurated = false
    @Published private(set) var isSearching = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let store: WallpaperStateStoreProtocol
    private let searchService: WallpaperSearchServiceProtocol
    private let imageLoader: WallpaperImageLoaderProtocol

    private var curatedPage = 1
    private var searchPage = 1
    private var canLoadMoreCurated = true
    private var canLoadMoreSearch = true
    private var searchTask: Task<Void, Never>?

    init(
        store: WallpaperStateStoreProtocol,
        searchService: WallpaperSearchServiceProtocol,
        imageLoader: WallpaperImageLoaderProtocol
    ) {
        self.store = store
        self.searchService = searchService
        self.imageLoader = imageLoader
        self.settings = store.load()
        repairPersistedWallpaperIfNeeded()
    }

    convenience init() {
        self.init(
            store: WallpaperUserDefaultsStore(),
            searchService: PexelsWallpaperSearchService(),
            imageLoader: WallpaperImageLoader()
        )
    }

    deinit {
        searchTask?.cancel()
    }

    var hasWallpaper: Bool {
        guard settings.isEnabled else { return false }
        if let path = settings.cachedLocalPath {
            return FileManager.default.fileExists(atPath: path)
        }
        return settings.sourceURL != nil
    }

    var statusText: String {
        if settings.isEnabled {
            if let sourceType = settings.sourceType {
                return "Enabled • \(sourceType.rawValue.capitalized)"
            }
            return "Enabled"
        }
        return "Off"
    }

    func clearError() {
        errorMessage = nil
    }

    func cancelPendingSearch() {
        searchTask?.cancel()
    }

    func removeWallpaper() {
        settings = .default
        persist()
    }

    func loadCuratedIfNeeded() async {
        guard curatedItems.isEmpty, !isLoadingCurated else { return }
        await loadMoreCurated()
    }

    func loadMoreCurated() async {
        guard !isLoadingCurated, canLoadMoreCurated else { return }
        isLoadingCurated = true
        errorMessage = nil
        defer { isLoadingCurated = false }

        do {
            let items = try await searchService.curatedPhotos(page: curatedPage, perPage: 24)
            curatedItems.append(contentsOf: items)
            canLoadMoreCurated = !items.isEmpty
            curatedPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateQuery(_ value: String) {
        query = value
        searchTask?.cancel()

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchItems = []
            searchPage = 1
            canLoadMoreSearch = true
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard let self, !Task.isCancelled else { return }
            await self.search(reset: true)
        }
    }

    func search(reset: Bool) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if isSearching || (!canLoadMoreSearch && !reset) { return }

        if reset {
            searchPage = 1
            canLoadMoreSearch = true
            searchItems = []
        }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let items = try await searchService.searchPhotos(query: trimmed, page: searchPage, perPage: 24)
            searchItems.append(contentsOf: items)
            canLoadMoreSearch = !items.isEmpty
            searchPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreSearchIfNeeded(current item: WallpaperSearchItem) async {
        guard let last = searchItems.last, last.id == item.id else { return }
        await search(reset: false)
    }

    func loadMoreCuratedIfNeeded(current item: WallpaperSearchItem) async {
        guard let last = curatedItems.last, last.id == item.id else { return }
        await loadMoreCurated()
    }

    func makeDraftFromPexels(_ item: WallpaperSearchItem) -> WallpaperEditorDraft {
        WallpaperEditorDraft(
            id: UUID(),
            sourceType: .pexels,
            sourceId: item.id,
            previewURL: item.previewURL,
            remoteURL: item.fullURL,
            cachedLocalPath: nil,
            blurRadius: settings.blurRadius,
            zoomScale: max(settings.zoomScale, 1),
            panXNorm: settings.panXNorm,
            panYNorm: settings.panYNorm,
            imagePixelWidth: settings.imagePixelWidth,
            imagePixelHeight: settings.imagePixelHeight,
            photographerName: item.photographerName,
            photographerURL: item.photographerURL,
            pexelsPhotoURL: item.pexelsPhotoURL
        )
    }

    func makeDraftFromLocalImageData(_ data: Data, sourceType: WallpaperSourceType) throws -> WallpaperEditorDraft {
        let sourceId = UUID().uuidString
        let cached = try imageLoader.cacheImage(fromData: data, sourceId: sourceId, maxPixelSize: 2200)

        return WallpaperEditorDraft(
            id: UUID(),
            sourceType: sourceType,
            sourceId: sourceId,
            previewURL: URL(filePath: cached.localPath),
            remoteURL: nil,
            cachedLocalPath: cached.localPath,
            blurRadius: settings.blurRadius,
            zoomScale: max(settings.zoomScale, 1),
            panXNorm: settings.panXNorm,
            panYNorm: settings.panYNorm,
            imagePixelWidth: cached.pixelWidth,
            imagePixelHeight: cached.pixelHeight,
            photographerName: nil,
            photographerURL: nil,
            pexelsPhotoURL: nil
        )
    }

    func prepareDraftForEditor(_ draft: WallpaperEditorDraft) async -> WallpaperEditorDraft {
        var mutable = draft
        if mutable.cachedLocalPath == nil, let remoteURL = mutable.remoteURL {
            do {
                let cached = try await imageLoader.cacheImage(fromRemoteURL: remoteURL, sourceId: mutable.sourceId, maxPixelSize: 2200)
                mutable.cachedLocalPath = cached.localPath
                mutable.imagePixelWidth = cached.pixelWidth
                mutable.imagePixelHeight = cached.pixelHeight
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        return mutable
    }

    func applyDraft(_ draft: WallpaperEditorDraft) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var mutable = draft
            if mutable.cachedLocalPath == nil, let remoteURL = mutable.remoteURL {
                let cached = try await imageLoader.cacheImage(fromRemoteURL: remoteURL, sourceId: mutable.sourceId, maxPixelSize: 2200)
                mutable.cachedLocalPath = cached.localPath
                mutable.imagePixelWidth = cached.pixelWidth
                mutable.imagePixelHeight = cached.pixelHeight
            }

            var newSettings = settings
            newSettings.isEnabled = true
            newSettings.sourceType = mutable.sourceType
            newSettings.sourceId = mutable.sourceId
            newSettings.sourceURL = mutable.remoteURL ?? mutable.previewURL
            newSettings.cachedLocalPath = mutable.cachedLocalPath
            newSettings.blurRadius = mutable.blurRadius
            newSettings.zoomScale = mutable.zoomScale
            newSettings.panXNorm = mutable.panXNorm
            newSettings.panYNorm = mutable.panYNorm
            newSettings.imagePixelWidth = mutable.imagePixelWidth
            newSettings.imagePixelHeight = mutable.imagePixelHeight
            newSettings.photographerName = mutable.photographerName
            newSettings.photographerURL = mutable.photographerURL
            newSettings.pexelsPhotoURL = mutable.pexelsPhotoURL

            settings = newSettings.clamped
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persist() {
        settings = settings.clamped
        store.save(settings)
    }

    private func repairPersistedWallpaperIfNeeded() {
        guard settings.isEnabled else { return }
        guard let cachedPath = settings.cachedLocalPath else { return }
        guard !FileManager.default.fileExists(atPath: cachedPath) else { return }
        guard let sourceURL = settings.sourceURL else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let cached = try await self.imageLoader.cacheImage(
                    fromRemoteURL: sourceURL,
                    sourceId: self.settings.sourceId ?? UUID().uuidString,
                    maxPixelSize: 2200
                )
                self.settings.cachedLocalPath = cached.localPath
                if self.settings.imagePixelWidth <= 0 || self.settings.imagePixelHeight <= 0 {
                    self.settings.imagePixelWidth = cached.pixelWidth
                    self.settings.imagePixelHeight = cached.pixelHeight
                }
                self.persist()
            } catch {
                // keep old setting; UI can still fallback to remote URL when available
            }
        }
    }
}
