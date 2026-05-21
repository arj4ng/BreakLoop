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

        // createdAt bleibt original erstellzeitpunkt
        self.createdAt = createdAt

        // updatedAt wird bei edits später ersetzt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
