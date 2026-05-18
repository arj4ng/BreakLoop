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

// form draft trennt ui input von firestore modell
struct ConsumableFormDraft: Hashable {
    var name: String
    var category: ConsumableCategory
    var defaultUnit: ConsumeUnit
    var usageMethod: ConsumableUsageMethod
    var pricingMode: ConsumablePricingMode
    var defaultPurchaseUnit: ConsumeUnit
    var defaultUnitsPerPurchaseText: String

    init(
        name: String = "",
        category: ConsumableCategory = .custom,
        defaultUnit: ConsumeUnit = .piece,
        usageMethod: ConsumableUsageMethod = .custom,
        pricingMode: ConsumablePricingMode = .perUnit,
        defaultPurchaseUnit: ConsumeUnit = .pack,
        defaultUnitsPerPurchaseText: String = ""
    ) {
        self.name = name
        self.category = category
        self.defaultUnit = defaultUnit
        self.usageMethod = usageMethod
        self.pricingMode = pricingMode
        self.defaultPurchaseUnit = defaultPurchaseUnit
        self.defaultUnitsPerPurchaseText = defaultUnitsPerPurchaseText
    }

    init(item: ConsumableItem) {
        self.init(
            name: item.name,
            category: item.category,
            defaultUnit: item.defaultUnit,
            usageMethod: item.usageMethod,
            pricingMode: item.pricingMode,
            defaultPurchaseUnit: item.defaultPurchaseUnit ?? .pack,
            defaultUnitsPerPurchaseText: item.defaultUnitsPerPurchase.map { String($0) } ?? ""
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var parsedUnitsPerPurchase: Double? {
        Double(defaultUnitsPerPurchaseText.replacingOccurrences(of: ",", with: "."))
    }

    var isValid: Bool {
        guard !trimmedName.isEmpty else { return false }
        if pricingMode == .perPurchase {
            guard let parsedUnitsPerPurchase, parsedUnitsPerPurchase > 0 else { return false }
        }
        return true
    }
}

struct SettingsConsumableFormResult: Hashable {
    var draft: ConsumableFormDraft
    var existingItem: ConsumableItem?
}
