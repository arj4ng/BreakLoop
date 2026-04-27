// BreakLoop/ BreakLoop/ Shared/ Models/ WeeklyStats.swift

// weekly stats
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


// MARK: ┏━ [11 MODELS] WeeklyStats
// MARK: ┗━ wöchentliche aggregierte werte pro consumable

struct WeeklyStats: Codable, Hashable, Sendable {

    // start von kalenderwoche
    var weekStartDate: Date

    // ende von kalenderwoche
    var weekEndDate: Date

    // item referenz
    var consumableItemId: String

    // summe consumes in woche
    var totalConsumes: Double

    // tagesdurchschnitt für woche
    var averageConsumesPerDay: Double

    // ausgaben in woche
    var moneySpent: Decimal

    // ersparnis in woche
    var moneySaved: Decimal

    // reward punkte in woche
    var rewardPoints: Int

    // true wenn komplette woche consume frei
    var isConsumeFree: Bool
}
