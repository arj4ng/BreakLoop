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
import FirebaseAuth


// MARK: ┏━ [10 SETTINGS] SettingsViewModel
// MARK: ┗━ settings view model für screen state

// main actor: settings state wird direkt von SwiftUI gelesen
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var consumables: [ConsumableItem] = []
    @Published private(set) var quitPlans: [QuitPlan] = []
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
            async let loadedConsumables = service.fetchConsumableItems(userId: userId, scope: scope)
            async let loadedPlans = service.fetchQuitPlans(userId: userId, scope: scope)
            consumables = try await loadedConsumables
            quitPlans = try await loadedPlans
        } catch {
            message = error.localizedDescription
        }
    }

    func loadProfile() async {
        do {
            profile = try await service.fetchUserProfile(userId: userId, scope: scope)
        } catch {
            message = error.localizedDescription
        }
    }

    func saveProfile(displayName: String) async -> Bool {
        guard var profile else {
            message = "Profile not found"
            return false
        }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = "Name cannot be empty"
            return false
        }

        profile.displayName = trimmed
        profile.updatedAt = .now

        do {
            try await service.saveUserProfile(profile, scope: scope)
            self.profile = profile
            message = "Profile updated"
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        let current = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !current.isEmpty else {
            message = "Current password required"
            return false
        }

        guard newPassword.count >= 6 else {
            message = "New password must be at least 6 characters"
            return false
        }

        do {
            guard let user = Auth.auth().currentUser, let email = user.email else {
                message = "No signed-in account"
                return false
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: current)
            _ = try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            message = "Password updated"
            return true
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.wrongPassword.rawValue {
                message = "Current password is incorrect"
            } else if nsError.code == AuthErrorCode.weakPassword.rawValue {
                message = "New password is too weak"
            } else if nsError.code == AuthErrorCode.networkError.rawValue {
                message = "Network issue. Try again."
            } else {
                message = error.localizedDescription
            }
            return false
        }
    }

    func activeQuitPlan(for item: ConsumableItem) -> QuitPlan? {
        quitPlans
            .filter { !$0.isArchived && $0.consumableItemId == item.id }
            .filter { $0.status == .active || $0.status == .paused }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
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

    func startQuitPlan(for item: ConsumableItem) async {
        await startQuitPlan(for: item, startDate: .now)
    }

    func startQuitPlan(for item: ConsumableItem, startDate: Date) async {
        let plan = QuitPlan(
            id: UUID().uuidString,
            userId: userId,
            consumableItemId: item.id,
            status: .active,
            mode: .quit,
            startDate: startDate,
            baselineDailyConsume: nil,
            baselineCostPerConsume: item.defaultCostPerConsume,
            templateId: RecoveryTemplateRegistry.defaultTemplateID(for: item.category),
            category: item.category
        )

        do {
            try await service.saveQuitPlan(plan, scope: scope)
            message = "Quit plan started"
            await loadConsumables()
        } catch {
            message = error.localizedDescription
        }
    }

    func pauseQuitPlan(_ plan: QuitPlan) async {
        await updateQuitPlan(plan, status: .paused, note: "Plan paused", messageText: "Plan paused")
    }

    func resumeQuitPlan(_ plan: QuitPlan) async {
        await updateQuitPlan(plan, status: .active, note: "Plan resumed", messageText: "Plan resumed")
    }

    func endQuitPlan(_ plan: QuitPlan) async {
        await updateQuitPlan(plan, status: .completed, note: "Plan ended", messageText: "Plan ended")
    }

    func relapseQuitPlan(_ plan: QuitPlan) async {
        do {
            let service = QuitPlanService(repository: self.service)
            _ = try await service.relapse(
                plan: plan,
                amount: nil,
                unit: nil,
                reason: nil,
                createsConsumeEntry: false,
                scope: scope
            )
            message = "Relapse logged"
            await loadConsumables()
        } catch {
            message = error.localizedDescription
        }
    }

    private func updateQuitPlan(_ plan: QuitPlan, status: QuitPlanStatus, note: String, messageText: String) async {
        do {
            let service = QuitPlanService(repository: self.service)
            _ = try await service.transition(plan: plan, to: status, note: note, scope: scope)
            message = messageText
            await loadConsumables()
        } catch {
            message = error.localizedDescription
        }
    }
}
