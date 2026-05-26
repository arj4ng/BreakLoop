// BreakLoop/ BreakLoop/ Shared/ Models/ RelapseEvent.swift

// relapse event
//
// Created by Arjang Khademi on 24.05.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
  ║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
  ║ ╚═╝  ╚═╝╚═╝  ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import Foundation


// MARK: ┏━ [11 MODELS] RelapseEvent
// MARK: ┗━ relapse history mit optional verknüpftem consume entry

// event dokumentiert relapse ohne alten plan oder logs zu löschen
struct RelapseEvent: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var userId: String
    var consumableItemId: String
    var quitPlanId: String
    var timestamp: Date
    var amount: Double?
    var unit: ConsumeUnit?
    var reason: String?
    var createdConsumeEntryId: String?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: String,
        userId: String,
        consumableItemId: String,
        quitPlanId: String,
        timestamp: Date = .now,
        amount: Double? = nil,
        unit: ConsumeUnit? = nil,
        reason: String? = nil,
        createdConsumeEntryId: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.quitPlanId = quitPlanId
        self.timestamp = timestamp
        self.amount = amount.map { max(0, $0) }
        self.unit = unit
        self.reason = reason
        self.createdConsumeEntryId = createdConsumeEntryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
