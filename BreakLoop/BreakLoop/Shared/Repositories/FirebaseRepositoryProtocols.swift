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
