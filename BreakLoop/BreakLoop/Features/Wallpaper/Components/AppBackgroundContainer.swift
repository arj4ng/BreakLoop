import SwiftUI

struct AppBackgroundContainer<Content: View>: View {
    @ObservedObject var wallpaperViewModel: WallpaperViewModel
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    wallpaperBackground(in: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()

                    content

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
        }
    }

    @ViewBuilder
    private func wallpaperBackground(in size: CGSize) -> some View {
        let settings = wallpaperViewModel.settings
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
                        .clipped()
                default:
                    AppColors.background
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
            AppColors.background
                .frame(width: size.width, height: size.height)
        }
    }

    private func resolvedImageURL(from settings: WallpaperSettings) -> URL? {
        if let path = settings.cachedLocalPath {
            return URL(filePath: path)
        }
        return settings.sourceURL
    }
}
