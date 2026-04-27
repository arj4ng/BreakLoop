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

    // firestore doc id
    let id: String

    // owner user id
    let userId: String

    // optional item link für item spezifische rewards
    let consumableItemId: String?

    // reward event typ
    var type: RewardType

    // punktestand für event
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

        // init mapping bleibt straight ohne extra logik
        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.type = type

        // keine negativen punkte speichern
        self.points = max(0, points)
        self.reason = reason
        self.createdAt = createdAt
    }
}
