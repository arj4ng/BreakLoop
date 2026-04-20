// BreakLoop/ BreakLoop/ Shared/ Models/ PurchaseEntry.swift

// purchase entry
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


// MARK: ┏━ [11 MODELS] PurchaseEntry
// MARK: ┗━ Kaufdatensatz zur Nachverfolgung von Ausgaben und Preisverlauf

// kaufwerte raw behalten für spätere nachvollziehbare recalculation
struct PurchaseEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID

    // anzahl gekaufte packs in einem kauf event
    var packsBought: Int

    // pack größe im moment vom kauf für korrekte history
    var cigarettesPerPack: Int

    // total price bleibt raw kaufwert ohne auto umrechnung
    var totalPrice: Decimal

    // zeitpunkt vom kauf für kostenverlauf und auswertung
    var timestamp: Date
    let createdAt: Date

    // init hält kaufdaten vollständig in einem eintrag zusammen
    init(
        id: UUID = UUID(),
        packsBought: Int,
        cigarettesPerPack: Int,
        totalPrice: Decimal,
        timestamp: Date = .now,
        createdAt: Date = .now
    ) {

        // init mapped eingaben direkt auf das model
        self.id = id
        self.packsBought = packsBought
        self.cigarettesPerPack = cigarettesPerPack
        self.totalPrice = totalPrice
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
