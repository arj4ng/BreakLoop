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

    // onboarding steuert ob auth als login, register oder guest startet
    @State private var authEntryIntent: AuthEntryIntent = .signIn

    // aktive uid im root für spätere dependency injection
    @State private var userId: String?

    // aktuelle session für onboarding save scope
    @State private var currentSession: AuthUserSession?

    // aktuelles profil für onboarding prefill
    @State private var currentProfile: UserProfile?

    // draft aus onboarding wird nach erstem login auf user profil geschrieben
    @State private var pendingOnboardingDraft: OnboardingDraft?

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
                AuthView(authService: authService, onAuthenticated: {

                    // nach auth change route erneut auflösen
                    route = .loading

                    Task {
                        await resolveInitialRoute()
                    }
                }, initialIntent: authEntryIntent)

            case .onboarding:
                OnboardingView(
                    initialProfile: currentProfile,
                    onChooseAuth: { intent, draft in
                        completeOnboarding(intent: intent, draft: draft)
                    }
                )

            case .app:
                DashboardView(onSignOut: {
                    handleSignOut()
                })
            }
        }
        .task {

            // bootstrap läuft beim app start und setzt route once
            await resolveInitialRoute()
        }
    }

    private func resolveInitialRoute() async {
        guard let session = authService.currentSession() else {

            // default für nicht eingeloggte user immer onboarding
            route = .onboarding
            return
        }

        do {
            userId = session.userId
            currentSession = session

            // legt profil doc an und lädt state
            let profile = try await ensureUserProfileDocument(for: session)

            // onboarding draft aus first-open flow jetzt auf account schreiben
            let finalProfile = try await applyPendingOnboardingIfNeeded(baseProfile: profile, session: session)
            currentProfile = finalProfile

            route = .app
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

    private func completeOnboarding(intent: AuthEntryIntent, draft: OnboardingDraft?) {
        // onboarding nur local abschließen, account save passiert nach auth
        pendingOnboardingDraft = draft
        authEntryIntent = intent
        route = .auth
    }

    private func applyPendingOnboardingIfNeeded(baseProfile: UserProfile?, session: AuthUserSession) async throws -> UserProfile? {
        guard let base = baseProfile else { return nil }
        guard let draft = pendingOnboardingDraft else { return base }

        let scope: FirestoreAccountScope = session.isAnonymous ? .guest : .registered
        let finalName = draft.displayName.isEmpty ? base.displayName : draft.displayName

        let updatedProfile = UserProfile(
            id: base.id,
            email: session.email,
            displayName: finalName,
            baselineDailyConsume: draft.baselineDailyConsume,
            baselineCostPerConsume: draft.baselineCostPerConsume,
            isGuestAccount: session.isAnonymous,
            onboardingCompleted: true,
            createdAt: base.createdAt,
            updatedAt: .now
        )

        try await userProfileRepository.saveUserProfile(updatedProfile, scope: scope)

        if draft.addFirstConsumable, !draft.firstConsumableName.isEmpty {
            let item = ConsumableItem(
                id: UUID().uuidString,
                userId: session.userId,
                name: draft.firstConsumableName,
                category: draft.firstConsumableCategory,
                defaultUnit: draft.firstConsumableUnit,
                defaultAmountPerConsume: 1,
                defaultCostPerConsume: draft.baselineCostPerConsume,
                note: nil,
                createdAt: .now,
                updatedAt: .now,
                isArchived: false
            )

            try await userProfileRepository.saveConsumableItem(item, scope: scope)
        }

        pendingOnboardingDraft = nil
        return updatedProfile
    }

    private func handleSignOut() {
        do {
            try authService.signOut()
            currentSession = nil
            currentProfile = nil
            userId = nil
            authEntryIntent = .signIn
            route = .auth
        } catch {
            authEntryIntent = .signIn
            route = .auth
        }
    }
}

#Preview {
    RootView()
}
