// BreakLoop/ BreakLoop/ Shared/ Models/ SmokeEntry.swift

// smoke entry
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


// MARK: ┏━ [11 MODELS] SmokeEntry
// MARK: ┗━ Einzelner Raucheintrag zur Nachverfolgung vom Konsum

// entry bewusst minimal und append only halten
struct SmokeEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID

    // kernwert für konsum tracking pro eintrag
    var cigarettesCount: Int

    // zeitpunkt vom event für timeline und filter
    var timestamp: Date
    let createdAt: Date

    // init bündelt smoke eintrag erstellung sauber
    init(
        id: UUID = UUID(),
        cigarettesCount: Int,
        timestamp: Date = .now,
        createdAt: Date = .now
    ) {

        // init mapped eingaben direkt auf das model
        self.id = id
        self.cigarettesCount = cigarettesCount
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
