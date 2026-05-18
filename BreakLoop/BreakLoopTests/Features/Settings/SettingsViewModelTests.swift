import XCTest
@testable import BreakLoop

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testAddConsumableSavesUserAndScope() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .guest, service: service)
        var draft = ConsumableFormDraft()
        draft.name = "Coffee"
        draft.category = .caffeine
        draft.defaultUnit = .cup

        let saved = await viewModel.saveConsumable(draft: draft, existingItem: nil)

        XCTAssertTrue(saved)
        XCTAssertEqual(service.savedItems.first?.item.userId, "user-1")
        XCTAssertEqual(service.savedItems.first?.item.name, "Coffee")
        XCTAssertEqual(service.savedItems.first?.item.category, .caffeine)
        XCTAssertEqual(service.savedItems.first?.item.defaultUnit, .cup)
        XCTAssertEqual(service.savedItems.first?.scope, .guest)
    }

    func testEditConsumableKeepsExistingId() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .registered, service: service)
        let existing = makeItem(id: "item-1", name: "Old")
        var draft = ConsumableFormDraft(item: existing)
        draft.name = "New"
        draft.defaultUnit = .gram

        let saved = await viewModel.saveConsumable(draft: draft, existingItem: existing)

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

    func testDraftValidationBlocksEmptyName() {
        var draft = ConsumableFormDraft()
        draft.name = "   "

        XCTAssertFalse(draft.isValid)
    }

    func testPerPurchaseSavesPurchaseUnitAndUnitsPerPurchase() async {
        let service = SettingsConsumableServiceFake()
        let viewModel = SettingsViewModel(userId: "user-1", scope: .registered, service: service)
        var draft = ConsumableFormDraft()
        draft.name = "Pods"
        draft.pricingMode = .perPurchase
        draft.defaultPurchaseUnit = .pack
        draft.defaultUnitsPerPurchaseText = "20"

        let saved = await viewModel.saveConsumable(draft: draft, existingItem: nil)

        XCTAssertTrue(saved)
        XCTAssertEqual(service.savedItems.first?.item.pricingMode, .perPurchase)
        XCTAssertEqual(service.savedItems.first?.item.defaultPurchaseUnit, .pack)
        XCTAssertEqual(service.savedItems.first?.item.defaultUnitsPerPurchase, 20)
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
