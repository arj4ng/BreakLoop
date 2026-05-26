import SwiftUI

struct WallpaperAdaptiveStyle {
    let wallpaperPrimaryText: Color
    let wallpaperSecondaryText: Color
    let wallpaperMutedText: Color
    let wallpaperGlassFill: Material
    let wallpaperGlassBorder: Color
    let wallpaperTabUnselected: Color
    let inactiveTabCapsuleFill: Color

    static func resolve(
        settings: WallpaperSettings,
        colorScheme: ColorScheme,
        colorSchemeContrast: ColorSchemeContrast
    ) -> WallpaperAdaptiveStyle {
        guard settings.isEnabled else {
            return WallpaperAdaptiveStyle(
                wallpaperPrimaryText: AppColors.textPrimary,
                wallpaperSecondaryText: AppColors.textSecondary,
                wallpaperMutedText: AppColors.textSecondary.opacity(0.75),
                wallpaperGlassFill: .ultraThinMaterial,
                wallpaperGlassBorder: AppColors.border.opacity(colorSchemeContrast == .increased ? 0.36 : 0.18),
                wallpaperTabUnselected: AppColors.textSecondary,
                inactiveTabCapsuleFill: .clear
            )
        }

        let tintIsLight = settings.readabilityTintMode == .light
        let extraContrast = colorSchemeContrast == .increased ? 0.14 : 0.0
        let secondaryBase = tintIsLight ? 0.9 : 0.78
        let mutedBase = tintIsLight ? 0.72 : 0.62
        let tabBase = tintIsLight ? 0.92 : 0.82
        let textBase: Color = tintIsLight ? .black : .white
        let tabTextBase: Color = colorScheme == .light ? .black : .white

        return WallpaperAdaptiveStyle(
            wallpaperPrimaryText: textBase.opacity(min(1, 0.96 + extraContrast)),
            wallpaperSecondaryText: textBase.opacity(min(1, secondaryBase + extraContrast)),
            wallpaperMutedText: textBase.opacity(min(1, mutedBase + extraContrast)),
            wallpaperGlassFill: (settings.surfaceOpacityBoost > 0.26 || colorSchemeContrast == .increased) ? .regularMaterial : .thinMaterial,
            wallpaperGlassBorder: textBase.opacity(0.12 + extraContrast),
            wallpaperTabUnselected: tabTextBase.opacity(min(1, (colorScheme == .light ? 0.62 : tabBase) + extraContrast)),
            inactiveTabCapsuleFill: tabTextBase.opacity(colorScheme == .light ? 0.06 : 0.12)
        )
    }
}
