// BreakLoop/ BreakLoop/ App/ AppState.swift

// app state
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


// MARK: ┏━ [01 APP FLOW] AppRoute
// MARK: ┗━ globale routes für root navigation switch

enum AppRoute: Hashable {

    // bootstrap prüft auth/profile state
    case loading

    // auth screen für sign in only
    case auth

    // onboarding flow bevor tracking startet
    case onboarding

    // haupt app dashboard und tabs
    case app
}


// MARK: ┏━ [01 APP FLOW] AppStateSnapshot
// MARK: ┗━ zentraler zustand für session + routing entscheidungen

struct AppStateSnapshot: Equatable {

    // welche root route aktuell sichtbar sein soll
    var route: AppRoute = .loading

    // true wenn auth modal aus onboarding geöffnet wurde
    var authOpenedFromOnboarding: Bool = false

    // active session user id wenn eingeloggt
    var userId: String?

    // helper für konsistente reset flows
    mutating func clearSessionAndResetToOnboarding() {

        // signout reset bringt user immer zu onboarding
        route = .onboarding
        authOpenedFromOnboarding = false
        userId = nil
    }
}
