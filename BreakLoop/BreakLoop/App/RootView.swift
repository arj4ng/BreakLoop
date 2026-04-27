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

    // zentraler app state für root routing und session flags
    @State private var appState = AppStateSnapshot()

    // onboarding steuert ob auth als login, register oder guest startet
    @State private var authEntryIntent: AuthEntryIntent = .signIn

    // aktuelle session für onboarding save scope
    @State private var currentSession: AuthUserSession?

    // aktuelles profil für onboarding prefill
    @State private var currentProfile: UserProfile?

    // draft aus onboarding wird nach erstem login auf user profil geschrieben
    @State private var pendingOnboardingDraft: OnboardingDraft?

    // register wird direkt über onboarding als modal geöffnet
    @State private var showsOnboardingRegisterSheet: Bool = false

    // sign in wird aus onboarding als modal geöffnet
    @State private var showsOnboardingAuthSheet: Bool = false

    // auth service prüft session und guest fallback
    private let authService: AuthServiceProtocol = FirebaseAuthService()

    // repo lädt profil um onboarding status zu prüfen
    private let userProfileRepository = FirestoreTrackingRepository()

    var body: some View {
        Group {
            switch appState.route {
            case .loading:
                ProgressView()

            case .auth:
                AuthView(authService: authService, onAuthenticated: {

                    // nach auth change route erneut auflösen
                    appState.route = .loading
                    appState.authOpenedFromOnboarding = false

                    Task {
                        await resolveInitialRoute()
                    }
                }, initialIntent: authEntryIntent, canGoBackToOnboarding: appState.authOpenedFromOnboarding, onBackToOnboarding: {
                    appState.authOpenedFromOnboarding = false
                    appState.route = .onboarding
                })

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
        .sheet(isPresented: $showsOnboardingRegisterSheet) {
            RegisterView(authService: authService, onRegistered: {
                    showsOnboardingRegisterSheet = false
                appState.route = .loading
                appState.authOpenedFromOnboarding = false

                Task {
                    await resolveInitialRoute()
                }
            }, onClose: {
                showsOnboardingRegisterSheet = false
            })
        }
        .sheet(isPresented: $showsOnboardingAuthSheet) {
            AuthView(
                authService: authService,
                onAuthenticated: {
                    showsOnboardingAuthSheet = false
                    appState.route = .loading
                    appState.authOpenedFromOnboarding = false

                    Task {
                        await resolveInitialRoute()
                    }
                },
                initialIntent: .signIn,
                canGoBackToOnboarding: true,
                onBackToOnboarding: {
                    showsOnboardingAuthSheet = false
                }
            )
        }
    }

    private func resolveInitialRoute() async {
        guard let session = authService.currentSession() else {

            // default für nicht eingeloggte user immer onboarding
            appState.route = .onboarding
            appState.authOpenedFromOnboarding = false
            return
        }

        do {
            appState.userId = session.userId
            currentSession = session

            // legt profil doc an und lädt state
            let profile = try await ensureUserProfileDocument(for: session)

            // onboarding draft aus first-open flow jetzt auf account schreiben
            let finalProfile = try await applyPendingOnboardingIfNeeded(baseProfile: profile, session: session)
            currentProfile = finalProfile

            appState.route = .app
        } catch {

            // bei fehler sicher auf auth fallback gehen
            appState.route = .auth
            appState.authOpenedFromOnboarding = false
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
                    preferredCurrencyCode: existing.preferredCurrencyCode,
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
            preferredCurrencyCode: "EUR",
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
        appState.authOpenedFromOnboarding = true

        // register flow direkt öffnen statt über login screen
        if intent == .register {
            showsOnboardingRegisterSheet = true
        } else if intent == .signIn {
            showsOnboardingAuthSheet = true
        } else {
            appState.route = .auth
        }
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
            preferredCurrencyCode: draft.preferredCurrencyCode,
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
                usageMethod: mapUsageMethod(draft.firstConsumableUsageMethod),
                pricingMode: mapPricingMode(draft.firstConsumablePricingMode),
                defaultPurchaseUnit: draft.firstConsumablePurchaseUnit,
                defaultAmountPerConsume: 1,
                defaultUnitsPerPurchase: draft.firstConsumableUnitsPerPurchase,
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

    private func mapUsageMethod(_ value: OnboardingUsageMethod) -> ConsumableUsageMethod {
        switch value {
        case .perPiece: return .perPiece
        case .perSession: return .perSession
        case .perGram: return .perGram
        case .perMilliliter: return .perMilliliter
        case .perCup: return .perCup
        case .perDose: return .perDose
        case .custom: return .custom
        }
    }

    private func mapPricingMode(_ value: OnboardingPricingMode) -> ConsumablePricingMode {
        switch value {
        case .perUnit: return .perUnit
        case .perPurchase: return .perPurchase
        }
    }

    private func handleSignOut() {
        do {
            try authService.signOut()
            currentSession = nil
            currentProfile = nil
            authEntryIntent = .signIn
            appState.clearSessionAndResetToOnboarding()
        } catch {
            authEntryIntent = .signIn
            appState.clearSessionAndResetToOnboarding()
        }
    }
}

#Preview {
    RootView()
}
