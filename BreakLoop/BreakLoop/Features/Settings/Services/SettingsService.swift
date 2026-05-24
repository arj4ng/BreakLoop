// BreakLoop/ BreakLoop/ Features/ Settings/ Services/ SettingsService.swift

// Settings service
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

import Foundation


// MARK: ┏━ [12 SERVICES] SettingsServiceProtocol
// MARK: ┗━ settings service contract für use cases

protocol SettingsServiceProtocol {}

// settings braucht scoped crud, weil guest und user daten getrennt liegen
protocol SettingsConsumableServiceProtocol: SettingsServiceProtocol, QuitPlanRepositoryProtocol {
    func fetchConsumableItems(userId: String, scope: FirestoreAccountScope) async throws -> [ConsumableItem]
    func saveConsumableItem(_ item: ConsumableItem, scope: FirestoreAccountScope) async throws
    func archiveConsumableItem(userId: String, itemId: String, scope: FirestoreAccountScope) async throws
}

extension FirestoreTrackingRepository: SettingsConsumableServiceProtocol {
    func fetchConsumableItems(userId: String, scope: FirestoreAccountScope) async throws -> [ConsumableItem] {
        let snapshot = try await exportUserDataSnapshot(userId: userId, scope: scope)
        return snapshot.consumableItems
            .filter { !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
