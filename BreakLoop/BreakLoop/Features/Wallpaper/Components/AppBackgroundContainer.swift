import SwiftUI

struct AppBackgroundContainer<Content: View>: View {
    @ObservedObject var wallpaperViewModel: WallpaperViewModel
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            // Layer 1: guaranteed fallback base color
            AppColors.background
                .ignoresSafeArea()

            // Layer 2: wallpaper full-bleed, independent from content layout
            wallpaperFullBleedLayer

            // Layer 3: foreground content keeps natural safe-area behavior
            content

            // Layer 4: legibility gradient full-bleed
            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    private var wallpaperFullBleedLayer: some View {
        GeometryReader { geo in
            wallpaperBackground(in: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func wallpaperBackground(in size: CGSize) -> some View {
        let settings = wallpaperViewModel.settings

        return Group {
            if settings.isEnabled, let imageURL = resolvedImageURL(from: settings) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        let transform = WallpaperTransform.resolve(
                            imagePixelSize: CGSize(width: settings.imagePixelWidth, height: settings.imagePixelHeight),
                            canvasSize: size,
                            zoom: CGFloat(settings.zoomScale),
                            panXNorm: CGFloat(settings.panXNorm),
                            panYNorm: CGFloat(settings.panYNorm)
                        )

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                            .scaleEffect(CGFloat(settings.zoomScale))
                            .offset(x: transform.offsetX, y: transform.offsetY)
                            .blur(radius: settings.blurRadius)
                            .overlay(Color.black.opacity(0.16))

                    default:
                        AppColors.background
                            .frame(width: size.width, height: size.height)
                    }
                }
            } else {
                AppColors.background
                    .frame(width: size.width, height: size.height)
            }
        }
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func resolvedImageURL(from settings: WallpaperSettings) -> URL? {
        if let path = settings.cachedLocalPath {
            if FileManager.default.fileExists(atPath: path) {
                return URL(filePath: path)
            }
        }
        return settings.sourceURL
    }
}
