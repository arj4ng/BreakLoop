// BreakLoop/ BreakLoop/ Shared/ Models/ QuitPlan.swift

// quit plan
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


enum QuitPlanStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case active
    case paused
    case completed
    case relapsed
    case archived
}

enum QuitPlanMode: String, Codable, CaseIterable, Hashable, Sendable {
    case quit
    case reduce
    case custom
}

extension QuitPlanStatus {

    // erlaubte statuswechsel schützen plan history vor unmöglichen zuständen
    func canTransition(to next: QuitPlanStatus) -> Bool {
        switch (self, next) {
        case (_, _) where self == next:
            return true
        case (.active, .paused), (.active, .completed), (.active, .relapsed), (.active, .archived):
            return true
        case (.paused, .active), (.paused, .archived):
            return true
        case (.completed, .archived):
            return true
        case (.relapsed, .active), (.relapsed, .archived):
            return true
        default:
            return false
        }
    }
}


// MARK: ┏━ [11 MODELS] QuitPlan
// MARK: ┗━ quit oder reduce plan pro consumable item

// plan ist item gebunden damit mehrere consumables getrennt quit state haben
struct QuitPlan: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var userId: String
    var consumableItemId: String
    var status: QuitPlanStatus
    var mode: QuitPlanMode
    var startDate: Date
    var targetDate: Date?
    var baselineDailyConsume: Double?
    var baselineCostPerConsume: Decimal?
    var templateId: String?
    var category: ConsumableCategory
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: String,
        userId: String,
        consumableItemId: String,
        status: QuitPlanStatus = .active,
        mode: QuitPlanMode = .quit,
        startDate: Date = .now,
        targetDate: Date? = nil,
        baselineDailyConsume: Double? = nil,
        baselineCostPerConsume: Decimal? = nil,
        templateId: String? = nil,
        category: ConsumableCategory = .custom,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.status = status
        self.mode = mode
        self.startDate = startDate
        self.targetDate = targetDate
        self.baselineDailyConsume = baselineDailyConsume.map { max(0, $0) }
        self.baselineCostPerConsume = baselineCostPerConsume
        self.templateId = templateId
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived || status == .archived
    }

    // pure helper gibt neuen plan zurück, ohne bestehenden value zu mutieren
    func transitioned(to next: QuitPlanStatus, at date: Date = .now) -> QuitPlan? {
        guard status.canTransition(to: next) else { return nil }
        return QuitPlan(
            id: id,
            userId: userId,
            consumableItemId: consumableItemId,
            status: next,
            mode: mode,
            startDate: startDate,
            targetDate: targetDate,
            baselineDailyConsume: baselineDailyConsume,
            baselineCostPerConsume: baselineCostPerConsume,
            templateId: templateId,
            category: category,
            createdAt: createdAt,
            updatedAt: date,
            isArchived: isArchived || next == .archived
        )
    }
}
