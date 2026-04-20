// BreakLoop/ BreakLoop/ Shared/ Models/ UserProfile.swift

// user profile
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


// MARK: ┏━ [11 MODELS] UserProfile
// MARK: ┗━ Basis Nutzerwerte für Kosten und Reward Berechnung

// model stabil halten für persistenz und spätere migrationen
struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var displayName: String

    // baseline wert für spätere vergleichsrechnung im dashboard
    var cigarettesPerDayBaseline: Int

    // fallback pack größe falls keine purchase daten da sind
    var cigarettesPerPack: Int

    // basis preis pro pack für cost berechnung
    var pricePerPack: Decimal
    let createdAt: Date
    var updatedAt: Date

    // init hält profile erstellung zentral an einer stelle
    init(
        id: UUID = UUID(),
        displayName: String,
        cigarettesPerDayBaseline: Int,
        cigarettesPerPack: Int,
        pricePerPack: Decimal,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {

        // init mapped eingaben direkt auf das model
        self.id = id
        self.displayName = displayName
        self.cigarettesPerDayBaseline = cigarettesPerDayBaseline
        self.cigarettesPerPack = cigarettesPerPack
        self.pricePerPack = pricePerPack
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
