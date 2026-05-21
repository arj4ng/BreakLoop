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
    let trackName: String
    let trackAmountText: String
    let trackUnit: ConsumeUnit
    let usageMethod: ConsumableUsageMethod
    let costAmountPerTrackText: String
    let costUnit: ConsumeUnit
    let purchaseName: String
    let purchaseAmountText: String
    let purchaseUnit: ConsumeUnit
}

struct ConsumableSetupPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let trackName: String
    let trackAmountText: String
    let trackUnit: ConsumeUnit
    let usageMethod: ConsumableUsageMethod
    let costAmountPerTrackText: String
    let costUnit: ConsumeUnit
    let purchaseName: String
    let defaultPurchaseAmountText: String
    let defaultPurchaseUnit: ConsumeUnit

    var trackAmount: Double {
        Double(trackAmountText.replacingOccurrences(of: ",", with: ".")) ?? 1
    }
}

enum ConsumableSetupPresets {
    static var fallbackPreset: ConsumableSetupPreset {
        ConsumableSetupPreset(
            id: "custom",
            title: "Custom",
            trackName: "unit",
            trackAmountText: "1",
            trackUnit: .piece,
            usageMethod: .custom,
            costAmountPerTrackText: "1",
            costUnit: .piece,
            purchaseName: "Purchase",
            defaultPurchaseAmountText: "1",
            defaultPurchaseUnit: .piece
        )
    }

    static func consumePresets(for category: ConsumableCategory) -> [ConsumableSetupPreset] {
        switch category {
        case .cannabis:
            return [
                preset("joint", "Joint", "joint", "1", .piece, .perPiece, "0.3", .gram, "Bag", "5", .gram),
                preset("gram", "Gram", "gram", "1", .gram, .perGram, "1", .gram, "Bag", "5", .gram),
                preset("edible", "Edible", "edible", "1", .piece, .perPiece, "1", .piece, "Pack", "10", .piece),
                preset("vapeHit", "Vape hit", "hit", "1", .piece, .perPiece, "0.05", .gram, "Cartridge", "1", .gram)
            ]
        case .nicotine:
            return [
                preset("cigarette", "Cigarette", "cigarette", "1", .piece, .perPiece, "1", .piece, "Pack", "20", .piece),
                preset("gum", "Gum", "gum", "1", .piece, .perPiece, "1", .piece, "Pack", "30", .piece),
                preset("pouch", "Pouch", "pouch", "1", .piece, .perPiece, "1", .piece, "Can", "20", .piece),
                preset("vapePuff", "Vape puff", "puffs", "5", .piece, .perPiece, "0.05", .milliliter, "Bottle", "10", .milliliter),
                preset("tobaccoGram", "Tobacco gram", "gram", "1", .gram, .perGram, "1", .gram, "Bag", "30", .gram)
            ]
        case .alcohol:
            return [
                preset("beer", "Beer", "beer", "1", .piece, .perPiece, "500", .milliliter, "Can", "500", .milliliter),
                preset("wine", "Wine glass", "glass", "1", .piece, .perPiece, "150", .milliliter, "Bottle", "750", .milliliter),
                preset("shot", "Shot", "shot", "1", .piece, .perPiece, "40", .milliliter, "Bottle", "700", .milliliter),
                preset("cocktail", "Cocktail", "cocktail", "1", .piece, .perPiece, "1", .piece, "Drink", "1", .piece)
            ]
        case .caffeine:
            return [
                preset("coffee", "Coffee", "cup", "1", .cup, .perCup, "1", .cup, "Coffee", "1", .cup),
                preset("coffeeBeans", "Coffee beans", "cup", "1", .cup, .perCup, "10", .gram, "Bag", "500", .gram),
                preset("energyDrink", "Energy drink", "can", "1", .piece, .perPiece, "1", .piece, "Can", "1", .piece),
                preset("tea", "Tea", "cup", "1", .cup, .perCup, "1", .piece, "Box", "20", .piece),
                preset("pill", "Caffeine pill", "pill", "1", .dose, .perDose, "1", .dose, "Box", "100", .dose)
            ]
        case .medicine:
            return [
                preset("pill", "Pill", "pill", "1", .dose, .perDose, "1", .dose, "Box", "30", .dose),
                preset("dose", "Dose", "dose", "1", .dose, .perDose, "1", .dose, "Dose", "1", .dose),
                preset("ml", "Milliliter", "dose", "1", .dose, .perDose, "5", .milliliter, "Bottle", "100", .milliliter)
            ]
        case .custom:
            return [preset("custom", "Custom", "unit", "1", .piece, .custom, "1", .piece, "Purchase", "1", .piece)]
        }
    }

    private static func preset(
        _ id: String,
        _ title: String,
        _ trackName: String,
        _ trackAmountText: String,
        _ trackUnit: ConsumeUnit,
        _ usageMethod: ConsumableUsageMethod,
        _ costAmountPerTrackText: String,
        _ costUnit: ConsumeUnit,
        _ purchaseName: String,
        _ defaultPurchaseAmountText: String,
        _ defaultPurchaseUnit: ConsumeUnit
    ) -> ConsumableSetupPreset {
        ConsumableSetupPreset(
            id: id,
            title: title,
            trackName: trackName,
            trackAmountText: trackAmountText,
            trackUnit: trackUnit,
            usageMethod: usageMethod,
            costAmountPerTrackText: costAmountPerTrackText,
            costUnit: costUnit,
            purchaseName: purchaseName,
            defaultPurchaseAmountText: defaultPurchaseAmountText,
            defaultPurchaseUnit: defaultPurchaseUnit
        )
    }
}
