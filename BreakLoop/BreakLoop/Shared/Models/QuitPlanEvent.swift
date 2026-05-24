// BreakLoop/ BreakLoop/ Shared/ Models/ QuitPlanEvent.swift

// quit plan event
//
// Created by Arjang Khademi on 24.05.2026
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


enum QuitPlanEventType: String, Codable, CaseIterable, Hashable, Sendable {
    case milestone
    case craving
    case checkIn
    case note
    case symptom
    case reward
}


// MARK: ┏━ [11 MODELS] QuitPlanEvent
// MARK: ┗━ timeline event für quit plan history

// events bleiben erhalten damit statuswechsel und relapse erklärbar sind
struct QuitPlanEvent: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var userId: String
    var consumableItemId: String
    var quitPlanId: String
    var type: QuitPlanEventType
    var timestamp: Date
    var value: Double?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: String,
        userId: String,
        consumableItemId: String,
        quitPlanId: String,
        type: QuitPlanEventType,
        timestamp: Date = .now,
        value: Double? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.quitPlanId = quitPlanId
        self.type = type
        self.timestamp = timestamp
        self.value = value
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
