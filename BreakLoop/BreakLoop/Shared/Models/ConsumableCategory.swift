// BreakLoop/ BreakLoop/ Shared/ Models/ ConsumableCategory.swift

// consumable category
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


// MARK: ┏━ [11 MODELS] ConsumableCategory
// MARK: ┗━ generische kategorien damit app nicht auf zigaretten fixed ist

enum ConsumableCategory: String, Codable, CaseIterable, Hashable, Sendable {

    // nikotin produkte wie cigarette, vape, snus
    case nicotine

    // alkohol drinks unabhängig von marke
    case alcohol

    // cannabis flow separat für eigene insights
    case cannabis

    // caffeine konsum wie coffee oder energy
    case caffeine

    // medikamente wenn user das als consume tracken will
    case medicine

    // freie user kategorie für alles andere
    case custom
}
