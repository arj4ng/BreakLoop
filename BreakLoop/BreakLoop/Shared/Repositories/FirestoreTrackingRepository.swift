// BreakLoop/ BreakLoop/ Shared/ Repositories/ FirestoreTrackingRepository.swift

// firestore tracking repository
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
import FirebaseFirestore


// MARK: ┏━ [10 FIREBASE] FirestoreTrackingRepository
// MARK: ┗━ firestore crud für profile, items, consume, purchase, rewards

final class FirestoreTrackingRepository:
    UserProfileRepositoryProtocol,
    ConsumableItemRepositoryProtocol,
    ConsumeEntryRepositoryProtocol,
    PurchaseEntryRepositoryProtocol,
    RewardEntryRepositoryProtocol,
    QuitPlanRepositoryProtocol,
    UserDataMigrationRepositoryProtocol
{

    // zentrale firestore db instanz
    private let db: Firestore

    init(db: Firestore = .firestore()) {

        // firestore instanz injizierbar für tests
        self.db = db
    }


    // MARK: - user profile

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let snapshot = try await usersCollection(scope: .registered).document(userId).getDocument()

        // nil wenn profil doc noch nicht existiert
        guard let data = snapshot.data() else { return nil }
        return userProfile(from: data, fallbackId: userId)
    }

    func saveUserProfile(_ profile: UserProfile) async throws {

        // merge true = update ohne felder blind zu löschen
        try await usersCollection(scope: .registered).document(profile.id).setData(userProfileData(profile), merge: true)
    }


    // MARK: - consumable items

    func fetchConsumableItems(userId: String) async throws -> [ConsumableItem] {
        let snapshot = try await consumableItemsCollection(userId: userId)
            .whereField("isArchived", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        // compactMap droppt defekte docs statt hard fail
        return snapshot.documents.compactMap {
            consumableItem(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
    }

    func saveConsumableItem(_ item: ConsumableItem) async throws {
        // doc id bleibt model id für stabile referenzen
        try await consumableItemsCollection(userId: item.userId)
            .document(item.id)
            .setData(consumableItemData(item), merge: true)
    }

    func saveConsumableItem(_ item: ConsumableItem, scope: FirestoreAccountScope) async throws {
        try await consumableItemsCollection(userId: item.userId, scope: scope)
            .document(item.id)
            .setData(consumableItemData(item), merge: true)
    }

    func archiveConsumableItem(userId: String, itemId: String) async throws {
        try await archiveConsumableItem(userId: userId, itemId: itemId, scope: .registered)
    }

    func archiveConsumableItem(userId: String, itemId: String, scope: FirestoreAccountScope) async throws {
        // soft archive damit history bleibt
        try await consumableItemsCollection(userId: userId, scope: scope)
            .document(itemId)
            .updateData([
                "isArchived": true,
                "updatedAt": Timestamp(date: .now)
            ])
    }


    // MARK: - consume entries

    func fetchConsumeEntries(userId: String) async throws -> [ConsumeEntry] {
        let snapshot = try await consumeEntriesCollection(userId: userId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .getDocuments()

        // nur aktive logs für calculations laden
        return snapshot.documents.compactMap {
            consumeEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
    }

    func saveConsumeEntry(_ entry: ConsumeEntry) async throws {
        try await saveConsumeEntry(entry, scope: .registered)
    }

    func saveConsumeEntry(_ entry: ConsumeEntry, scope: FirestoreAccountScope) async throws {
        // scope entscheidet zwischen users/{uid} und guestUsers/{uid}
        try await consumeEntriesCollection(userId: entry.userId, scope: scope)
            .document(entry.id)
            .setData(consumeEntryData(entry), merge: true)
    }

    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date) async throws {
        try await softDeleteConsumeEntry(userId: userId, entryId: entryId, deletedAt: deletedAt, scope: .registered)
    }

    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date, scope: FirestoreAccountScope) async throws {
        // soft delete flags statt hard remove
        try await consumeEntriesCollection(userId: userId, scope: scope)
            .document(entryId)
            .updateData([
                "isDeleted": true,
                "deletedAt": Timestamp(date: deletedAt),
                "updatedAt": Timestamp(date: deletedAt)
            ])
    }


    // MARK: - purchase entries

    func fetchPurchaseEntries(userId: String) async throws -> [PurchaseEntry] {
        let snapshot = try await purchaseEntriesCollection(userId: userId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "purchaseDate", descending: true)
            .getDocuments()

        // nur aktive kauf logs für cost logic laden
        return snapshot.documents.compactMap {
            purchaseEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
    }

    func savePurchaseEntry(_ entry: PurchaseEntry) async throws {
        try await savePurchaseEntry(entry, scope: .registered)
    }

    func savePurchaseEntry(_ entry: PurchaseEntry, scope: FirestoreAccountScope) async throws {
        // scope hält guest logs getrennt von registrierten account logs
        try await purchaseEntriesCollection(userId: entry.userId, scope: scope)
            .document(entry.id)
            .setData(purchaseEntryData(entry), merge: true)
    }

    func softDeletePurchaseEntry(userId: String, entryId: String, deletedAt: Date) async throws {
        // soft delete flags statt hard remove
        try await purchaseEntriesCollection(userId: userId)
            .document(entryId)
            .updateData([
                "isDeleted": true,
                "deletedAt": Timestamp(date: deletedAt),
                "updatedAt": Timestamp(date: deletedAt)
            ])
    }


    // MARK: - reward entries

    func fetchRewardEntries(userId: String) async throws -> [RewardEntry] {
        let snapshot = try await rewardEntriesCollection(userId: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        // newest first für rewards timeline ui
        return snapshot.documents.compactMap {
            rewardEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
    }

    func saveRewardEntry(_ entry: RewardEntry) async throws {
        try await rewardEntriesCollection(userId: entry.userId)
            .document(entry.id)
            .setData(rewardEntryData(entry), merge: true)
    }


    // MARK: - quit plans

    func fetchQuitPlans(userId: String, scope: FirestoreAccountScope) async throws -> [QuitPlan] {
        let snapshot = try await quitPlansCollection(userId: userId, scope: scope)
            .whereField("isArchived", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap {
            quitPlan(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
    }

    func saveQuitPlan(_ plan: QuitPlan, scope: FirestoreAccountScope) async throws {
        try await quitPlansCollection(userId: plan.userId, scope: scope)
            .document(plan.id)
            .setData(quitPlanData(plan), merge: true)
    }

    func saveQuitPlanEvent(_ event: QuitPlanEvent, scope: FirestoreAccountScope) async throws {
        try await quitPlanEventsCollection(userId: event.userId, scope: scope)
            .document(event.id)
            .setData(quitPlanEventData(event), merge: true)
    }

    func recordRelapse(
        plan: QuitPlan,
        amount: Double?,
        unit: ConsumeUnit?,
        reason: String?,
        createsConsumeEntry: Bool,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlanRelapseResult {
        guard plan.status == .relapsed else {
            throw NSError(
                domain: "BreakLoop.QuitPlan",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Relapse requires relapsed plan"]
            )
        }

        let now = Date()
        try await saveQuitPlan(plan, scope: scope)

        let consumeEntry: ConsumeEntry?
        if createsConsumeEntry,
           let amount,
           amount > 0,
           let unit {
            let entry = ConsumeEntry(
                id: UUID().uuidString,
                userId: plan.userId,
                consumableItemId: plan.consumableItemId,
                timestamp: now,
                amount: amount,
                unit: unit
            )
            try await saveConsumeEntry(entry, scope: scope)
            consumeEntry = entry
        } else {
            consumeEntry = nil
        }

        let relapse = RelapseEvent(
            id: UUID().uuidString,
            userId: plan.userId,
            consumableItemId: plan.consumableItemId,
            quitPlanId: plan.id,
            timestamp: now,
            amount: amount,
            unit: unit,
            reason: reason,
            createdConsumeEntryId: consumeEntry?.id,
            createdAt: now,
            updatedAt: now
        )
        try await relapseEventsCollection(userId: plan.userId, scope: scope)
            .document(relapse.id)
            .setData(relapseEventData(relapse), merge: true)

        let event = QuitPlanEvent(
            id: UUID().uuidString,
            userId: plan.userId,
            consumableItemId: plan.consumableItemId,
            quitPlanId: plan.id,
            type: .note,
            timestamp: now,
            note: "Relapse logged",
            createdAt: now,
            updatedAt: now
        )
        try await saveQuitPlanEvent(event, scope: scope)

        return QuitPlanRelapseResult(
            plan: plan,
            event: event,
            relapse: relapse,
            consumeEntry: consumeEntry
        )
    }

    func archiveQuitPlan(userId: String, planId: String, archivedAt: Date, scope: FirestoreAccountScope) async throws {
        try await quitPlansCollection(userId: userId, scope: scope)
            .document(planId)
            .updateData([
                "status": QuitPlanStatus.archived.rawValue,
                "isArchived": true,
                "updatedAt": Timestamp(date: archivedAt)
            ])
    }

    func fetchUserProfile(userId: String, scope: FirestoreAccountScope) async throws -> UserProfile? {
        let snapshot = try await usersCollection(scope: scope).document(userId).getDocument()
        guard let data = snapshot.data() else { return nil }
        return userProfile(from: data, fallbackId: userId)
    }

    func saveUserProfile(_ profile: UserProfile, scope: FirestoreAccountScope) async throws {
        try await usersCollection(scope: scope).document(profile.id).setData(userProfileData(profile), merge: true)
    }


    // MARK: - migration helpers

    func isAccountDataEmpty(userId: String) async throws -> Bool {
        let snapshot = try await exportUserDataSnapshot(userId: userId, scope: .registered)
        return !snapshot.hasAnyData
    }

    func exportUserDataSnapshot(userId: String) async throws -> FirestoreUserDataSnapshot {
        try await exportUserDataSnapshot(userId: userId, scope: .registered)
    }

    func exportUserDataSnapshot(userId: String, scope: FirestoreAccountScope) async throws -> FirestoreUserDataSnapshot {
        async let profile = fetchUserProfile(userId: userId, scope: scope)
        async let itemsDocs = consumableItemsCollection(userId: userId, scope: scope).getDocuments()
        async let consumeDocs = consumeEntriesCollection(userId: userId, scope: scope).getDocuments()
        async let purchaseDocs = purchaseEntriesCollection(userId: userId, scope: scope).getDocuments()
        async let rewardDocs = rewardEntriesCollection(userId: userId, scope: scope).getDocuments()
        async let quitPlanDocs = quitPlansCollection(userId: userId, scope: scope).getDocuments()
        async let quitEventDocs = quitPlanEventsCollection(userId: userId, scope: scope).getDocuments()
        async let relapseDocs = relapseEventsCollection(userId: userId, scope: scope).getDocuments()

        let itemModels = try await itemsDocs.documents.compactMap {
            consumableItem(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let consumeModels = try await consumeDocs.documents.compactMap {
            consumeEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let purchaseModels = try await purchaseDocs.documents.compactMap {
            purchaseEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let rewardModels = try await rewardDocs.documents.compactMap {
            rewardEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let quitPlanModels = try await quitPlanDocs.documents.compactMap {
            quitPlan(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let quitEventModels = try await quitEventDocs.documents.compactMap {
            quitPlanEvent(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }
        let relapseModels = try await relapseDocs.documents.compactMap {
            relapseEvent(from: $0.data(), fallbackId: $0.documentID, userId: userId)
        }

        return FirestoreUserDataSnapshot(
            profile: try await profile,
            consumableItems: itemModels,
            consumeEntries: consumeModels,
            purchaseEntries: purchaseModels,
            rewardEntries: rewardModels,
            quitPlans: quitPlanModels,
            quitPlanEvents: quitEventModels,
            relapseEvents: relapseModels
        )
    }

    func importUserDataSnapshot(_ snapshot: FirestoreUserDataSnapshot, targetUserId: String) async throws {
        try await importUserDataSnapshot(snapshot, targetUserId: targetUserId, targetScope: .registered)
    }

    func importUserDataSnapshot(
        _ snapshot: FirestoreUserDataSnapshot,
        targetUserId: String,
        targetScope: FirestoreAccountScope
    ) async throws {
        guard snapshot.hasAnyData else { return }

        if let profile = snapshot.profile {
            let migratedProfile = UserProfile(
                id: targetUserId,
                email: profile.email,
                displayName: profile.displayName,
                preferredCurrencyCode: profile.preferredCurrencyCode,
                baselineDailyConsume: profile.baselineDailyConsume,
                baselineCostPerConsume: profile.baselineCostPerConsume,
                isGuestAccount: false,
                onboardingCompleted: profile.onboardingCompleted,
                createdAt: profile.createdAt,
                updatedAt: .now
            )

            try await saveUserProfile(migratedProfile, scope: targetScope)
        }

        for item in snapshot.consumableItems {
            let migrated = ConsumableItem(
                id: item.id,
                userId: targetUserId,
                name: item.name,
                category: item.category,
                defaultUnit: item.defaultUnit,
                usageMethod: item.usageMethod,
                pricingMode: item.pricingMode,
                defaultPurchaseUnit: item.defaultPurchaseUnit,
                defaultAmountPerConsume: item.defaultAmountPerConsume,
                defaultUnitsPerPurchase: item.defaultUnitsPerPurchase,
                defaultCostPerConsume: item.defaultCostPerConsume,
                note: item.note,
                consumePresetName: item.consumePresetName,
                purchasePresetName: item.purchasePresetName,
                trackName: item.trackName,
                trackAmount: item.trackAmount,
                trackUnit: item.trackUnit,
                costAmountPerTrack: item.costAmountPerTrack,
                costUnit: item.costUnit,
                purchaseName: item.purchaseName,
                defaultPurchaseAmount: item.defaultPurchaseAmount,
                createdAt: item.createdAt,
                updatedAt: .now,
                isArchived: item.isArchived
            )
            try await consumableItemsCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(consumableItemData(migrated), merge: true)
        }

        for entry in snapshot.consumeEntries {
            let migrated = ConsumeEntry(
                id: entry.id,
                userId: targetUserId,
                consumableItemId: entry.consumableItemId,
                timestamp: entry.timestamp,
                amount: entry.amount,
                unit: entry.unit,
                note: entry.note,
                trigger: entry.trigger,
                cravingLevel: entry.cravingLevel,
                createdAt: entry.createdAt,
                updatedAt: .now,
                isDeleted: entry.isDeleted,
                deletedAt: entry.deletedAt
            )
            try await consumeEntriesCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(consumeEntryData(migrated), merge: true)
        }

        for entry in snapshot.purchaseEntries {
            let migrated = PurchaseEntry(
                id: entry.id,
                userId: targetUserId,
                consumableItemId: entry.consumableItemId,
                purchaseDate: entry.purchaseDate,
                price: entry.price,
                quantity: entry.quantity,
                unit: entry.unit,
                calculatedCostPerUnit: entry.calculatedCostPerUnit,
                productName: entry.productName,
                note: entry.note,
                createdAt: entry.createdAt,
                updatedAt: .now,
                isDeleted: entry.isDeleted,
                deletedAt: entry.deletedAt
            )
            try await purchaseEntriesCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(purchaseEntryData(migrated), merge: true)
        }

        for entry in snapshot.rewardEntries {
            let migrated = RewardEntry(
                id: entry.id,
                userId: targetUserId,
                consumableItemId: entry.consumableItemId,
                type: entry.type,
                points: entry.points,
                periodKey: entry.periodKey,
                reason: entry.reason,
                createdAt: entry.createdAt
            )
            try await rewardEntriesCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(rewardEntryData(migrated), merge: true)
        }

        for plan in snapshot.quitPlans {
            let migrated = QuitPlan(
                id: plan.id,
                userId: targetUserId,
                consumableItemId: plan.consumableItemId,
                status: plan.status,
                mode: plan.mode,
                startDate: plan.startDate,
                targetDate: plan.targetDate,
                baselineDailyConsume: plan.baselineDailyConsume,
                baselineCostPerConsume: plan.baselineCostPerConsume,
                templateId: plan.templateId,
                category: plan.category,
                createdAt: plan.createdAt,
                updatedAt: .now,
                isArchived: plan.isArchived
            )
            try await quitPlansCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(quitPlanData(migrated), merge: true)
        }

        for event in snapshot.quitPlanEvents {
            let migrated = QuitPlanEvent(
                id: event.id,
                userId: targetUserId,
                consumableItemId: event.consumableItemId,
                quitPlanId: event.quitPlanId,
                type: event.type,
                timestamp: event.timestamp,
                value: event.value,
                note: event.note,
                createdAt: event.createdAt,
                updatedAt: .now,
                isArchived: event.isArchived
            )
            try await quitPlanEventsCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(quitPlanEventData(migrated), merge: true)
        }

        for relapse in snapshot.relapseEvents {
            let migrated = RelapseEvent(
                id: relapse.id,
                userId: targetUserId,
                consumableItemId: relapse.consumableItemId,
                quitPlanId: relapse.quitPlanId,
                timestamp: relapse.timestamp,
                amount: relapse.amount,
                unit: relapse.unit,
                reason: relapse.reason,
                createdConsumeEntryId: relapse.createdConsumeEntryId,
                createdAt: relapse.createdAt,
                updatedAt: .now,
                isArchived: relapse.isArchived
            )
            try await relapseEventsCollection(userId: targetUserId, scope: targetScope)
                .document(migrated.id)
                .setData(relapseEventData(migrated), merge: true)
        }
    }


    // MARK: - paths

    private func usersCollection(scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // root users collection
        switch scope {
        case .guest:
            db.collection(FirestorePath.guestUsers)
        case .registered:
            db.collection(FirestorePath.users)
        }
    }

    private func consumableItemsCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/consumableItems
        usersCollection(scope: scope).document(userId).collection(FirestorePath.consumableItems)
    }

    private func consumeEntriesCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/consumeEntries
        usersCollection(scope: scope).document(userId).collection(FirestorePath.consumeEntries)
    }

    private func purchaseEntriesCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/purchaseEntries
        usersCollection(scope: scope).document(userId).collection(FirestorePath.purchaseEntries)
    }

    private func rewardEntriesCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/rewardEntries
        usersCollection(scope: scope).document(userId).collection(FirestorePath.rewardEntries)
    }

    private func quitPlansCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/quitPlans
        usersCollection(scope: scope).document(userId).collection(FirestorePath.quitPlans)
    }

    private func quitPlanEventsCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/quitPlanEvents
        usersCollection(scope: scope).document(userId).collection(FirestorePath.quitPlanEvents)
    }

    private func relapseEventsCollection(userId: String, scope: FirestoreAccountScope = .registered) -> CollectionReference {

        // subcollection pfad users/{uid}/relapseEvents
        usersCollection(scope: scope).document(userId).collection(FirestorePath.relapseEvents)
    }


    // MARK: - mapping encode

    private func userProfileData(_ value: UserProfile) -> [String: Any] {

        // encode modell zu firestore dictionary
        [
            "id": value.id,
            "email": value.email as Any,
            "displayName": value.displayName,
            "preferredCurrencyCode": value.preferredCurrencyCode,
            "baselineDailyConsume": value.baselineDailyConsume,
            "baselineCostPerConsume": decimalToNumber(value.baselineCostPerConsume) as Any,
            "isGuestAccount": value.isGuestAccount,
            "onboardingCompleted": value.onboardingCompleted,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt)
        ]
    }

    private func consumableItemData(_ value: ConsumableItem) -> [String: Any] {

        // enums als rawValue speichern für einfache queries
        [
            "id": value.id,
            "userId": value.userId,
            "name": value.name,
            "category": value.category.rawValue,
            "defaultUnit": value.defaultUnit.rawValue,
            "usageMethod": value.usageMethod.rawValue,
            "pricingMode": value.pricingMode.rawValue,
            "defaultPurchaseUnit": value.defaultPurchaseUnit?.rawValue as Any,
            "defaultAmountPerConsume": value.defaultAmountPerConsume as Any,
            "defaultUnitsPerPurchase": value.defaultUnitsPerPurchase as Any,
            "defaultCostPerConsume": decimalToNumber(value.defaultCostPerConsume) as Any,
            "note": value.note as Any,
            "consumePresetName": value.consumePresetName as Any,
            "purchasePresetName": value.purchasePresetName as Any,
            "trackName": value.trackName as Any,
            "trackAmount": value.trackAmount as Any,
            "trackUnit": value.trackUnit?.rawValue as Any,
            "costAmountPerTrack": value.costAmountPerTrack as Any,
            "costUnit": value.costUnit?.rawValue as Any,
            "purchaseName": value.purchaseName as Any,
            "defaultPurchaseAmount": value.defaultPurchaseAmount as Any,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isArchived": value.isArchived
        ]
    }

    private func consumeEntryData(_ value: ConsumeEntry) -> [String: Any] {

        // dates werden als firestore timestamp gespeichert
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId,
            "timestamp": Timestamp(date: value.timestamp),
            "amount": value.amount,
            "unit": value.unit.rawValue,
            "note": value.note as Any,
            "trigger": value.trigger?.rawValue as Any,
            "cravingLevel": value.cravingLevel as Any,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isDeleted": value.isDeleted,
            "deletedAt": value.deletedAt.map { Timestamp(date: $0) } as Any
        ]
    }

    private func purchaseEntryData(_ value: PurchaseEntry) -> [String: Any] {

        // decimal felder als nummer für firestore kompatibilität
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId,
            "purchaseDate": Timestamp(date: value.purchaseDate),
            "price": decimalToNumber(value.price) as Any,
            "quantity": value.quantity,
            "unit": value.unit.rawValue,
            "calculatedCostPerUnit": decimalToNumber(value.calculatedCostPerUnit) as Any,
            "productName": value.productName as Any,
            "note": value.note as Any,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isDeleted": value.isDeleted,
            "deletedAt": value.deletedAt.map { Timestamp(date: $0) } as Any
        ]
    }

    private func rewardEntryData(_ value: RewardEntry) -> [String: Any] {

        // reward event minimal halten für timeline
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId as Any,
            "type": value.type.rawValue,
            "points": value.points,
            "periodKey": value.periodKey as Any,
            "reason": value.reason as Any,
            "createdAt": Timestamp(date: value.createdAt)
        ]
    }

    private func quitPlanData(_ value: QuitPlan) -> [String: Any] {

        // quit plan als raw firestore dictionary ohne swiftdata abhängigkeit
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId,
            "status": value.status.rawValue,
            "mode": value.mode.rawValue,
            "startDate": Timestamp(date: value.startDate),
            "targetDate": value.targetDate.map { Timestamp(date: $0) } as Any,
            "baselineDailyConsume": value.baselineDailyConsume as Any,
            "baselineCostPerConsume": decimalToNumber(value.baselineCostPerConsume) as Any,
            "templateId": value.templateId as Any,
            "category": value.category.rawValue,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isArchived": value.isArchived
        ]
    }

    private func quitPlanEventData(_ value: QuitPlanEvent) -> [String: Any] {

        // event history bleibt soft archivierbar
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId,
            "quitPlanId": value.quitPlanId,
            "type": value.type.rawValue,
            "timestamp": Timestamp(date: value.timestamp),
            "value": value.value as Any,
            "note": value.note as Any,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isArchived": value.isArchived
        ]
    }

    private func relapseEventData(_ value: RelapseEvent) -> [String: Any] {

        // optional consume id verbindet relapse mit normalem tracking log
        [
            "id": value.id,
            "userId": value.userId,
            "consumableItemId": value.consumableItemId,
            "quitPlanId": value.quitPlanId,
            "timestamp": Timestamp(date: value.timestamp),
            "amount": value.amount as Any,
            "unit": value.unit?.rawValue as Any,
            "reason": value.reason as Any,
            "createdConsumeEntryId": value.createdConsumeEntryId as Any,
            "createdAt": Timestamp(date: value.createdAt),
            "updatedAt": Timestamp(date: value.updatedAt),
            "isArchived": value.isArchived
        ]
    }


    // MARK: - mapping decode

    private func userProfile(from data: [String: Any], fallbackId: String) -> UserProfile? {
        guard let displayName = data["displayName"] as? String else { return nil }

        let id = (data["id"] as? String) ?? fallbackId
        let email = data["email"] as? String
        let preferredCurrencyCode = data["preferredCurrencyCode"] as? String ?? "EUR"
        let baselineDailyConsume = data["baselineDailyConsume"] as? Double ?? 0
        let baselineCostPerConsume = numberToDecimal(data["baselineCostPerConsume"])
        let isGuestAccount = data["isGuestAccount"] as? Bool ?? false
        let onboardingCompleted = data["onboardingCompleted"] as? Bool ?? false
        let createdAt = timestampToDate(data["createdAt"]) ?? .now
        let updatedAt = timestampToDate(data["updatedAt"]) ?? .now

        // fallbackId verhindert crash bei fehlendem id feld
        return UserProfile(
            id: id,
            email: email,
            displayName: displayName,
            preferredCurrencyCode: preferredCurrencyCode,
            baselineDailyConsume: baselineDailyConsume,
            baselineCostPerConsume: baselineCostPerConsume,
            isGuestAccount: isGuestAccount,
            onboardingCompleted: onboardingCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func consumableItem(from data: [String: Any], fallbackId: String, userId: String) -> ConsumableItem? {
        guard
            let name = data["name"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = ConsumableCategory(rawValue: categoryRaw),
            let unitRaw = data["defaultUnit"] as? String,
            let defaultUnit = ConsumeUnit(rawValue: unitRaw)
        else {
            return nil
        }

        let usageMethod: ConsumableUsageMethod
        if let usageRaw = data["usageMethod"] as? String,
           let mapped = ConsumableUsageMethod(rawValue: usageRaw) {
            usageMethod = mapped
        } else {
            usageMethod = .custom
        }

        let pricingMode: ConsumablePricingMode
        if let pricingRaw = data["pricingMode"] as? String,
           let mapped = ConsumablePricingMode(rawValue: pricingRaw) {
            pricingMode = mapped
        } else {
            pricingMode = .perUnit
        }

        let defaultPurchaseUnit: ConsumeUnit?
        if let purchaseRaw = data["defaultPurchaseUnit"] as? String {
            defaultPurchaseUnit = ConsumeUnit(rawValue: purchaseRaw)
        } else {
            defaultPurchaseUnit = nil
        }

        // guard schützt enum mapping gegen ungültige raw values
        return ConsumableItem(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            name: name,
            category: category,
            defaultUnit: defaultUnit,
            usageMethod: usageMethod,
            pricingMode: pricingMode,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultAmountPerConsume: data["defaultAmountPerConsume"] as? Double,
            defaultUnitsPerPurchase: data["defaultUnitsPerPurchase"] as? Double,
            defaultCostPerConsume: numberToDecimal(data["defaultCostPerConsume"]),
            note: data["note"] as? String,
            consumePresetName: data["consumePresetName"] as? String,
            purchasePresetName: data["purchasePresetName"] as? String,
            trackName: data["trackName"] as? String,
            trackAmount: data["trackAmount"] as? Double,
            trackUnit: (data["trackUnit"] as? String).flatMap(ConsumeUnit.init(rawValue:)),
            costAmountPerTrack: data["costAmountPerTrack"] as? Double,
            costUnit: (data["costUnit"] as? String).flatMap(ConsumeUnit.init(rawValue:)),
            purchaseName: data["purchaseName"] as? String,
            defaultPurchaseAmount: data["defaultPurchaseAmount"] as? Double,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isArchived: data["isArchived"] as? Bool ?? false
        )
    }

    private func consumeEntry(from data: [String: Any], fallbackId: String, userId: String) -> ConsumeEntry? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let unitRaw = data["unit"] as? String,
            let unit = ConsumeUnit(rawValue: unitRaw)
        else {
            return nil
        }

        // trigger bleibt optional wenn feld fehlt
        let trigger: TriggerType?
        if let raw = data["trigger"] as? String {
            trigger = TriggerType(rawValue: raw)
        } else {
            trigger = nil
        }

        return ConsumeEntry(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            timestamp: timestampToDate(data["timestamp"]) ?? .now,
            amount: data["amount"] as? Double ?? 0,
            unit: unit,
            note: data["note"] as? String,
            trigger: trigger,
            cravingLevel: data["cravingLevel"] as? Int,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            deletedAt: timestampToDate(data["deletedAt"])
        )
    }

    private func purchaseEntry(from data: [String: Any], fallbackId: String, userId: String) -> PurchaseEntry? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let unitRaw = data["unit"] as? String,
            let unit = ConsumeUnit(rawValue: unitRaw)
        else {
            return nil
        }

        // calculatedCostPerUnit kann fehlen und wird dann init neu gesetzt
        return PurchaseEntry(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            purchaseDate: timestampToDate(data["purchaseDate"]) ?? .now,
            price: numberToDecimal(data["price"]) ?? .zero,
            quantity: data["quantity"] as? Double ?? 0,
            unit: unit,
            calculatedCostPerUnit: numberToDecimal(data["calculatedCostPerUnit"]),
            productName: data["productName"] as? String,
            note: data["note"] as? String,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            deletedAt: timestampToDate(data["deletedAt"])
        )
    }

    private func rewardEntry(from data: [String: Any], fallbackId: String, userId: String) -> RewardEntry? {
        guard
            let typeRaw = data["type"] as? String,
            let type = RewardType(rawValue: typeRaw)
        else {
            return nil
        }

        // ungültiger reward type => doc wird ignoriert
        return RewardEntry(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: data["consumableItemId"] as? String,
            type: type,
            points: data["points"] as? Int ?? 0,
            periodKey: data["periodKey"] as? String,
            reason: data["reason"] as? String,
            createdAt: timestampToDate(data["createdAt"]) ?? .now
        )
    }

    private func quitPlan(from data: [String: Any], fallbackId: String, userId: String) -> QuitPlan? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = ConsumableCategory(rawValue: categoryRaw)
        else {
            return nil
        }

        let status = (data["status"] as? String).flatMap(QuitPlanStatus.init(rawValue:)) ?? .active
        let mode = (data["mode"] as? String).flatMap(QuitPlanMode.init(rawValue:)) ?? .quit

        return QuitPlan(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            status: status,
            mode: mode,
            startDate: timestampToDate(data["startDate"]) ?? .now,
            targetDate: timestampToDate(data["targetDate"]),
            baselineDailyConsume: data["baselineDailyConsume"] as? Double,
            baselineCostPerConsume: numberToDecimal(data["baselineCostPerConsume"]),
            templateId: data["templateId"] as? String,
            category: category,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isArchived: (data["isArchived"] as? Bool) ?? (status == .archived)
        )
    }

    private func quitPlanEvent(from data: [String: Any], fallbackId: String, userId: String) -> QuitPlanEvent? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let quitPlanId = data["quitPlanId"] as? String,
            let typeRaw = data["type"] as? String,
            let type = QuitPlanEventType(rawValue: typeRaw)
        else {
            return nil
        }

        return QuitPlanEvent(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            quitPlanId: quitPlanId,
            type: type,
            timestamp: timestampToDate(data["timestamp"]) ?? .now,
            value: data["value"] as? Double,
            note: data["note"] as? String,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isArchived: data["isArchived"] as? Bool ?? false
        )
    }

    private func relapseEvent(from data: [String: Any], fallbackId: String, userId: String) -> RelapseEvent? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let quitPlanId = data["quitPlanId"] as? String
        else {
            return nil
        }

        return RelapseEvent(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            quitPlanId: quitPlanId,
            timestamp: timestampToDate(data["timestamp"]) ?? .now,
            amount: data["amount"] as? Double,
            unit: (data["unit"] as? String).flatMap(ConsumeUnit.init(rawValue:)),
            reason: data["reason"] as? String,
            createdConsumeEntryId: data["createdConsumeEntryId"] as? String,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isArchived: data["isArchived"] as? Bool ?? false
        )
    }


    // MARK: - helpers

    private func timestampToDate(_ value: Any?) -> Date? {

        // akzeptiert timestamp und raw date für migrationsfälle
        if let ts = value as? Timestamp { return ts.dateValue() }
        if let date = value as? Date { return date }
        return nil
    }

    private func numberToDecimal(_ value: Any?) -> Decimal? {

        // unterstützt number, string und decimal inputs
        switch value {
        case let number as NSNumber:
            return number.decimalValue
        case let string as String:
            return Decimal(string: string)
        case let decimal as Decimal:
            return decimal
        default:
            return nil
        }
    }

    private func decimalToNumber(_ value: Decimal?) -> NSNumber? {
        guard let value else { return nil }

        // firestore schreibt decimal stabil als nsdecimalnumber
        return NSDecimalNumber(decimal: value)
    }
}


enum FirestorePath {
    static let guestUsers = "guestUsers"
    static let users = "users"
    static let consumableItems = "consumableItems"
    static let consumeEntries = "consumeEntries"
    static let purchaseEntries = "purchaseEntries"
    static let rewardEntries = "rewardEntries"
    static let quitPlans = "quitPlans"
    static let quitPlanEvents = "quitPlanEvents"
    static let relapseEvents = "relapseEvents"
}
