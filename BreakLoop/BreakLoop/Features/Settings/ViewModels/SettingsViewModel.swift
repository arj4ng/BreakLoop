// BreakLoop/ BreakLoop/ Features/ Settings/ ViewModels/ SettingsViewModel.swift

// Settings view model
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
import Combine


// MARK: ┏━ [10 SETTINGS] SettingsViewModel
// MARK: ┗━ settings view model für screen state

// main actor: settings state wird direkt von SwiftUI gelesen
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var consumables: [ConsumableItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?

    private let userId: String
    private let scope: FirestoreAccountScope
    private let service: SettingsConsumableServiceProtocol

    init(
        userId: String,
        scope: FirestoreAccountScope,
        service: SettingsConsumableServiceProtocol? = nil
    ) {
        self.userId = userId
        self.scope = scope
        self.service = service ?? FirestoreTrackingRepository()
    }

    func loadConsumables() async {
        isLoading = true
        defer { isLoading = false }

        do {
            consumables = try await service.fetchConsumableItems(userId: userId, scope: scope)
        } catch {
            message = error.localizedDescription
        }
    }

    // async: Firestore save wartet ohne ui thread zu blockieren
    func saveConsumable(draft: ConsumableFormDraft, existingItem: ConsumableItem?) async -> Bool {
        guard draft.isValid else {
            message = "Check consumable form"
            return false
        }

        let now = Date()
        let item = ConsumableItem(
            id: existingItem?.id ?? UUID().uuidString,
            userId: userId,
            name: draft.trimmedName,
            category: draft.category,
            defaultUnit: draft.defaultUnit,
            usageMethod: draft.usageMethod,
            pricingMode: draft.pricingMode,
            defaultPurchaseUnit: draft.pricingMode == .perPurchase ? draft.defaultPurchaseUnit : nil,
            defaultAmountPerConsume: existingItem?.defaultAmountPerConsume ?? 1,
            defaultUnitsPerPurchase: draft.pricingMode == .perPurchase ? draft.parsedUnitsPerPurchase : nil,
            defaultCostPerConsume: existingItem?.defaultCostPerConsume,
            note: existingItem?.note,
            createdAt: existingItem?.createdAt ?? now,
            updatedAt: now,
            isArchived: false
        )

        do {
            try await service.saveConsumableItem(item, scope: scope)
            message = existingItem == nil ? "Consumable added" : "Consumable updated"
            await loadConsumables()
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    // archive statt löschen hält alte logs erklärbar
    func archiveConsumable(_ item: ConsumableItem) async {
        do {
            try await service.archiveConsumableItem(userId: userId, itemId: item.id, scope: scope)
            message = "Consumable removed"
            await loadConsumables()
        } catch {
            message = error.localizedDescription
        }
    }
}
