import XCTest
@testable import BreakLoop

final class QuitPlanServiceTests: XCTestCase {
    func testStatusTransitionRules() {
        XCTAssertTrue(QuitPlanStatus.active.canTransition(to: .paused))
        XCTAssertTrue(QuitPlanStatus.paused.canTransition(to: .active))
        XCTAssertTrue(QuitPlanStatus.active.canTransition(to: .relapsed))
        XCTAssertFalse(QuitPlanStatus.completed.canTransition(to: .relapsed))
    }

    func testPausedRelapsePromotesToRelapsedBeforeWritingHistory() async throws {
        let repository = QuitPlanRepositoryFake()
        let service = QuitPlanService(repository: repository)
        let plan = QuitPlan(
            id: "plan-1",
            userId: "user-1",
            consumableItemId: "item-1",
            status: .paused,
            category: .cannabis
        )

        let result = try await service.relapse(
            plan: plan,
            amount: nil,
            unit: nil,
            reason: "test",
            createsConsumeEntry: false,
            scope: .guest
        )

        XCTAssertEqual(result?.plan.status, .relapsed)
        XCTAssertEqual(repository.recordedRelapses.count, 1)
        XCTAssertEqual(repository.recordedRelapses.first?.plan.status, .relapsed)
        XCTAssertNil(result?.consumeEntry)
    }

    func testRelapseCanCreateLinkedConsumeEntry() async throws {
        let repository = QuitPlanRepositoryFake()
        let service = QuitPlanService(repository: repository)
        let plan = QuitPlan(
            id: "plan-1",
            userId: "user-1",
            consumableItemId: "item-1",
            status: .active,
            category: .nicotine
        )

        let result = try await service.relapse(
            plan: plan,
            amount: 1,
            unit: .piece,
            reason: nil,
            createsConsumeEntry: true,
            scope: .registered
        )

        XCTAssertEqual(result?.relapse.createdConsumeEntryId, "consume-1")
        XCTAssertEqual(result?.consumeEntry?.amount, 1)
        XCTAssertEqual(result?.consumeEntry?.unit, .piece)
    }

    func testSnapshotTracksQuitDataForMigration() {
        let snapshot = FirestoreUserDataSnapshot(
            profile: nil,
            consumableItems: [],
            consumeEntries: [],
            purchaseEntries: [],
            rewardEntries: [],
            quitPlans: [
                QuitPlan(
                    id: "plan-1",
                    userId: "user-1",
                    consumableItemId: "item-1"
                )
            ],
            quitPlanEvents: [],
            relapseEvents: []
        )

        XCTAssertTrue(snapshot.hasAnyData)
        XCTAssertEqual(snapshot.quitPlans.count, 1)
    }
}

private final class QuitPlanRepositoryFake: QuitPlanRepositoryProtocol {
    private(set) var savedPlans: [(plan: QuitPlan, scope: FirestoreAccountScope)] = []
    private(set) var savedEvents: [(event: QuitPlanEvent, scope: FirestoreAccountScope)] = []
    private(set) var recordedRelapses: [(plan: QuitPlan, scope: FirestoreAccountScope)] = []

    func fetchQuitPlans(userId: String, scope: FirestoreAccountScope) async throws -> [QuitPlan] {
        savedPlans.map(\.plan)
    }

    func saveQuitPlan(_ plan: QuitPlan, scope: FirestoreAccountScope) async throws {
        savedPlans.append((plan, scope))
    }

    func saveQuitPlanEvent(_ event: QuitPlanEvent, scope: FirestoreAccountScope) async throws {
        savedEvents.append((event, scope))
    }

    func recordRelapse(
        plan: QuitPlan,
        amount: Double?,
        unit: ConsumeUnit?,
        reason: String?,
        createsConsumeEntry: Bool,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlanRelapseResult {
        recordedRelapses.append((plan, scope))

        let consumeEntry: ConsumeEntry?
        if createsConsumeEntry, let amount, let unit {
            consumeEntry = ConsumeEntry(
                id: "consume-1",
                userId: plan.userId,
                consumableItemId: plan.consumableItemId,
                amount: amount,
                unit: unit
            )
        } else {
            consumeEntry = nil
        }

        let relapse = RelapseEvent(
            id: "relapse-1",
            userId: plan.userId,
            consumableItemId: plan.consumableItemId,
            quitPlanId: plan.id,
            amount: amount,
            unit: unit,
            reason: reason,
            createdConsumeEntryId: consumeEntry?.id
        )
        let event = QuitPlanEvent(
            id: "event-1",
            userId: plan.userId,
            consumableItemId: plan.consumableItemId,
            quitPlanId: plan.id,
            type: .note,
            note: "Relapse logged"
        )

        return QuitPlanRelapseResult(
            plan: plan,
            event: event,
            relapse: relapse,
            consumeEntry: consumeEntry
        )
    }

    func archiveQuitPlan(userId: String, planId: String, archivedAt: Date, scope: FirestoreAccountScope) async throws {}
}
