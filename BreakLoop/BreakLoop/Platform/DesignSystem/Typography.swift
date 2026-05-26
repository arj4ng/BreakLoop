// BreakLoop/ BreakLoop/ Core/ DesignSystem/ Typography.swift

// typography
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


// MARK: ┏━ [15 DESIGN TYPE] AppTypography
// MARK: ┗━ Gemeinsame SF Pro typography tokens für app texte

// typografie nur über tokens nutzen, keine hardcoded größen im feature code
enum AppTypography {

    // MARK: ┏━ [15 DESIGN TYPE] Weight
    // MARK: ┗━ Wiederverwendbare font weights für typography tokens

    // weight alias halten style definitionen gut lesbar
    enum Weight {
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }

    static let displayLarge = Font.system(size: 34, weight: Weight.bold, design: .default)
    static let display = Font.system(size: 28, weight: Weight.bold, design: .default)

    static let title1 = Font.system(size: 24, weight: Weight.bold, design: .default)
    static let title2 = Font.system(size: 22, weight: Weight.semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: Weight.semibold, design: .default)

    static let headline = Font.system(size: 17, weight: Weight.semibold, design: .default)
    static let body = Font.system(size: 17, weight: Weight.regular, design: .default)
    static let bodyEmphasis = Font.system(size: 17, weight: Weight.medium, design: .default)
    static let callout = Font.system(size: 16, weight: Weight.regular, design: .default)

    static let subheadline = Font.system(size: 15, weight: Weight.regular, design: .default)
    static let footnote = Font.system(size: 13, weight: Weight.regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: Weight.regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: Weight.regular, design: .default)

    static let buttonPrimary = Font.system(size: 17, weight: Weight.semibold, design: .default)
    static let buttonSecondary = Font.system(size: 15, weight: Weight.medium, design: .default)
}


// MARK: ┏━ [15 DESIGN TYPE] View Erweiterung
// MARK: ┗━ Helper zum Anwenden von typography tokens

// helper schlank halten, token auswahl passiert in feature views
extension View {

    // MARK: ┏━ [15 DESIGN TYPE] appTypography
    // MARK: ┗━ Wendet ein Design System Schrift Token auf die aktuelle View an

    func appTypography(_ font: Font) -> some View {
        self.font(font)
    }
}
