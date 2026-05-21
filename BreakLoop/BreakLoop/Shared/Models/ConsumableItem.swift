// BreakLoop/ BreakLoop/ Shared/ Models/ ConsumableItem.swift

// consumable item
//
// Created by Arjang Khademi on 27.04.2026
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

enum ConsumableUsageMethod: String, Codable, Hashable, Sendable {
    case perPiece
    case perSession
    case perGram
    case perMilliliter
    case perCup
    case perDose
    case custom
}

enum ConsumablePricingMode: String, Codable, Hashable, Sendable {
    case perUnit
    case perPurchase
}

// MARK: ┏━ [11 MODELS] ConsumableItem
// MARK: ┗━ user definierter konsum typ für entries und purchases

// item bleibt flexibel für zigaretten, alkohol, caffeine oder custom
struct ConsumableItem: Identifiable, Codable, Hashable, Sendable {

    // firestore doc id
    let id: String

    // owner user id
    let userId: String

    // user sichtbarer name vom item
    var name: String

    // grobe gruppierung für filtering
    var category: ConsumableCategory

    // standard unit für dieses item
    var defaultUnit: ConsumeUnit

    // beschreibt wie nutzung semantisch gemessen wird
    var usageMethod: ConsumableUsageMethod

    // bestimmt ob kosten direkt oder pro purchase gerechnet werden
    var pricingMode: ConsumablePricingMode

    // optionale purchase einheit zB pack für 20 piece
    var defaultPurchaseUnit: ConsumeUnit?

    // amount die für einen consume zählt, zB 0.7g oder 1 piece
    var defaultAmountPerConsume: Double?

    // default units in einem purchase container zB pack=20 piece
    var defaultUnitsPerPurchase: Double?

    // fallback wenn keine purchase daten da sind
    var defaultCostPerConsume: Decimal?

    var note: String?

    // ui preset für verständliche consume anzeige zB joint, gum, beer
    var consumePresetName: String?

    // ui preset für verständliche purchase anzeige zB bag, pack, bottle
    var purchasePresetName: String?

    // user sichtbarer consume name zB joint, cigarette, cup
    var trackName: String?

    // amount pro log in track unit, meistens 1
    var trackAmount: Double?

    // unit die beim loggen angezeigt und gespeichert wird
    var trackUnit: ConsumeUnit?

    // kostenbasis pro consume, zB ein joint nutzt 0.3 gram
    var costAmountPerTrack: Double?

    // unit für kostenberechnung, zB gram, piece, ml
    var costUnit: ConsumeUnit?

    // user sichtbarer kaufname zB bag, pack, bottle
    var purchaseName: String?

    // typische kaufmenge in defaultPurchaseUnit
    var defaultPurchaseAmount: Double?

    // creation timestamp für sortierung
    var createdAt: Date

    // update timestamp für sync
    var updatedAt: Date

    // archiv flag blendet item aus ohne datenverlust
    var isArchived: Bool

    init(
        id: String,
        userId: String,
        name: String,
        category: ConsumableCategory,
        defaultUnit: ConsumeUnit,
        usageMethod: ConsumableUsageMethod = .custom,
        pricingMode: ConsumablePricingMode = .perUnit,
        defaultPurchaseUnit: ConsumeUnit? = nil,
        defaultAmountPerConsume: Double? = nil,
        defaultUnitsPerPurchase: Double? = nil,
        defaultCostPerConsume: Decimal? = nil,
        note: String? = nil,
        consumePresetName: String? = nil,
        purchasePresetName: String? = nil,
        trackName: String? = nil,
        trackAmount: Double? = nil,
        trackUnit: ConsumeUnit? = nil,
        costAmountPerTrack: Double? = nil,
        costUnit: ConsumeUnit? = nil,
        purchaseName: String? = nil,
        defaultPurchaseAmount: Double? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {

        // init mapped inputs direkt auf modell
        self.id = id
        self.userId = userId
        self.name = name
        self.category = category
        self.defaultUnit = defaultUnit
        self.usageMethod = usageMethod
        self.pricingMode = pricingMode
        self.defaultPurchaseUnit = defaultPurchaseUnit
        self.defaultAmountPerConsume = defaultAmountPerConsume
        self.defaultUnitsPerPurchase = defaultUnitsPerPurchase.map { max(0, $0) }
        self.defaultCostPerConsume = defaultCostPerConsume
        self.note = note
        self.consumePresetName = consumePresetName
        self.purchasePresetName = purchasePresetName
        self.trackName = trackName
        self.trackAmount = trackAmount.map { max(0, $0) }
        self.trackUnit = trackUnit
        self.costAmountPerTrack = costAmountPerTrack.map { max(0, $0) }
        self.costUnit = costUnit
        self.purchaseName = purchaseName
        self.defaultPurchaseAmount = defaultPurchaseAmount.map { max(0, $0) }

        // createdAt bleibt original erstellzeitpunkt
        self.createdAt = createdAt

        // updatedAt wird bei edits später ersetzt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}

extension ConsumableItem {
    var effectiveTrackName: String {
        let value = trackName ?? consumePresetName ?? name
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? name : value
    }

    var effectiveTrackAmount: Double {
        positive(trackAmount) ?? positive(defaultAmountPerConsume) ?? 1
    }

    var effectiveTrackUnit: ConsumeUnit {
        trackUnit ?? defaultUnit
    }

    var effectiveCostUnit: ConsumeUnit {
        costUnit ?? inferredLegacyCostUnit
    }

    var effectiveCostAmountPerTrack: Double {
        positive(costAmountPerTrack) ?? inferredLegacyCostAmountPerTrack
    }

    var effectivePurchaseName: String {
        let value = purchaseName ?? purchasePresetName ?? "Purchase"
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Purchase" : value
    }

    var effectiveDefaultPurchaseAmount: Double {
        positive(defaultPurchaseAmount) ?? positive(defaultUnitsPerPurchase) ?? 1
    }

    var effectiveDefaultPurchaseUnit: ConsumeUnit {
        defaultPurchaseUnit ?? effectiveCostUnit
    }

    var usesDynamicCostModel: Bool {
        trackName != nil ||
        trackAmount != nil ||
        trackUnit != nil ||
        costAmountPerTrack != nil ||
        costUnit != nil ||
        purchaseName != nil ||
        defaultPurchaseAmount != nil
    }

    private var inferredLegacyCostUnit: ConsumeUnit {
        if let defaultPurchaseUnit, defaultPurchaseUnit != .pack {
            return defaultPurchaseUnit
        }

        return defaultUnit == .pack ? .piece : defaultUnit
    }

    private var inferredLegacyCostAmountPerTrack: Double {
        if let defaultAmount = positive(defaultAmountPerConsume), effectiveCostUnit == defaultUnit {
            return defaultAmount
        }

        if category == .cannabis, defaultUnit == .piece, effectiveCostUnit == .gram {
            return 0.3
        }

        return positive(defaultAmountPerConsume) ?? 1
    }

    private func positive(_ value: Double?) -> Double? {
        guard let value, value > 0 else { return nil }
        return value
    }
}
