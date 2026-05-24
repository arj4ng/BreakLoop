// BreakLoop/ BreakLoop/ Shared/ Repositories/ FirebaseRepositoryProtocols.swift

// firebase repository protocols
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


// MARK: ┏━ [10 FIREBASE] Account Scope
// MARK: ┗━ trennt guest root von registrierten user docs

enum FirestoreAccountScope: Sendable {
    case guest
    case registered
}


// MARK: ┏━ [10 FIREBASE] User Data Snapshot
// MARK: ┗━ migration payload für export/import zwischen scopes

struct FirestoreUserDataSnapshot: Sendable {
    var profile: UserProfile?
    var consumableItems: [ConsumableItem]
    var consumeEntries: [ConsumeEntry]
    var purchaseEntries: [PurchaseEntry]
    var rewardEntries: [RewardEntry]
    var quitPlans: [QuitPlan]
    var quitPlanEvents: [QuitPlanEvent]
    var relapseEvents: [RelapseEvent]

    var hasAnyData: Bool {
        profile != nil ||
        !consumableItems.isEmpty ||
        !consumeEntries.isEmpty ||
        !purchaseEntries.isEmpty ||
        !rewardEntries.isEmpty ||
        !quitPlans.isEmpty ||
        !quitPlanEvents.isEmpty ||
        !relapseEvents.isEmpty
    }
}


// MARK: ┏━ [10 FIREBASE] Repository Protocols
// MARK: ┗━ firestore vorbereitete contracts, implementierung folgt später

protocol UserProfileRepositoryProtocol {

    // lädt profil aus users/{userId}
    func fetchUserProfile(userId: String) async throws -> UserProfile?

    // upsert profil in users/{userId}
    func saveUserProfile(_ profile: UserProfile) async throws
}

protocol ConsumableItemRepositoryProtocol {

    // lädt alle items aus users/{userId}/consumableItems
    func fetchConsumableItems(userId: String) async throws -> [ConsumableItem]

    // upsert einzelnes item
    func saveConsumableItem(_ item: ConsumableItem) async throws

    // soft archive statt löschen
    func archiveConsumableItem(userId: String, itemId: String) async throws
}

protocol ConsumeEntryRepositoryProtocol {

    // lädt consume logs aus subcollection
    func fetchConsumeEntries(userId: String) async throws -> [ConsumeEntry]

    // speichert neuen oder editierten consume log
    func saveConsumeEntry(_ entry: ConsumeEntry) async throws

    // setzt soft delete flags
    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date) async throws
}

protocol PurchaseEntryRepositoryProtocol {

    // lädt kauf logs aus subcollection
    func fetchPurchaseEntries(userId: String) async throws -> [PurchaseEntry]

    // speichert neuen oder editierten kauf log
    func savePurchaseEntry(_ entry: PurchaseEntry) async throws

    // setzt soft delete flags
    func softDeletePurchaseEntry(userId: String, entryId: String, deletedAt: Date) async throws
}

protocol RewardEntryRepositoryProtocol {

    // lädt reward historie aus subcollection
    func fetchRewardEntries(userId: String) async throws -> [RewardEntry]

    // schreibt reward event in historie
    func saveRewardEntry(_ entry: RewardEntry) async throws
}

protocol QuitPlanRepositoryProtocol {

    // lädt quit plans aus subcollection
    func fetchQuitPlans(userId: String, scope: FirestoreAccountScope) async throws -> [QuitPlan]

    // speichert quit plan im passenden scope
    func saveQuitPlan(_ plan: QuitPlan, scope: FirestoreAccountScope) async throws

    // schreibt quit event history
    func saveQuitPlanEvent(_ event: QuitPlanEvent, scope: FirestoreAccountScope) async throws

    // schreibt relapse event und optional consume log nach erfolgreichem statuswechsel
    func recordRelapse(
        plan: QuitPlan,
        amount: Double?,
        unit: ConsumeUnit?,
        reason: String?,
        createsConsumeEntry: Bool,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlanRelapseResult

    // soft archive statt löschen
    func archiveQuitPlan(userId: String, planId: String, archivedAt: Date, scope: FirestoreAccountScope) async throws
}


// MARK: ┏━ [10 FIREBASE] Migration Protocol
// MARK: ┗━ guest zu account datenfluss und snapshot helper

protocol UserDataMigrationRepositoryProtocol {

    // prüft ob target account noch keine tracking daten hat
    func isAccountDataEmpty(userId: String) async throws -> Bool

    // export aller tracking daten aus default scope
    func exportUserDataSnapshot(userId: String) async throws -> FirestoreUserDataSnapshot

    // import snapshot in target user default scope
    func importUserDataSnapshot(_ snapshot: FirestoreUserDataSnapshot, targetUserId: String) async throws
}
