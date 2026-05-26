// BreakLoop/ BreakLoop/ Shared/ Services/ QuitPlanService.swift

// quit plan service
//
// Created by Arjang Khademi on 24.05.2026
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


// MARK: ┏━ [12 SERVICES] QuitPlanService
// MARK: ┗━ domain actions für quit und relapse ohne ui abhängigkeit

struct QuitPlanRelapseResult: Hashable, Sendable {
    let plan: QuitPlan
    let event: QuitPlanEvent
    let relapse: RelapseEvent
    let consumeEntry: ConsumeEntry?
}

struct QuitPlanService {
    private let repository: QuitPlanRepositoryProtocol

    init(repository: QuitPlanRepositoryProtocol = FirestoreTrackingRepository()) {
        self.repository = repository
    }

    func startPlan(
        userId: String,
        item: ConsumableItem,
        mode: QuitPlanMode = .quit,
        baselineDailyConsume: Double? = nil,
        baselineCostPerConsume: Decimal? = nil,
        startDate: Date = .now,
        targetDate: Date? = nil,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlan {
        let plan = QuitPlan(
            id: UUID().uuidString,
            userId: userId,
            consumableItemId: item.id,
            status: .active,
            mode: mode,
            startDate: startDate,
            targetDate: targetDate,
            baselineDailyConsume: baselineDailyConsume,
            baselineCostPerConsume: baselineCostPerConsume,
            templateId: RecoveryTemplateRegistry.defaultTemplateID(for: item.category),
            category: item.category
        )

        try await repository.saveQuitPlan(plan, scope: scope)
        return plan
    }

    func transition(
        plan: QuitPlan,
        to status: QuitPlanStatus,
        note: String? = nil,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlan? {
        guard let updated = plan.transitioned(to: status) else { return nil }
        try await repository.saveQuitPlan(updated, scope: scope)

        if let note {
            let event = QuitPlanEvent(
                id: UUID().uuidString,
                userId: updated.userId,
                consumableItemId: updated.consumableItemId,
                quitPlanId: updated.id,
                type: .note,
                note: note
            )
            try await repository.saveQuitPlanEvent(event, scope: scope)
        }

        return updated
    }

    func relapse(
        plan: QuitPlan,
        amount: Double? = nil,
        unit: ConsumeUnit? = nil,
        reason: String? = nil,
        createsConsumeEntry: Bool = false,
        scope: FirestoreAccountScope
    ) async throws -> QuitPlanRelapseResult? {
        var workingPlan = plan
        if workingPlan.status == .paused {
            guard let active = workingPlan.transitioned(to: .active) else { return nil }
            workingPlan = active
        }

        guard let relapsedPlan = workingPlan.transitioned(to: .relapsed) else { return nil }
        return try await repository.recordRelapse(
            plan: relapsedPlan,
            amount: amount,
            unit: unit,
            reason: reason,
            createsConsumeEntry: createsConsumeEntry,
            scope: scope
        )
    }
}
