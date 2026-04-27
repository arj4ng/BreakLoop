// BreakLoop/ BreakLoop/ App/ RootView.swift

// root view
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

import SwiftUI


// MARK: ┏━ [01 APP FLOW] RootView
// MARK: ┗━ Root routing für loading, auth, onboarding und app state

struct RootView: View {

    // route steuert welchen app zustand user gerade sieht
    private enum Route {
        case loading
        case auth
        case onboarding
        case app
    }

    // start immer im loading state bis auth/profile geprüft wurde
    @State private var route: Route = .loading

    // aktive uid im root für spätere dependency injection
    @State private var userId: String?

    // auth service prüft session und guest fallback
    private let authService: AuthServiceProtocol = FirebaseAuthService()

    // repo lädt profil um onboarding status zu prüfen
    private let userProfileRepository = FirestoreTrackingRepository()

    var body: some View {
        Group {
            switch route {
            case .loading:
                ProgressView()

            case .auth:
                AuthView(authService: authService) {

                    // nach auth change route erneut auflösen
                    route = .loading

                    Task {
                        await resolveInitialRoute()
                    }
                }

            case .onboarding:
                VStack(spacing: 12) {
                    Text("onboarding flow placeholder")

                    Button("Continue to app") {
                        route = .app
                    }
                    .buttonStyle(.bordered)

                    Button("Sign out") {
                        if authService.isAnonymous {

                            // guest logout bleibt auf gleicher device session
                            route = .auth
                        } else {
                            do {
                                try authService.signOut()
                                route = .auth
                            } catch {
                                route = .auth
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)

            case .app:
                DashboardView()
            }
        }
        .task {

            // bootstrap läuft beim app start und setzt route once
            await resolveInitialRoute()
        }
    }

    private func resolveInitialRoute() async {
        do {

            // stellt sicher dass wir eine session haben guest oder normal
            let session = try await authService.signInAnonymouslyIfNeeded()
            userId = session.userId

            // legt users/{uid} automatisch an falls noch nicht vorhanden
            let profile = try await ensureUserProfileDocument(for: session)

            // profil entscheidet ob onboarding bereits abgeschlossen ist
            if let profile, profile.onboardingCompleted {
                route = .app
            } else {

                // guest und normale user ohne onboarding gehen beide ins onboarding
                route = .onboarding
            }
        } catch {

            // bei fehler sicher auf auth fallback gehen
            route = .auth
        }
    }

    private func ensureUserProfileDocument(for session: AuthUserSession) async throws -> UserProfile? {
        let scope: FirestoreAccountScope = session.isAnonymous ? .guest : .registered

        if let existing = try await userProfileRepository.fetchUserProfile(userId: session.userId, scope: scope) {

            // guest flag und email bei statuswechsel sauber halten
            if existing.isGuestAccount != session.isAnonymous || existing.email != session.email {
                let updated = UserProfile(
                    id: existing.id,
                    email: session.email,
                    displayName: existing.displayName,
                    baselineDailyConsume: existing.baselineDailyConsume,
                    baselineCostPerConsume: existing.baselineCostPerConsume,
                    isGuestAccount: session.isAnonymous,
                    onboardingCompleted: existing.onboardingCompleted,
                    createdAt: existing.createdAt,
                    updatedAt: .now
                )

                try await userProfileRepository.saveUserProfile(updated, scope: scope)
                return updated
            }

            return existing
        }

        let profile = UserProfile(
            id: session.userId,
            email: session.email,
            displayName: session.isAnonymous ? "Guest" : "User",
            baselineDailyConsume: 0,
            baselineCostPerConsume: nil,
            isGuestAccount: session.isAnonymous,
            onboardingCompleted: false,
            createdAt: .now,
            updatedAt: .now
        )

        try await userProfileRepository.saveUserProfile(profile, scope: scope)
        return profile
    }
}

#Preview {
    RootView()
}
