// BreakLoop/ BreakLoop/ Shared/ Models/ UserProfile.swift

// user profile
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


// MARK: ┏━ [11 MODELS] UserProfile
// MARK: ┗━ Nutzerprofil für baseline kosten und tracking prefs

// profil hält nur kernwerte für berechnung und onboarding
struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var email: String?
    var displayName: String

    // baseline pro tag als startwert falls historie noch leer ist
    var baselineDailyConsume: Double

    // fallback cost pro consume wenn kaufdaten fehlen
    var baselineCostPerConsume: Decimal?

    // true solange account noch guest anonym ist
    var isGuestAccount: Bool

    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        email: String? = nil,
        displayName: String,
        baselineDailyConsume: Double = 0,
        baselineCostPerConsume: Decimal? = nil,
        isGuestAccount: Bool = true,
        onboardingCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {

        // init mapped inputs direkt auf modell
        self.id = id
        self.email = email
        self.displayName = displayName
        self.baselineDailyConsume = max(0, baselineDailyConsume)
        self.baselineCostPerConsume = baselineCostPerConsume
        self.isGuestAccount = isGuestAccount
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
