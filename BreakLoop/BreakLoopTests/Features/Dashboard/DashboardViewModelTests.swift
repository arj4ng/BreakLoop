import XCTest
import FirebaseFirestore
@testable import BreakLoop

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testOneConsumableAutoSelectsAndHidesPicker() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(realtime: realtime, repository: repository)
        let item = makeItem(id: "coffee")

        viewModel.start()
        await realtime.send(consumables: [item])

        XCTAssertEqual(viewModel.selectedItem?.id, "coffee")
        XCTAssertFalse(viewModel.shouldShowConsumablePicker)
    }

    func testMultipleConsumablesShowsPicker() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(realtime: realtime, repository: repository)

        viewModel.start()
        await realtime.send(consumables: [makeItem(id: "coffee"), makeItem(id: "vape")])

        XCTAssertTrue(viewModel.shouldShowConsumablePicker)
    }

    func testQuickConsumeBuildsCorrectEntry() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(scope: .guest, realtime: realtime, repository: repository)
        let item = makeItem(id: "coffee", defaultUnit: .cup, defaultAmountPerConsume: 2)

        viewModel.start()
        await realtime.send(consumables: [item])
        await viewModel.quickLogConsume()

        XCTAssertEqual(repository.savedConsumes.count, 1)
        XCTAssertEqual(repository.savedConsumes.first?.entry.userId, "user-1")
        XCTAssertEqual(repository.savedConsumes.first?.entry.consumableItemId, "coffee")
        XCTAssertEqual(repository.savedConsumes.first?.entry.amount, 2)
        XCTAssertEqual(repository.savedConsumes.first?.entry.unit, .cup)
        XCTAssertEqual(repository.savedConsumes.first?.scope, .guest)
    }

    func testPurchaseSaveBuildsCorrectEntry() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(realtime: realtime, repository: repository)
        let item = makeItem(id: "vape", defaultUnit: .milliliter, defaultPurchaseUnit: .pack)

        viewModel.start()
        await realtime.send(consumables: [item])
        await viewModel.savePurchase(price: 12.50, quantity: 3, unit: .pack)

        XCTAssertEqual(repository.savedPurchases.count, 1)
        XCTAssertEqual(repository.savedPurchases.first?.entry.userId, "user-1")
        XCTAssertEqual(repository.savedPurchases.first?.entry.consumableItemId, "vape")
        XCTAssertEqual(repository.savedPurchases.first?.entry.price, 12.50)
        XCTAssertEqual(repository.savedPurchases.first?.entry.quantity, 3)
        XCTAssertEqual(repository.savedPurchases.first?.entry.unit, .pack)
        XCTAssertEqual(repository.savedPurchases.first?.scope, .registered)
    }

    func testUndoSoftDeletesLastQuickConsume() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(scope: .guest, realtime: realtime, repository: repository)

        viewModel.start()
        await realtime.send(consumables: [makeItem(id: "coffee")])
        await viewModel.quickLogConsume()
        await viewModel.undoLastQuickConsume()

        XCTAssertEqual(repository.deletedConsumes.count, 1)
        XCTAssertEqual(repository.deletedConsumes.first?.userId, "user-1")
        XCTAssertEqual(repository.deletedConsumes.first?.entryId, repository.savedConsumes.first?.entry.id)
        XCTAssertEqual(repository.deletedConsumes.first?.scope, .guest)
    }

    func testSelectedActiveQuitPlanMatchesSelectedConsumable() async {
        let realtime = DashboardRealtimeServiceFake()
        let repository = DashboardEntryRepositoryFake()
        let viewModel = makeViewModel(realtime: realtime, repository: repository)
        let coffee = makeItem(id: "coffee")
        let vape = makeItem(id: "vape")
        let plan = QuitPlan(
            id: "plan-vape",
            userId: "user-1",
            consumableItemId: "vape",
            status: .active,
            category: .nicotine
        )

        viewModel.start()
        await realtime.send(consumables: [coffee, vape], quitPlans: [plan])
        viewModel.selectConsumable(id: "vape")

        XCTAssertEqual(viewModel.state.selectedActiveQuitPlan?.id, "plan-vape")
    }

    private func makeViewModel(
        scope: FirestoreAccountScope = .registered,
        realtime: DashboardRealtimeServiceFake,
        repository: DashboardEntryRepositoryFake
    ) -> DashboardViewModel {
        DashboardViewModel(
            userId: "user-1",
            scope: scope,
            realtimeService: realtime,
            entryRepository: repository,
            calculationService: CalculationService()
        )
    }

    private func makeItem(
        id: String,
        defaultUnit: ConsumeUnit = .piece,
        defaultPurchaseUnit: ConsumeUnit? = nil,
        defaultAmountPerConsume: Double? = 1
    ) -> ConsumableItem {
        ConsumableItem(
            id: id,
            userId: "user-1",
            name: id,
            category: .custom,
            defaultUnit: defaultUnit,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultAmountPerConsume: defaultAmountPerConsume,
            updatedAt: Date(timeIntervalSince1970: id == "coffee" ? 2 : 1)
        )
    }
}

private final class DashboardRealtimeServiceFake: DashboardRealtimeServiceProtocol {
    private var onUpdate: ((DashboardRealtimePayload) -> Void)?

    func startRealtime(
        userId: String,
        scope: FirestoreAccountScope,
        onUpdate: @escaping (DashboardRealtimePayload) -> Void,
        onError: @escaping (Error) -> Void
    ) -> [ListenerRegistration] {
        self.onUpdate = onUpdate
        return []
    }

    @MainActor
    func send(consumables: [ConsumableItem], quitPlans: [QuitPlan] = []) async {
        onUpdate?(
            DashboardRealtimePayload(
                profile: UserProfile(
                    id: "user-1",
                    displayName: "User",
                    preferredCurrencyCode: "EUR",
                    baselineDailyConsume: 0,
                    baselineCostPerConsume: nil,
                    isGuestAccount: false,
                    onboardingCompleted: true
                ),
                consumables: consumables,
                entries: [],
                purchases: [],
                rewards: [],
                quitPlans: quitPlans,
                quitPlanEvents: [],
                relapseEvents: []
            )
        )
        await Task.yield()
    }
}

private final class DashboardEntryRepositoryFake: DashboardEntryRepositoryProtocol {
    private(set) var savedConsumes: [(entry: ConsumeEntry, scope: FirestoreAccountScope)] = []
    private(set) var savedPurchases: [(entry: PurchaseEntry, scope: FirestoreAccountScope)] = []
    private(set) var deletedConsumes: [(userId: String, entryId: String, scope: FirestoreAccountScope)] = []

    func saveConsumeEntry(_ entry: ConsumeEntry, scope: FirestoreAccountScope) async throws {
        savedConsumes.append((entry, scope))
    }

    func savePurchaseEntry(_ entry: PurchaseEntry, scope: FirestoreAccountScope) async throws {
        savedPurchases.append((entry, scope))
    }

    func softDeleteConsumeEntry(userId: String, entryId: String, deletedAt: Date, scope: FirestoreAccountScope) async throws {
        deletedConsumes.append((userId, entryId, scope))
    }
}
