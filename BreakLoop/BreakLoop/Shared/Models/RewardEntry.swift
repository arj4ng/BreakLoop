// BreakLoop/ BreakLoop/ Shared/ Models/ RewardEntry.swift

// reward entry
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


// MARK: ┏━ [11 MODELS] RewardEntry
// MARK: ┗━ reward event für points historie

struct RewardEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let consumableItemId: String?
    var type: RewardType
    var points: Int
    var reason: String?
    var createdAt: Date

    init(
        id: String,
        userId: String,
        consumableItemId: String? = nil,
        type: RewardType,
        points: Int,
        reason: String? = nil,
        createdAt: Date = .now
    ) {

        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.type = type
        self.points = max(0, points)
        self.reason = reason
        self.createdAt = createdAt
    }
}
