import Foundation

enum WallpaperSourceType: String, Codable {
    case library
    case camera
    case pexels
}

struct WallpaperSettings: Codable, Equatable {
    var isEnabled: Bool
    var sourceType: WallpaperSourceType?
    var sourceId: String?
    var sourceURL: URL?
    var cachedLocalPath: String?
    var blurRadius: Double
    var zoomScale: Double
    var panXNorm: Double
    var panYNorm: Double
    var imagePixelWidth: Double
    var imagePixelHeight: Double
    var photographerName: String?
    var photographerURL: URL?
    var pexelsPhotoURL: URL?

    static let `default` = WallpaperSettings(
        isEnabled: false,
        sourceType: nil,
        sourceId: nil,
        sourceURL: nil,
        cachedLocalPath: nil,
        blurRadius: 10,
        zoomScale: 1,
        panXNorm: 0,
        panYNorm: 0,
        imagePixelWidth: 0,
        imagePixelHeight: 0,
        photographerName: nil,
        photographerURL: nil,
        pexelsPhotoURL: nil
    )

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case sourceType
        case sourceId
        case sourceURL
        case previewURL
        case fullURL
        case cachedLocalPath
        case blurRadius
        case zoomScale
        case panXNorm
        case panYNorm
        case imagePixelWidth
        case imagePixelHeight
        case offsetX
        case offsetY
        case alignmentX
        case alignmentY
        case photographerName
        case photographerURL
        case pexelsPhotoURL
    }

    init(
        isEnabled: Bool,
        sourceType: WallpaperSourceType?,
        sourceId: String?,
        sourceURL: URL?,
        cachedLocalPath: String?,
        blurRadius: Double,
        zoomScale: Double,
        panXNorm: Double,
        panYNorm: Double,
        imagePixelWidth: Double,
        imagePixelHeight: Double,
        photographerName: String?,
        photographerURL: URL?,
        pexelsPhotoURL: URL?
    ) {
        self.isEnabled = isEnabled
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.sourceURL = sourceURL
        self.cachedLocalPath = cachedLocalPath
        self.blurRadius = blurRadius
        self.zoomScale = zoomScale
        self.panXNorm = panXNorm
        self.panYNorm = panYNorm
        self.imagePixelWidth = imagePixelWidth
        self.imagePixelHeight = imagePixelHeight
        self.photographerName = photographerName
        self.photographerURL = photographerURL
        self.pexelsPhotoURL = pexelsPhotoURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        let sourceType = try container.decodeIfPresent(WallpaperSourceType.self, forKey: .sourceType)
        let sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId)
        let sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
            ?? container.decodeIfPresent(URL.self, forKey: .fullURL)
            ?? container.decodeIfPresent(URL.self, forKey: .previewURL)
        let cachedLocalPath = try container.decodeIfPresent(String.self, forKey: .cachedLocalPath)
        let blurRadius = try container.decodeIfPresent(Double.self, forKey: .blurRadius) ?? 10
        let zoomScale = try container.decodeIfPresent(Double.self, forKey: .zoomScale) ?? 1

        // Migration strategy: if normalized pan missing, center old wallpapers.
        let panXNorm = try container.decodeIfPresent(Double.self, forKey: .panXNorm) ?? 0
        let panYNorm = try container.decodeIfPresent(Double.self, forKey: .panYNorm) ?? 0
        let imagePixelWidth = try container.decodeIfPresent(Double.self, forKey: .imagePixelWidth) ?? 0
        let imagePixelHeight = try container.decodeIfPresent(Double.self, forKey: .imagePixelHeight) ?? 0

        let photographerName = try container.decodeIfPresent(String.self, forKey: .photographerName)
        let photographerURL = try container.decodeIfPresent(URL.self, forKey: .photographerURL)
        let pexelsPhotoURL = try container.decodeIfPresent(URL.self, forKey: .pexelsPhotoURL)

        self.init(
            isEnabled: isEnabled,
            sourceType: sourceType,
            sourceId: sourceId,
            sourceURL: sourceURL,
            cachedLocalPath: cachedLocalPath,
            blurRadius: blurRadius,
            zoomScale: zoomScale,
            panXNorm: panXNorm,
            panYNorm: panYNorm,
            imagePixelWidth: imagePixelWidth,
            imagePixelHeight: imagePixelHeight,
            photographerName: photographerName,
            photographerURL: photographerURL,
            pexelsPhotoURL: pexelsPhotoURL
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(sourceType, forKey: .sourceType)
        try container.encodeIfPresent(sourceId, forKey: .sourceId)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(cachedLocalPath, forKey: .cachedLocalPath)
        try container.encode(blurRadius, forKey: .blurRadius)
        try container.encode(zoomScale, forKey: .zoomScale)
        try container.encode(panXNorm, forKey: .panXNorm)
        try container.encode(panYNorm, forKey: .panYNorm)
        try container.encode(imagePixelWidth, forKey: .imagePixelWidth)
        try container.encode(imagePixelHeight, forKey: .imagePixelHeight)
        try container.encodeIfPresent(photographerName, forKey: .photographerName)
        try container.encodeIfPresent(photographerURL, forKey: .photographerURL)
        try container.encodeIfPresent(pexelsPhotoURL, forKey: .pexelsPhotoURL)
    }

    var clamped: WallpaperSettings {
        var copy = self
        copy.blurRadius = min(max(copy.blurRadius, 0), 30)
        copy.zoomScale = min(max(copy.zoomScale, 1), 4)
        copy.panXNorm = min(max(copy.panXNorm, -1), 1)
        copy.panYNorm = min(max(copy.panYNorm, -1), 1)
        copy.imagePixelWidth = max(copy.imagePixelWidth, 0)
        copy.imagePixelHeight = max(copy.imagePixelHeight, 0)
        return copy
    }
}

struct WallpaperSearchItem: Identifiable, Codable, Equatable {
    let id: String
    let previewURL: URL
    let fullURL: URL
    let photographerName: String?
    let photographerURL: URL?
    let pexelsPhotoURL: URL?
}

struct WallpaperEditorDraft: Identifiable, Equatable {
    let id: UUID
    let sourceType: WallpaperSourceType
    let sourceId: String
    var previewURL: URL?
    var remoteURL: URL?
    var cachedLocalPath: String?
    var blurRadius: Double
    var zoomScale: Double
    var panXNorm: Double
    var panYNorm: Double
    var imagePixelWidth: Double
    var imagePixelHeight: Double
    var photographerName: String?
    var photographerURL: URL?
    var pexelsPhotoURL: URL?

    var displayURL: URL? {
        if let cachedLocalPath {
            return URL(filePath: cachedLocalPath)
        }
        return previewURL ?? remoteURL
    }
}
