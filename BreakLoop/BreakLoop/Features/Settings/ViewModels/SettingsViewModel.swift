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
    func saveConsumable(
        name: String,
        category: ConsumableCategory,
        consumePresetName: String,
        defaultAmountPerConsumeText: String,
        defaultUnit: ConsumeUnit,
        usageMethod: ConsumableUsageMethod,
        purchasePresetName: String,
        defaultPurchaseUnit: ConsumeUnit,
        defaultUnitsPerPurchaseText: String,
        existingItem: ConsumableItem?
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmountPerConsume = Double(defaultAmountPerConsumeText.replacingOccurrences(of: ",", with: "."))
        let parsedUnitsPerPurchase = Double(defaultUnitsPerPurchaseText.replacingOccurrences(of: ",", with: "."))

        guard !trimmedName.isEmpty,
              let parsedAmountPerConsume,
              parsedAmountPerConsume > 0,
              let parsedUnitsPerPurchase,
              parsedUnitsPerPurchase > 0
        else {
            message = "Check consumable form"
            return false
        }

        let now = Date()
        let item = ConsumableItem(
            id: existingItem?.id ?? UUID().uuidString,
            userId: userId,
            name: trimmedName,
            category: category,
            defaultUnit: defaultUnit,
            usageMethod: usageMethod,
            pricingMode: .perPurchase,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultAmountPerConsume: parsedAmountPerConsume,
            defaultUnitsPerPurchase: parsedUnitsPerPurchase,
            defaultCostPerConsume: existingItem?.defaultCostPerConsume,
            note: existingItem?.note,
            consumePresetName: consumePresetName,
            purchasePresetName: purchasePresetName.trimmingCharacters(in: .whitespacesAndNewlines),
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
