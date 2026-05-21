// BreakLoop/ BreakLoop/ Features/ Settings/ Models/ SettingsModel.swift

// Settings model
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

import Foundation


// MARK: ┏━ [11 MODELS] SettingsModel
// MARK: ┗━ settings model für daten

struct SettingsModel {}

struct ConsumableFormSubmission: Hashable, Sendable {
    let name: String
    let category: ConsumableCategory
    let consumePresetName: String
    let defaultAmountPerConsumeText: String
    let defaultUnit: ConsumeUnit
    let usageMethod: ConsumableUsageMethod
    let purchasePresetName: String
    let defaultPurchaseUnit: ConsumeUnit
    let defaultUnitsPerPurchaseText: String
}

struct ConsumableSetupPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let unit: ConsumeUnit
    let usageMethod: ConsumableUsageMethod
    let defaultAmountText: String
    let purchaseUnit: ConsumeUnit
    let purchaseAmountText: String

    var defaultAmount: Double {
        Double(defaultAmountText.replacingOccurrences(of: ",", with: ".")) ?? 1
    }
}

enum ConsumableSetupPresets {
    static var fallbackPreset: ConsumableSetupPreset {
        ConsumableSetupPreset(
            id: "custom",
            title: "Custom",
            unit: .piece,
            usageMethod: .custom,
            defaultAmountText: "1",
            purchaseUnit: .piece,
            purchaseAmountText: "1"
        )
    }

    static func consumePresets(for category: ConsumableCategory) -> [ConsumableSetupPreset] {
        switch category {
        case .cannabis:
            return [
                preset("joint", "Joint", .piece, .perPiece, "1", .gram, "5"),
                preset("gram", "Gram", .gram, .perGram, "0.3", .gram, "5"),
                preset("edible", "Edible", .piece, .perPiece, "1", .piece, "10"),
                preset("vapeHit", "Vape hit", .piece, .perPiece, "1", .gram, "1")
            ]
        case .nicotine:
            return [
                preset("cigarette", "Cigarette", .piece, .perPiece, "1", .pack, "20"),
                preset("gum", "Gum", .piece, .perPiece, "1", .pack, "30"),
                preset("pouch", "Pouch", .piece, .perPiece, "1", .pack, "20"),
                preset("vapePuff", "Vape puff", .piece, .perPiece, "5", .milliliter, "10"),
                preset("tobaccoGram", "Tobacco gram", .gram, .perGram, "1", .gram, "30")
            ]
        case .alcohol:
            return [
                preset("beer", "Beer", .milliliter, .perMilliliter, "500", .milliliter, "500"),
                preset("wine", "Wine glass", .milliliter, .perMilliliter, "150", .milliliter, "750"),
                preset("shot", "Shot", .milliliter, .perMilliliter, "40", .milliliter, "700"),
                preset("cocktail", "Cocktail", .piece, .perPiece, "1", .piece, "1")
            ]
        case .caffeine:
            return [
                preset("coffee", "Coffee", .cup, .perCup, "1", .gram, "500"),
                preset("energyDrink", "Energy drink", .piece, .perPiece, "1", .piece, "1"),
                preset("tea", "Tea", .cup, .perCup, "1", .piece, "20"),
                preset("pill", "Caffeine pill", .dose, .perDose, "1", .dose, "100")
            ]
        case .medicine:
            return [
                preset("pill", "Pill", .dose, .perDose, "1", .dose, "30"),
                preset("dose", "Dose", .dose, .perDose, "1", .dose, "1"),
                preset("ml", "Milliliter", .milliliter, .perMilliliter, "5", .milliliter, "100")
            ]
        case .custom:
            return [preset("custom", "Custom", .piece, .custom, "1", .piece, "1")]
        }
    }

    private static func preset(
        _ id: String,
        _ title: String,
        _ unit: ConsumeUnit,
        _ usageMethod: ConsumableUsageMethod,
        _ defaultAmountText: String,
        _ purchaseUnit: ConsumeUnit,
        _ purchaseAmountText: String
    ) -> ConsumableSetupPreset {
        ConsumableSetupPreset(
            id: id,
            title: title,
            unit: unit,
            usageMethod: usageMethod,
            defaultAmountText: defaultAmountText,
            purchaseUnit: purchaseUnit,
            purchaseAmountText: purchaseAmountText
        )
    }
}
