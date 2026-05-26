// BreakLoop/ BreakLoop/ Shared/ Models/ MonthlyStats.swift

// monthly stats
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


// MARK: ┏━ [11 MODELS] MonthlyStats
// MARK: ┗━ monatliche aggregierte werte pro consumable

struct MonthlyStats: Codable, Hashable, Sendable {

    // start vom monat
    var monthStartDate: Date

    // ende vom monat
    var monthEndDate: Date

    // item referenz
    var consumableItemId: String

    // summe consumes im monat
    var totalConsumes: Double

    // tagesdurchschnitt im monat
    var averageConsumesPerDay: Double

    // ausgaben im monat
    var moneySpent: Decimal

    // ersparnis im monat
    var moneySaved: Decimal

    // reward punkte im monat
    var rewardPoints: Int

    // true wenn kompletter monat consume frei
    var isConsumeFree: Bool
}
