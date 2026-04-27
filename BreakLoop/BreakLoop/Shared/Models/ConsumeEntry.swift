// BreakLoop/ BreakLoop/ Shared/ Models/ ConsumeEntry.swift

// consume entry
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


// MARK: ┏━ [11 MODELS] ConsumeEntry
// MARK: ┗━ einzelner consume log mit amount, unit und optional context

// entry enthält soft delete flags damit edits und history sauber bleiben
struct ConsumeEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let consumableItemId: String
    var timestamp: Date
    var amount: Double
    var unit: ConsumeUnit
    var note: String?
    var trigger: TriggerType?

    // craving level 1..10 optional für späteres insight scoring
    var cravingLevel: Int?

    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAt: Date?

    init(
        id: String,
        userId: String,
        consumableItemId: String,
        timestamp: Date = .now,
        amount: Double,
        unit: ConsumeUnit,
        note: String? = nil,
        trigger: TriggerType? = nil,
        cravingLevel: Int? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDeleted: Bool = false,
        deletedAt: Date? = nil
    ) {

        // init clamp schützt gegen negative amounts und out of range craving
        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.timestamp = timestamp
        self.amount = max(0, amount)
        self.unit = unit
        self.note = note
        self.trigger = trigger
        self.cravingLevel = cravingLevel.map { min(max($0, 1), 10) }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
    }
}
