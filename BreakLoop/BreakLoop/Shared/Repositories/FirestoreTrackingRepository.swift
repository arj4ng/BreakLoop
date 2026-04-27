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
    RewardEntryRepositoryProtocol
{

    // zentrale firestore db instanz
    private let db: Firestore

    init(db: Firestore = .firestore()) {

        // firestore instanz injizierbar für tests
        self.db = db
    }


    // MARK: - user profile

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let snapshot = try await usersCollection().document(userId).getDocument()

        // nil wenn profil doc noch nicht existiert
        guard let data = snapshot.data() else { return nil }
        return userProfile(from: data, fallbackId: userId)
    }

    func saveUserProfile(_ profile: UserProfile) async throws {

        // merge true = update ohne felder blind zu löschen
        try await usersCollection().document(profile.id).setData(userProfileData(profile), merge: true)
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

    func archiveConsumableItem(userId: String, itemId: String) async throws {
        // soft archive damit history bleibt
        try await consumableItemsCollection(userId: userId)
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
        try await consumeEntriesCollection(userId: entry.userId)
            .document(entry.id)
            .setData(consumeEntryData(entry), merge: true)
    }

    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date) async throws {
        // soft delete flags statt hard remove
        try await consumeEntriesCollection(userId: userId)
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
        try await purchaseEntriesCollection(userId: entry.userId)
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


    // MARK: - paths

    private func usersCollection() -> CollectionReference {

        // root users collection
        db.collection(FirestorePath.users)
    }

    private func consumableItemsCollection(userId: String) -> CollectionReference {

        // subcollection pfad users/{uid}/consumableItems
        usersCollection().document(userId).collection(FirestorePath.consumableItems)
    }

    private func consumeEntriesCollection(userId: String) -> CollectionReference {

        // subcollection pfad users/{uid}/consumeEntries
        usersCollection().document(userId).collection(FirestorePath.consumeEntries)
    }

    private func purchaseEntriesCollection(userId: String) -> CollectionReference {

        // subcollection pfad users/{uid}/purchaseEntries
        usersCollection().document(userId).collection(FirestorePath.purchaseEntries)
    }

    private func rewardEntriesCollection(userId: String) -> CollectionReference {

        // subcollection pfad users/{uid}/rewardEntries
        usersCollection().document(userId).collection(FirestorePath.rewardEntries)
    }


    // MARK: - mapping encode

    private func userProfileData(_ value: UserProfile) -> [String: Any] {

        // encode modell zu firestore dictionary
        [
            "id": value.id,
            "email": value.email as Any,
            "displayName": value.displayName,
            "baselineDailyConsume": value.baselineDailyConsume,
            "baselineCostPerConsume": decimalToNumber(value.baselineCostPerConsume) as Any,
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
            "defaultAmountPerConsume": value.defaultAmountPerConsume as Any,
            "defaultCostPerConsume": decimalToNumber(value.defaultCostPerConsume) as Any,
            "note": value.note as Any,
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
            "reason": value.reason as Any,
            "createdAt": Timestamp(date: value.createdAt)
        ]
    }


    // MARK: - mapping decode

    private func userProfile(from data: [String: Any], fallbackId: String) -> UserProfile? {
        guard let displayName = data["displayName"] as? String else { return nil }

        let id = (data["id"] as? String) ?? fallbackId
        let email = data["email"] as? String
        let baselineDailyConsume = data["baselineDailyConsume"] as? Double ?? 0
        let baselineCostPerConsume = numberToDecimal(data["baselineCostPerConsume"])
        let onboardingCompleted = data["onboardingCompleted"] as? Bool ?? false
        let createdAt = timestampToDate(data["createdAt"]) ?? .now
        let updatedAt = timestampToDate(data["updatedAt"]) ?? .now

        // fallbackId verhindert crash bei fehlendem id feld
        return UserProfile(
            id: id,
            email: email,
            displayName: displayName,
            baselineDailyConsume: baselineDailyConsume,
            baselineCostPerConsume: baselineCostPerConsume,
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

        // guard schützt enum mapping gegen ungültige raw values
        return ConsumableItem(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            name: name,
            category: category,
            defaultUnit: defaultUnit,
            defaultAmountPerConsume: data["defaultAmountPerConsume"] as? Double,
            defaultCostPerConsume: numberToDecimal(data["defaultCostPerConsume"]),
            note: data["note"] as? String,
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
            reason: data["reason"] as? String,
            createdAt: timestampToDate(data["createdAt"]) ?? .now
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
    static let users = "users"
    static let consumableItems = "consumableItems"
    static let consumeEntries = "consumeEntries"
    static let purchaseEntries = "purchaseEntries"
    static let rewardEntries = "rewardEntries"
}
