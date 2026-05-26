// BreakLoop/ BreakLoop/ Shared/ Models/ DailyStats.swift

// daily stats
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


// MARK: ┏━ [11 MODELS] DailyStats
// MARK: ┗━ tägliche aggregierte werte pro consumable

struct DailyStats: Codable, Hashable, Sendable {

    // referenz tag
    var date: Date

    // für welches item stats gelten
    var consumableItemId: String

    // summe consumes an diesem tag
    var totalConsumes: Double

    // durchschnitt consume baseline
    var averageConsumes: Double

    // ausgegebenes geld an diesem tag
    var moneySpent: Decimal

    // gespartes geld vs average
    var moneySaved: Decimal

    // gesammelte punkte
    var rewardPoints: Int

    // true wenn tag komplett consume frei
    var isConsumeFree: Bool
}
