// BreakLoop/ BreakLoop/ Core/ DesignSystem/ Colors.swift

// colors
//
// Created by Arjang Khademi on 20.04.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
  ║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
  ║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import SwiftUI


// MARK: ┏━ [14 DESIGN COLORS] AppColors
// MARK: ┗━ Zentrale app farben aus xcassets fürs theme

// colors nur nach nutzung benennen, nie nach raw werten
enum AppColors {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceElevated = Color("SurfaceElevated")
    static let cardBackground = Color("CardBackground")
    static let inputBackground = Color("InputBackground")
    static let navBackground = Color("NavBackground")
    static let tabBarBackground = Color("TabBarBackground")
    static let overlay = Color("Overlay").opacity(0.62)

    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textInverse = Color("TextInverse")
    static let textOnAccent = Color("TextOnAccent")
    static let textDisabled = Color("TextDisabled")

    static let border = Color("Border")
    static let borderStrong = Color("BorderStrong")
    static let divider = Color("Divider")

    static let accent = Color("BrandAccent")
    static let accentStrong = Color("BrandAccentStrong")
    static let accentSoft = Color("BrandAccentSoft")
    static let buttonPrimaryBackground = Color("ButtonPrimaryBackground")
    static let buttonSecondaryBackground = Color("ButtonSecondaryBackground")
    static let buttonSecondaryText = Color("ButtonSecondaryText")
    static let disabledBackground = Color("DisabledBackground")

    static let success = Color("Success")
    static let successStrong = Color("SuccessStrong")
    static let warning = Color("Warning")
    static let danger = Color("Danger")
    static let info = Color("Info")

    static let chartPrimary = Color("ChartPrimary")
    static let chartSecondary = Color("ChartSecondary")
    static let chartTertiary = Color("ChartTertiary")
}
