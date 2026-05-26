import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import UIKit

protocol WallpaperStateStoreProtocol {
    func load() -> WallpaperSettings
    func save(_ settings: WallpaperSettings)
    func reset()
}

protocol WallpaperSearchServiceProtocol {
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> [WallpaperSearchItem]
    func curatedPhotos(page: Int, perPage: Int) async throws -> [WallpaperSearchItem]
}

struct CachedWallpaperImage {
    let localPath: String
    let pixelWidth: Double
    let pixelHeight: Double
}

protocol WallpaperImageLoaderProtocol {
    func cacheImage(fromRemoteURL url: URL, sourceId: String, maxPixelSize: CGFloat) async throws -> CachedWallpaperImage
    func cacheImage(fromData data: Data, sourceId: String, maxPixelSize: CGFloat) throws -> CachedWallpaperImage
}

struct WallpaperReadabilityProfile {
    let topScrimOpacity: Double
    let midScrimOpacity: Double
    let bottomScrimOpacity: Double
    let globalTint: WallpaperReadabilityTintMode
    let surfaceBoost: Double

    static let fallback = WallpaperReadabilityProfile(
        topScrimOpacity: 0.12,
        midScrimOpacity: 0.08,
        bottomScrimOpacity: 0.2,
        globalTint: .dark,
        surfaceBoost: 0.18
    )
}

protocol WallpaperReadabilityAnalyzerProtocol {
    func analyze(localFilePath: String) -> WallpaperReadabilityProfile?
}

final class WallpaperUserDefaultsStore: WallpaperStateStoreProtocol {
    private let defaults: UserDefaults
    private let key = "breakloop.wallpaper.settings"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> WallpaperSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(WallpaperSettings.self, from: data) else { return .default }
        return settings.clamped
    }

    func save(_ settings: WallpaperSettings) {
        guard let data = try? JSONEncoder().encode(settings.clamped) else { return }
        defaults.set(data, forKey: key)
    }

    func reset() { defaults.removeObject(forKey: key) }
}

actor WallpaperSecurityGuard {
    private var lastRequestTime: Date?
    private var sessionPageBudgetUsed = 0

    let minimumQueryLength = 3
    let minimumRequestInterval: TimeInterval = 1.0
    let maxPerPage = 40
    let maxPagesPerSession = 20

    func validateSearchQuery(_ query: String, requestedPerPage: Int) throws -> Int {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumQueryLength else { throw WallpaperServiceError.queryTooShort(minimum: minimumQueryLength) }
        return try validatePageBudget(requestedPerPage: requestedPerPage)
    }

    func validateCuratedRequest(requestedPerPage: Int) throws -> Int {
        try validatePageBudget(requestedPerPage: requestedPerPage)
    }

    private func validatePageBudget(requestedPerPage: Int) throws -> Int {
        guard sessionPageBudgetUsed < maxPagesPerSession else { throw WallpaperServiceError.pageBudgetExceeded }
        return min(max(requestedPerPage, 1), maxPerPage)
    }

    func waitIfNeeded() async {
        guard let lastRequestTime else {
            self.lastRequestTime = Date()
            return
        }
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minimumRequestInterval {
            try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - elapsed) * 1_000_000_000))
        }
        self.lastRequestTime = Date()
    }

    func registerPageRequest() { sessionPageBudgetUsed += 1 }
}

enum WallpaperServiceError: LocalizedError {
    case queryTooShort(minimum: Int)
    case pageBudgetExceeded
    case invalidRequest
    case missingAPIKey
    case decodeFailure
    case downsampleFailure

    var errorDescription: String? {
        switch self {
        case .queryTooShort(let minimum): return "Search needs at least \(minimum) characters"
        case .pageBudgetExceeded: return "Search limit reached for this session"
        case .invalidRequest: return "Invalid request"
        case .missingAPIKey: return "Missing Pexels API key"
        case .decodeFailure: return "Could not decode image"
        case .downsampleFailure: return "Could not optimize selected image"
        }
    }
}

final class PexelsWallpaperSearchService: WallpaperSearchServiceProtocol {
    private struct PexelsListResponse: Decodable {
        struct PexelsPhoto: Decodable {
            struct Source: Decodable {
                let original: URL?
                let large2x: URL?
                let large: URL?
                let medium: URL?
            }

            let id: Int
            let url: URL
            let photographer: String
            let photographer_url: URL
            let src: Source

            var mappedItem: WallpaperSearchItem? {
                let full = src.large2x ?? src.large ?? src.medium ?? src.original
                let preview = src.medium ?? src.large ?? src.large2x ?? src.original
                guard let full, let preview else { return nil }
                return WallpaperSearchItem(
                    id: String(id),
                    previewURL: preview,
                    fullURL: full,
                    photographerName: photographer,
                    photographerURL: photographer_url,
                    pexelsPhotoURL: url
                )
            }
        }

        let photos: [PexelsPhoto]
    }

    private let searchURL = URL(string: "https://api.pexels.com/v1/search")!
    private let curatedURL = URL(string: "https://api.pexels.com/v1/curated")!
    private let session: URLSession
    private let guardPolicy: WallpaperSecurityGuard
    private let apiKeyProvider: () -> String?

    init(
        session: URLSession = .shared,
        guardPolicy: WallpaperSecurityGuard = WallpaperSecurityGuard(),
        apiKeyProvider: @escaping () -> String? = {
            if let env = ProcessInfo.processInfo.environment["PEXELS_API_KEY"], !env.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return env
            }
            if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
               let key = dict["PEXELS_API_KEY"] as? String,
               !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return key
            }
            return nil
        }
    ) {
        self.session = session
        self.guardPolicy = guardPolicy
        self.apiKeyProvider = apiKeyProvider
    }

    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> [WallpaperSearchItem] {
        let cappedPerPage = try await guardPolicy.validateSearchQuery(query, requestedPerPage: perPage)
        return try await requestList(
            baseURL: searchURL,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(max(1, page))),
                URLQueryItem(name: "per_page", value: String(cappedPerPage)),
                URLQueryItem(name: "orientation", value: "portrait")
            ]
        )
    }

    func curatedPhotos(page: Int, perPage: Int) async throws -> [WallpaperSearchItem] {
        let cappedPerPage = try await guardPolicy.validateCuratedRequest(requestedPerPage: perPage)
        return try await requestList(
            baseURL: curatedURL,
            queryItems: [
                URLQueryItem(name: "page", value: String(max(1, page))),
                URLQueryItem(name: "per_page", value: String(cappedPerPage))
            ]
        )
    }

    private func requestList(baseURL: URL, queryItems: [URLQueryItem]) async throws -> [WallpaperSearchItem] {
        let apiKey = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let apiKey, !apiKey.isEmpty else { throw WallpaperServiceError.missingAPIKey }

        await guardPolicy.waitIfNeeded()

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else { throw WallpaperServiceError.invalidRequest }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let (data, _) = try await session.data(for: request)
        let decoded = try JSONDecoder().decode(PexelsListResponse.self, from: data)
        await guardPolicy.registerPageRequest()

        return decoded.photos.compactMap { $0.mappedItem }
    }
}

final class WallpaperImageLoader: WallpaperImageLoaderProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func cacheImage(fromRemoteURL url: URL, sourceId: String, maxPixelSize: CGFloat) async throws -> CachedWallpaperImage {
        let (data, _) = try await session.data(from: url)
        return try cacheImage(fromData: data, sourceId: sourceId, maxPixelSize: maxPixelSize)
    }

    func cacheImage(fromData data: Data, sourceId: String, maxPixelSize: CGFloat) throws -> CachedWallpaperImage {
        let fm = FileManager.default
        guard let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw WallpaperServiceError.invalidRequest
        }

        let dir = base.appendingPathComponent("Wallpapers", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let downsampled = try downsampledJPEG(from: data, maxPixelSize: maxPixelSize)
        let fileURL = dir.appendingPathComponent("\(sourceId).jpg")
        try downsampled.data.write(to: fileURL, options: .atomic)

        return CachedWallpaperImage(
            localPath: fileURL.path,
            pixelWidth: Double(downsampled.pixelSize.width),
            pixelHeight: Double(downsampled.pixelSize.height)
        )
    }

    private func downsampledJPEG(from data: Data, maxPixelSize: CGFloat) throws -> (data: Data, pixelSize: CGSize) {
        let options: CFDictionary = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            throw WallpaperServiceError.decodeFailure
        }

        let downsampleOptions: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            throw WallpaperServiceError.downsampleFailure
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw WallpaperServiceError.downsampleFailure
        }

        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.86] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw WallpaperServiceError.downsampleFailure
        }

        return (mutableData as Data, CGSize(width: image.width, height: image.height))
    }
}

final class WallpaperReadabilityAnalyzer: WallpaperReadabilityAnalyzerProtocol {
    func analyze(localFilePath: String) -> WallpaperReadabilityProfile? {
        guard let image = UIImage(contentsOfFile: localFilePath)?.cgImage else { return nil }
        guard let sample = sampleLuminance(cgImage: image) else { return nil }

        let average = sample.global
        let range = max(sample.max - sample.min, 0)
        let isBright = average > 0.62
        let baseTop = isBright ? 0.18 : 0.12
        let baseMid = isBright ? 0.12 : 0.08
        let baseBottom = isBright ? 0.28 : 0.2
        let contrastPenalty = max(0, 0.22 - range) * 0.9
        let surfaceBoost = min(max(0.12 + contrastPenalty + (isBright ? 0.1 : 0), 0.12), 0.45)

        return WallpaperReadabilityProfile(
            topScrimOpacity: min(baseTop + contrastPenalty * 0.8, 0.42),
            midScrimOpacity: min(baseMid + contrastPenalty * 0.7, 0.34),
            bottomScrimOpacity: min(baseBottom + contrastPenalty, 0.56),
            globalTint: isBright ? .light : .dark,
            surfaceBoost: surfaceBoost
        )
    }

    private func sampleLuminance(cgImage: CGImage) -> (global: Double, min: Double, max: Double)? {
        let width = 24
        let height = 24
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .low
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var values: [Double] = []
        values.reserveCapacity(width * height)
        for i in stride(from: 0, to: data.count, by: 4) {
            let r = Double(data[i]) / 255
            let g = Double(data[i + 1]) / 255
            let b = Double(data[i + 2]) / 255
            let l = 0.2126 * r + 0.7152 * g + 0.0722 * b
            values.append(l)
        }
        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / Double(values.count)
        return (avg, values.min() ?? avg, values.max() ?? avg)
    }
}
