import XCTest
@testable import BreakLoop

final class CalculationServiceTests: XCTestCase {
    private let service = CalculationService()

    func testWeedJointCostUsesGramPurchaseConversion() {
        let item = makeItem(
            id: "weed",
            category: .cannabis,
            defaultUnit: .piece,
            defaultPurchaseUnit: .gram,
            defaultAmountPerConsume: 1,
            defaultUnitsPerPurchase: 5,
            trackName: "joint",
            trackAmount: 1,
            trackUnit: .piece,
            costAmountPerTrack: 0.3,
            costUnit: .gram,
            purchaseName: "Bag",
            defaultPurchaseAmount: 5
        )
        let purchase = PurchaseEntry(
            id: "purchase-1",
            userId: "user-1",
            consumableItemId: "weed",
            price: 50,
            quantity: 5,
            unit: .gram
        )

        let cost = service.calculateEstimatedCostPerConsume(
            item: item,
            purchases: [purchase],
            profile: profile
        )

        XCTAssertEqual(NSDecimalNumber(decimal: cost).doubleValue, 3, accuracy: 0.001)
    }

    func testCigaretteCostUsesPiecePurchaseConversion() {
        let item = makeItem(
            id: "cigarettes",
            category: .nicotine,
            defaultUnit: .piece,
            defaultPurchaseUnit: .piece,
            defaultAmountPerConsume: 1,
            defaultUnitsPerPurchase: 20,
            trackName: "cigarette",
            trackAmount: 1,
            trackUnit: .piece,
            costAmountPerTrack: 1,
            costUnit: .piece,
            purchaseName: "Pack",
            defaultPurchaseAmount: 20
        )
        let purchase = PurchaseEntry(
            id: "purchase-1",
            userId: "user-1",
            consumableItemId: "cigarettes",
            price: 10,
            quantity: 20,
            unit: .piece
        )

        let cost = service.calculateEstimatedCostPerConsume(
            item: item,
            purchases: [purchase],
            profile: profile
        )

        XCTAssertEqual(NSDecimalNumber(decimal: cost).doubleValue, 0.5, accuracy: 0.001)
    }

    func testOldCannabisPieceItemInfersJointGramFallback() {
        let item = makeItem(
            id: "old-weed",
            category: .cannabis,
            defaultUnit: .piece,
            defaultPurchaseUnit: .gram,
            defaultAmountPerConsume: 1,
            defaultUnitsPerPurchase: 5
        )
        let purchase = PurchaseEntry(
            id: "purchase-1",
            userId: "user-1",
            consumableItemId: "old-weed",
            price: 50,
            quantity: 5,
            unit: .gram
        )

        let cost = service.calculateEstimatedCostPerConsume(
            item: item,
            purchases: [purchase],
            profile: profile
        )

        XCTAssertEqual(NSDecimalNumber(decimal: cost).doubleValue, 3, accuracy: 0.001)
    }

    func testDynamicItemWithoutPurchaseIgnoresStaleDefaultCost() {
        let item = makeItem(
            id: "weed",
            category: .cannabis,
            defaultUnit: .piece,
            defaultPurchaseUnit: .gram,
            defaultAmountPerConsume: 1,
            defaultUnitsPerPurchase: 5,
            defaultCostPerConsume: 10,
            trackName: "joint",
            trackAmount: 1,
            trackUnit: .piece,
            costAmountPerTrack: 0.3,
            costUnit: .gram,
            purchaseName: "Bag",
            defaultPurchaseAmount: 5
        )

        let cost = service.calculateEstimatedCostPerConsume(
            item: item,
            purchases: [],
            profile: profile
        )

        XCTAssertEqual(cost, .zero)
    }

    private var profile: UserProfile {
        UserProfile(
            id: "user-1",
            displayName: "User",
            preferredCurrencyCode: "EUR",
            baselineDailyConsume: 0,
            baselineCostPerConsume: nil,
            isGuestAccount: false,
            onboardingCompleted: true
        )
    }

    private func makeItem(
        id: String,
        category: ConsumableCategory,
        defaultUnit: ConsumeUnit,
        defaultPurchaseUnit: ConsumeUnit?,
        defaultAmountPerConsume: Double?,
        defaultUnitsPerPurchase: Double?,
        defaultCostPerConsume: Decimal? = nil,
        trackName: String? = nil,
        trackAmount: Double? = nil,
        trackUnit: ConsumeUnit? = nil,
        costAmountPerTrack: Double? = nil,
        costUnit: ConsumeUnit? = nil,
        purchaseName: String? = nil,
        defaultPurchaseAmount: Double? = nil
    ) -> ConsumableItem {
        ConsumableItem(
            id: id,
            userId: "user-1",
            name: id,
            category: category,
            defaultUnit: defaultUnit,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultAmountPerConsume: defaultAmountPerConsume,
            defaultUnitsPerPurchase: defaultUnitsPerPurchase,
            defaultCostPerConsume: defaultCostPerConsume,
            trackName: trackName,
            trackAmount: trackAmount,
            trackUnit: trackUnit,
            costAmountPerTrack: costAmountPerTrack,
            costUnit: costUnit,
            purchaseName: purchaseName,
            defaultPurchaseAmount: defaultPurchaseAmount
        )
    }
}
