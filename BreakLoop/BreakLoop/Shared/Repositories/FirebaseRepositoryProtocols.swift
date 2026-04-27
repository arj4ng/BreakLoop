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
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
}

protocol ConsumableItemRepositoryProtocol {
    func fetchConsumableItems(userId: String) async throws -> [ConsumableItem]
    func saveConsumableItem(_ item: ConsumableItem) async throws
    func archiveConsumableItem(userId: String, itemId: String) async throws
}

protocol ConsumeEntryRepositoryProtocol {
    func fetchConsumeEntries(userId: String) async throws -> [ConsumeEntry]
    func saveConsumeEntry(_ entry: ConsumeEntry) async throws
    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date) async throws
}

protocol PurchaseEntryRepositoryProtocol {
    func fetchPurchaseEntries(userId: String) async throws -> [PurchaseEntry]
    func savePurchaseEntry(_ entry: PurchaseEntry) async throws
    func softDeletePurchaseEntry(userId: String, entryId: String, deletedAt: Date) async throws
}

protocol RewardEntryRepositoryProtocol {
    func fetchRewardEntries(userId: String) async throws -> [RewardEntry]
    func saveRewardEntry(_ entry: RewardEntry) async throws
}
