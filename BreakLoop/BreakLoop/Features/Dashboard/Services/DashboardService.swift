// BreakLoop/ BreakLoop/ Features/ Dashboard/ Services/ DashboardService.swift

// Dashboard service
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
import FirebaseFirestore


// MARK: ┏━ [12 SERVICES] DashboardServiceProtocol
// MARK: ┗━ dashboard service contract für use cases

protocol DashboardServiceProtocol {}

// bündelt alle firestore snapshots, die dashboard gleichzeitig braucht
struct DashboardRealtimePayload {
    var profile: UserProfile?
    var consumables: [ConsumableItem]
    var entries: [ConsumeEntry]
    var purchases: [PurchaseEntry]
    var rewards: [RewardEntry]
}

// realtime contract liefert listener zurück, damit viewmodel stoppen kann
protocol DashboardRealtimeServiceProtocol: DashboardServiceProtocol {
    func startRealtime(
        userId: String,
        scope: FirestoreAccountScope,
        onUpdate: @escaping (DashboardRealtimePayload) -> Void,
        onError: @escaping (Error) -> Void
    ) -> [ListenerRegistration]
}

// dashboard braucht nur entry writes, nicht komplettes repository interface
protocol DashboardEntryRepositoryProtocol {
    func saveConsumeEntry(_ entry: ConsumeEntry, scope: FirestoreAccountScope) async throws
    func savePurchaseEntry(_ entry: PurchaseEntry, scope: FirestoreAccountScope) async throws
    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date, scope: FirestoreAccountScope) async throws
}

extension FirestoreTrackingRepository: DashboardEntryRepositoryProtocol {}

// liest dashboard daten live aus mehreren firestore subcollections
final class FirestoreDashboardRealtimeService: DashboardRealtimeServiceProtocol {
    private let db: Firestore

    // db injizierbar für spätere tests oder emulator setup
    init(db: Firestore = .firestore()) {
        self.db = db
    }

    func startRealtime(
        userId: String,
        scope: FirestoreAccountScope,
        onUpdate: @escaping (DashboardRealtimePayload) -> Void,
        onError: @escaping (Error) -> Void
    ) -> [ListenerRegistration] {
        let base = usersCollection(scope: scope).document(userId)

        var profile: UserProfile?
        var consumables: [ConsumableItem] = []
        var entries: [ConsumeEntry] = []
        var purchases: [PurchaseEntry] = []
        var rewards: [RewardEntry] = []

        // jeder listener aktualisiert seinen teil und pusht dann kompletten stand
        func push() {
            onUpdate(
                DashboardRealtimePayload(
                    profile: profile,
                    consumables: consumables,
                    entries: entries,
                    purchases: purchases,
                    rewards: rewards
                )
            )
        }

        // profil liegt direkt im user doc
        let profileListener = base.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            profile = snapshot.flatMap { self.userProfile(from: $0.data(), fallbackId: userId) }
            push()
        }

        // aktive consumables für picker und kpi basis
        let consumableListener = base.collection(FirestorePath.consumableItems).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            consumables = snapshot?.documents.compactMap {
                self.consumableItem(from: $0.data(), fallbackId: $0.documentID, userId: userId)
            }.filter { !$0.isArchived } ?? []
            push()
        }

        // consume logs ohne soft deleted docs
        let consumeListener = base.collection(FirestorePath.consumeEntries).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            entries = snapshot?.documents.compactMap {
                self.consumeEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
            }.filter { !$0.isDeleted } ?? []
            push()
        }

        // purchase logs ohne soft deleted docs
        let purchaseListener = base.collection(FirestorePath.purchaseEntries).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            purchases = snapshot?.documents.compactMap {
                self.purchaseEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
            }.filter { !$0.isDeleted } ?? []
            push()
        }

        // reward historie für punkte im dashboard
        let rewardListener = base.collection(FirestorePath.rewardEntries).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }

            rewards = snapshot?.documents.compactMap {
                self.rewardEntry(from: $0.data(), fallbackId: $0.documentID, userId: userId)
            } ?? []
            push()
        }

        return [profileListener, consumableListener, consumeListener, purchaseListener, rewardListener]
    }

    // guest daten und account daten liegen in getrennten root collections
    private func usersCollection(scope: FirestoreAccountScope) -> CollectionReference {
        switch scope {
        case .guest:
            db.collection(FirestorePath.guestUsers)
        case .registered:
            db.collection(FirestorePath.users)
        }
    }

    // firestore dictionary -> user profile model
    private func userProfile(from data: [String: Any]?, fallbackId: String) -> UserProfile? {
        guard
            let data,
            let displayName = data["displayName"] as? String
        else {
            return nil
        }

        return UserProfile(
            id: (data["id"] as? String) ?? fallbackId,
            email: data["email"] as? String,
            displayName: displayName,
            preferredCurrencyCode: data["preferredCurrencyCode"] as? String ?? "EUR",
            baselineDailyConsume: data["baselineDailyConsume"] as? Double ?? 0,
            baselineCostPerConsume: numberToDecimal(data["baselineCostPerConsume"]),
            isGuestAccount: data["isGuestAccount"] as? Bool ?? false,
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now
        )
    }

    // firestore dictionary -> consumable item model
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

        let usageMethod = (data["usageMethod"] as? String).flatMap(ConsumableUsageMethod.init(rawValue:)) ?? .custom
        let pricingMode = (data["pricingMode"] as? String).flatMap(ConsumablePricingMode.init(rawValue:)) ?? .perUnit
        let defaultPurchaseUnit = (data["defaultPurchaseUnit"] as? String).flatMap(ConsumeUnit.init(rawValue:))

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

    // firestore dictionary -> consume entry model
    private func consumeEntry(from data: [String: Any], fallbackId: String, userId: String) -> ConsumeEntry? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let unitRaw = data["unit"] as? String,
            let unit = ConsumeUnit(rawValue: unitRaw)
        else {
            return nil
        }

        return ConsumeEntry(
            id: (data["id"] as? String) ?? fallbackId,
            userId: (data["userId"] as? String) ?? userId,
            consumableItemId: consumableItemId,
            timestamp: timestampToDate(data["timestamp"]) ?? .now,
            amount: data["amount"] as? Double ?? 0,
            unit: unit,
            note: data["note"] as? String,
            trigger: (data["trigger"] as? String).flatMap(TriggerType.init(rawValue:)),
            cravingLevel: data["cravingLevel"] as? Int,
            createdAt: timestampToDate(data["createdAt"]) ?? .now,
            updatedAt: timestampToDate(data["updatedAt"]) ?? .now,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            deletedAt: timestampToDate(data["deletedAt"])
        )
    }

    // firestore dictionary -> purchase entry model
    private func purchaseEntry(from data: [String: Any], fallbackId: String, userId: String) -> PurchaseEntry? {
        guard
            let consumableItemId = data["consumableItemId"] as? String,
            let unitRaw = data["unit"] as? String,
            let unit = ConsumeUnit(rawValue: unitRaw)
        else {
            return nil
        }

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

    // firestore dictionary -> reward entry model
    private func rewardEntry(from data: [String: Any], fallbackId: String, userId: String) -> RewardEntry? {
        guard
            let rawType = data["type"] as? String,
            let type = RewardType(rawValue: rawType)
        else {
            return nil
        }

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

    // firestore Timestamp und alte Date werte beide akzeptieren
    private func timestampToDate(_ value: Any?) -> Date? {
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        if let date = value as? Date { return date }
        return nil
    }

    // zahlen robust lesen, weil firestore decimal als verschiedene typen liefern kann
    private func numberToDecimal(_ value: Any?) -> Decimal? {
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
}
