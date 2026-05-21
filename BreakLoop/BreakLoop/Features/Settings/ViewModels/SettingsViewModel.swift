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
        trackName: String,
        trackAmountText: String,
        trackUnit: ConsumeUnit,
        usageMethod: ConsumableUsageMethod,
        costAmountPerTrackText: String,
        costUnit: ConsumeUnit,
        purchaseName: String,
        purchaseAmountText: String,
        purchaseUnit: ConsumeUnit,
        existingItem: ConsumableItem?
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTrackName = trackName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPurchaseName = purchaseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedTrackAmount = Double(trackAmountText.replacingOccurrences(of: ",", with: "."))
        let parsedCostAmount = Double(costAmountPerTrackText.replacingOccurrences(of: ",", with: "."))
        let parsedPurchaseAmount = Double(purchaseAmountText.replacingOccurrences(of: ",", with: "."))

        guard !trimmedName.isEmpty,
              !trimmedTrackName.isEmpty,
              let parsedTrackAmount,
              parsedTrackAmount > 0,
              let parsedCostAmount,
              parsedCostAmount > 0,
              let parsedPurchaseAmount,
              parsedPurchaseAmount > 0
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
            defaultUnit: trackUnit,
            usageMethod: usageMethod,
            pricingMode: .perPurchase,
            defaultPurchaseUnit: purchaseUnit,
            defaultAmountPerConsume: parsedTrackAmount,
            defaultUnitsPerPurchase: parsedPurchaseAmount,
            defaultCostPerConsume: nil,
            note: existingItem?.note,
            consumePresetName: consumePresetName,
            purchasePresetName: trimmedPurchaseName,
            trackName: trimmedTrackName,
            trackAmount: parsedTrackAmount,
            trackUnit: trackUnit,
            costAmountPerTrack: parsedCostAmount,
            costUnit: costUnit,
            purchaseName: trimmedPurchaseName,
            defaultPurchaseAmount: parsedPurchaseAmount,
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
