import XCTest
@testable import BreakLoop

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testAddConsumableSavesUserAndScope() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .guest, service: service)
        let saved = await viewModel.saveConsumable(
            name: "Coffee",
            category: .caffeine,
            consumePresetName: "Coffee",
            trackName: "unit",
            trackAmountText: "1",
            trackUnit: .cup,
            usageMethod: .perCup,
            costAmountPerTrackText: "1",
            costUnit: .cup,
            purchaseName: "Bag",
            purchaseAmountText: "500",
            purchaseUnit: .gram,
            existingItem: nil
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(service.savedItems.first?.item.userId, "user-1")
        XCTAssertEqual(service.savedItems.first?.item.name, "Coffee")
        XCTAssertEqual(service.savedItems.first?.item.category, .caffeine)
        XCTAssertEqual(service.savedItems.first?.item.defaultUnit, .cup)
        XCTAssertEqual(service.savedItems.first?.item.trackName, "unit")
        XCTAssertEqual(service.savedItems.first?.item.costUnit, .cup)
        XCTAssertEqual(service.savedItems.first?.scope, .guest)
    }

    func testEditConsumableKeepsExistingId() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .registered, service: service)
        let existing = makeItem(id: "item-1", name: "Old")
        let saved = await viewModel.saveConsumable(
            name: "New",
            category: .custom,
            consumePresetName: "Custom",
            trackName: "unit",
            trackAmountText: "1",
            trackUnit: .gram,
            usageMethod: .custom,
            costAmountPerTrackText: "1",
            costUnit: .gram,
            purchaseName: "Bag",
            purchaseAmountText: "10",
            purchaseUnit: .gram,
            existingItem: existing
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(service.savedItems.first?.item.id, "item-1")
        XCTAssertEqual(service.savedItems.first?.item.name, "New")
        XCTAssertEqual(service.savedItems.first?.item.defaultUnit, .gram)
    }

    func testArchiveCallsScopedArchivePath() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .guest, service: service)
        let item = makeItem(id: "item-1", name: "Coffee")

        await viewModel.archiveConsumable(item)

        XCTAssertEqual(service.archivedItems.first?.userId, "user-1")
        XCTAssertEqual(service.archivedItems.first?.itemId, "item-1")
        XCTAssertEqual(service.archivedItems.first?.scope, .guest)
    }

    func testDraftValidationBlocksEmptyName() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .registered, service: service)

        let saved = await viewModel.saveConsumable(
            name: "   ",
            category: .custom,
            consumePresetName: "Custom",
            trackName: "unit",
            trackAmountText: "1",
            trackUnit: .piece,
            usageMethod: .custom,
            costAmountPerTrackText: "1",
            costUnit: .piece,
            purchaseName: "Package",
            purchaseAmountText: "1",
            purchaseUnit: .piece,
            existingItem: nil
        )

        XCTAssertFalse(saved)
    }

    func testPerPurchaseSavesPurchaseUnitAndUnitsPerPurchase() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .registered, service: service)
        let saved = await viewModel.saveConsumable(
            name: "Pods",
            category: .nicotine,
            consumePresetName: "Pouch",
            trackName: "unit",
            trackAmountText: "1",
            trackUnit: .piece,
            usageMethod: .perPiece,
            costAmountPerTrackText: "1",
            costUnit: .piece,
            purchaseName: "Pack",
            purchaseAmountText: "20",
            purchaseUnit: .pack,
            existingItem: nil
        )

        XCTAssertTrue(saved)
        XCTAssertEqual(service.savedItems.first?.item.pricingMode, .perPurchase)
        XCTAssertEqual(service.savedItems.first?.item.defaultPurchaseUnit, .pack)
        XCTAssertEqual(service.savedItems.first?.item.defaultUnitsPerPurchase, 20)
        XCTAssertEqual(service.savedItems.first?.item.purchaseName, "Pack")
        XCTAssertEqual(service.savedItems.first?.item.defaultPurchaseAmount, 20)
    }

    private func makeItem(id: String, name: String) -> ConsumableItem {
        ConsumableItem(
            id: id,
            userId: "user-1",
            name: name,
            category: .custom,
            defaultUnit: .piece
        )
    }
}

private final class SettingsConsumableServiceFake: SettingsConsumableServiceProtocol {
    private(set) var savedItems: [(item: ConsumableItem, scope: FirestoreAccountScope)] = []
    private(set) var archivedItems: [(userId: String, itemId: String, scope: FirestoreAccountScope)] = []
    var fetchedItems: [ConsumableItem] = []

    func fetchConsumableItems(userId: String, scope: FirestoreAccountScope) async throws -> [ConsumableItem] {
        fetchedItems
    }

    func saveConsumableItem(_ item: ConsumableItem, scope: FirestoreAccountScope) async throws {
        savedItems.append((item, scope))
    }

    func archiveConsumableItem(userId: String, itemId: String, scope: FirestoreAccountScope) async throws {
        archivedItems.append((userId, itemId, scope))
    }
}
