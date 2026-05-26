import CoreGraphics

struct WallpaperTransform {
    let offsetX: CGFloat
    let offsetY: CGFloat
    let maxOffsetX: CGFloat
    let maxOffsetY: CGFloat

    static func resolve(
        imagePixelSize: CGSize,
        canvasSize: CGSize,
        zoom: CGFloat,
        panXNorm: CGFloat,
        panYNorm: CGFloat
    ) -> WallpaperTransform {
        guard imagePixelSize.width > 0, imagePixelSize.height > 0, canvasSize.width > 0, canvasSize.height > 0 else {
            return WallpaperTransform(offsetX: 0, offsetY: 0, maxOffsetX: 0, maxOffsetY: 0)
        }

        let fillScale = max(canvasSize.width / imagePixelSize.width, canvasSize.height / imagePixelSize.height)
        let scaledWidth = imagePixelSize.width * fillScale * max(zoom, 1)
        let scaledHeight = imagePixelSize.height * fillScale * max(zoom, 1)

        let maxOffsetX = max((scaledWidth - canvasSize.width) * 0.5, 0)
        let maxOffsetY = max((scaledHeight - canvasSize.height) * 0.5, 0)

        let xNorm = min(max(panXNorm, -1), 1)
        let yNorm = min(max(panYNorm, -1), 1)

        let offsetX = maxOffsetX > 0 ? xNorm * maxOffsetX : 0
        let offsetY = maxOffsetY > 0 ? yNorm * maxOffsetY : 0

        return WallpaperTransform(offsetX: offsetX, offsetY: offsetY, maxOffsetX: maxOffsetX, maxOffsetY: maxOffsetY)
    }

    static func normalizedPan(offsetX: CGFloat, offsetY: CGFloat, maxOffsetX: CGFloat, maxOffsetY: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let x = maxOffsetX > 0 ? min(max(offsetX / maxOffsetX, -1), 1) : 0
        let y = maxOffsetY > 0 ? min(max(offsetY / maxOffsetY, -1), 1) : 0
        return (x, y)
    }

    static func clampOffset(offsetX: CGFloat, offsetY: CGFloat, maxOffsetX: CGFloat, maxOffsetY: CGFloat) -> CGSize {
        CGSize(
            width: min(max(offsetX, -maxOffsetX), maxOffsetX),
            height: min(max(offsetY, -maxOffsetY), maxOffsetY)
        )
    }
}
