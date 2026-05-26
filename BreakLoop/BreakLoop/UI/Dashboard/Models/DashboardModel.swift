// BreakLoop/ BreakLoop/ Features/ Dashboard/ Models/ DashboardModel.swift

// Dashboard model
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


// MARK: ┏━ [11 MODELS] DashboardModel
// MARK: ┗━ dashboard model für daten

// anzeige wert plus optionaler raw wert für spätere charts
struct DashboardKPIValue: Hashable {
    let display: String
    let rawNumeric: Double?

    init(display: String, rawNumeric: Double? = nil) {
        self.display = display
        self.rawNumeric = rawNumeric
    }
}

// einzelne dashboard kachel mit festem typ als id
struct DashboardKPI: Identifiable, Hashable {
    enum Kind: String {
        case lastConsume
        case timeSince
        case todayConsume
        case monthConsume
        case monthSpent
        case monthSaved
    }

    let id: Kind
    let title: String
    let primary: DashboardKPIValue
    let secondary: String?
}

// kompletter ui state vom dashboard screen
struct DashboardViewState: Hashable {
    var profile: UserProfile?
    var activeConsumables: [ConsumableItem]
    var selectedConsumableId: String?
    var entries: [ConsumeEntry]
    var purchases: [PurchaseEntry]
    var rewards: [RewardEntry]
    var quitPlans: [QuitPlan]
    var quitPlanEvents: [QuitPlanEvent]
    var relapseEvents: [RelapseEvent]
    var cards: [DashboardKPI]
    var isLoading: Bool
    var errorMessage: String?

    static let empty = DashboardViewState(
        profile: nil,
        activeConsumables: [],
        selectedConsumableId: nil,
        entries: [],
        purchases: [],
        rewards: [],
        quitPlans: [],
        quitPlanEvents: [],
        relapseEvents: [],
        cards: [],
        isLoading: true,
        errorMessage: nil
    )

    // selected id gewinnt, sonst erstes aktives item
    var selectedItem: ConsumableItem? {
        guard let selectedConsumableId else { return activeConsumables.first }
        return activeConsumables.first(where: { $0.id == selectedConsumableId }) ?? activeConsumables.first
    }

    // aktueller quit/reduce plan für ausgewähltes item
    var selectedActiveQuitPlan: QuitPlan? {
        guard let item = selectedItem else { return nil }
        return quitPlans
            .filter { !$0.isArchived }
            .filter { $0.consumableItemId == item.id }
            .filter { $0.status == .active || $0.status == .paused }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    // empty state nur zeigen, wenn wirklich keine log daten da sind
    var hasAnyEntryData: Bool {
        !entries.isEmpty || !purchases.isEmpty
    }
}

// toast payload für entry actions unten im dashboard
struct DashboardEntryActionMessage: Identifiable, Hashable {
    let id: UUID
    let text: String
    let allowsUndo: Bool
    let isError: Bool

    init(id: UUID = UUID(), text: String, allowsUndo: Bool = false, isError: Bool = false) {
        self.id = id
        self.text = text
        self.allowsUndo = allowsUndo
        self.isError = isError
    }
}

// kompakte quit stats für dashboard cards
struct DashboardQuitMetrics: Hashable {
    let daysQuit: Int
    let unitsAvoided: Double
    let moneySaved: Decimal
    let dailyBurnRate: Decimal

    static let empty = DashboardQuitMetrics(
        daysQuit: 0,
        unitsAvoided: 0,
        moneySaved: .zero,
        dailyBurnRate: .zero
    )
}
