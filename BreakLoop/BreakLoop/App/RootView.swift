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
                        // Task startet async arbeit aus normalem button callback
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
                if let session = currentSession {
                    DashboardView(
                        userId: session.userId,
                        scope: session.isAnonymous ? .guest : .registered,
                        onSignOut: {
                            handleSignOut()
                        }
                    )
                } else {
                    ProgressView()
                }
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
                    // route braucht firebase/profile daten, deshalb async neu laden
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
                        // auth modal fertig, root status danach neu berechnen
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

    // async weil firebase/profile laden nicht sofort fertig ist
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

            // linked guest accounts keep uid, but app reads registered root after signup
            try await migrateLinkedGuestDataIfNeeded(for: session)

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

    // async throws: firestore lesen/schreiben kann warten und fehlschlagen
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

    // wenn guest zu email gelinkt wird, müssen alte guest subcollections in users/{uid}
    private func migrateLinkedGuestDataIfNeeded(for session: AuthUserSession) async throws {
        guard session.isAnonymous == false else { return }

        let registeredSnapshot = try await userProfileRepository.exportUserDataSnapshot(userId: session.userId, scope: .registered)
        guard registeredSnapshot.consumableItems.isEmpty else { return }

        let guestSnapshot = try await userProfileRepository.exportUserDataSnapshot(userId: session.userId, scope: .guest)
        guard guestSnapshot.hasAnyData else { return }

        try await userProfileRepository.importUserDataSnapshot(
            guestSnapshot,
            targetUserId: session.userId,
            targetScope: .registered
        )
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

    // async throws: onboarding draft wird nach login in firestore gespeichert
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
                defaultAmountPerConsume: draft.firstConsumableTrackAmount,
                defaultUnitsPerPurchase: draft.firstConsumableUnitsPerPurchase,
                defaultCostPerConsume: nil,
                note: nil,
                consumePresetName: draft.firstConsumableTrackName,
                purchasePresetName: draft.firstConsumablePurchaseName,
                trackName: draft.firstConsumableTrackName,
                trackAmount: draft.firstConsumableTrackAmount,
                trackUnit: draft.firstConsumableTrackUnit,
                costAmountPerTrack: draft.firstConsumableCostAmountPerTrack,
                costUnit: draft.firstConsumableCostUnit,
                purchaseName: draft.firstConsumablePurchaseName,
                defaultPurchaseAmount: draft.firstConsumableDefaultPurchaseAmount,
                createdAt: .now,
                updatedAt: .now,
                isArchived: false
            )

            try await userProfileRepository.saveConsumableItem(item, scope: scope)

            if draft.initialMode == .quit {
                let plan = QuitPlan(
                    id: UUID().uuidString,
                    userId: session.userId,
                    consumableItemId: item.id,
                    status: .active,
                    mode: .quit,
                    startDate: draft.quitStartDate,
                    baselineDailyConsume: draft.baselineDailyConsume,
                    baselineCostPerConsume: draft.baselineCostPerConsume,
                    templateId: RecoveryTemplateRegistry.defaultTemplateID(for: item.category),
                    category: item.category
                )

                try await userProfileRepository.saveQuitPlan(plan, scope: scope)
            }
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
