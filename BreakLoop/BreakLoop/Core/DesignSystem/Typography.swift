import SwiftUI

enum AppTypography {
    enum Weight {
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }

    // Industry standard semantic scale for mobile UI.
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

extension View {
    func appTypography(_ font: Font) -> some View {
        self.font(font)
    }
}
