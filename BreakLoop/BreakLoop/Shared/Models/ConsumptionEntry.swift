// BreakLoop/ BreakLoop/ Shared/ Models/ ConsumptionEntry.swift

// consumption entry
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


// MARK: ┏━ [11 MODELS] ConsumptionEntry
// MARK: ┗━ Einzelner Konsum eintrag zur Nachverfolgung vom Konsum

// entry bewusst minimal und append only halten
struct ConsumptionEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID

    // kernwert für konsum tracking pro eintrag
    var consumedUnitsCount: Int

    // zeitpunkt vom event für timeline und filter
    var timestamp: Date
    let createdAt: Date

    // init bündelt konsum eintrag erstellung sauber
    init(
        id: UUID = UUID(),
        consumedUnitsCount: Int,
        timestamp: Date = .now,
        createdAt: Date = .now
    ) {

        // init mapped eingaben direkt auf das model
        self.id = id
        self.consumedUnitsCount = consumedUnitsCount
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
