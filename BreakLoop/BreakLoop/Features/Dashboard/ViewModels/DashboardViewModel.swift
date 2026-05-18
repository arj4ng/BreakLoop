// BreakLoop/ BreakLoop/ Features/ Dashboard/ ViewModels/ DashboardViewModel.swift

// Dashboard view model
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
import Combine
import FirebaseFirestore


// MARK: ┏━ [04 DASHBOARD] DashboardViewModel
// MARK: ┗━ dashboard view model für screen state

// main actor: published state ändert nur auf ui thread
@MainActor
final class DashboardViewModel: ObservableObject {
    // @Published informiert SwiftUI wenn dashboard daten neu sind
    @Published private(set) var state: DashboardViewState = .empty
    @Published private(set) var entryActionMessage: DashboardEntryActionMessage?

    let userId: String
    let scope: FirestoreAccountScope
    private let realtimeService: DashboardRealtimeServiceProtocol
    private let entryRepository: DashboardEntryRepositoryProtocol
    private let calculationService: CalculationService
    // firestore listener behalten, damit deinit sie stoppen kann
    private var listeners: [ListenerRegistration] = []
    private var lastQuickConsumeEntryId: String?

    init(
        userId: String,
        scope: FirestoreAccountScope,
        realtimeService: DashboardRealtimeServiceProtocol? = nil,
        entryRepository: DashboardEntryRepositoryProtocol? = nil,
        calculationService: CalculationService? = nil
    ) {
        self.userId = userId
        self.scope = scope
        self.realtimeService = realtimeService ?? FirestoreDashboardRealtimeService()
        self.entryRepository = entryRepository ?? FirestoreTrackingRepository()
        self.calculationService = calculationService ?? CalculationService()
    }

    deinit {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    var selectedItem: ConsumableItem? {
        state.selectedItem
    }

    var shouldShowConsumablePicker: Bool {
        state.activeConsumables.count > 1
    }

    // startet realtime nur einmal pro view model
    func start() {
        guard listeners.isEmpty else { return }

        listeners = realtimeService.startRealtime(
            userId: userId,
            scope: scope,
            onUpdate: { [weak self] payload in
                // callback kann von firebase thread kommen, state muss zurück auf main
                DispatchQueue.main.async {
                    self?.applyRealtimePayload(payload)
                }
            },
            onError: { [weak self] error in
                // fehlertext ist ui state und bleibt deshalb auf main
                DispatchQueue.main.async {
                    self?.state.errorMessage = error.localizedDescription
                }
            }
        )
    }

    func selectConsumable(id: String) {
        state.selectedConsumableId = id
        recomputeCards()
    }

    // async: firestore save läuft im hintergrund, ui wartet ohne einzufrieren
    func quickLogConsume() async {
        guard let selectedItem else {
            showMissingConsumableMessage()
            return
        }

        let entry = ConsumeEntry(
            id: UUID().uuidString,
            userId: userId,
            consumableItemId: selectedItem.id,
            timestamp: .now,
            amount: selectedItem.defaultAmountPerConsume ?? 1,
            unit: selectedItem.defaultUnit
        )

        do {
            try await entryRepository.saveConsumeEntry(entry, scope: scope)
            lastQuickConsumeEntryId = entry.id
            entryActionMessage = DashboardEntryActionMessage(text: "Logged Consume", allowsUndo: true)
        } catch {
            entryActionMessage = DashboardEntryActionMessage(text: error.localizedDescription, isError: true)
        }
    }

    // undo löscht nicht hart, sondern setzt soft-delete flag im gleichen scope
    func undoLastQuickConsume() async {
        guard let entryId = lastQuickConsumeEntryId else { return }

        do {
            try await entryRepository.softDeleteConsumeEntry(
                userId: userId,
                entryId: entryId,
                deletedAt: .now,
                scope: scope
            )
            lastQuickConsumeEntryId = nil
            entryActionMessage = DashboardEntryActionMessage(text: "Consume removed")
        } catch {
            entryActionMessage = DashboardEntryActionMessage(text: error.localizedDescription, isError: true)
        }
    }

    // purchase sheet sammelt nur preis + menge; rest kommt vom gewählten consumable
    func savePurchase(price: Decimal, quantity: Double) async {
        guard let selectedItem else {
            showMissingConsumableMessage()
            return
        }

        let entry = PurchaseEntry(
            id: UUID().uuidString,
            userId: userId,
            consumableItemId: selectedItem.id,
            purchaseDate: .now,
            price: price,
            quantity: quantity,
            unit: selectedItem.defaultPurchaseUnit ?? selectedItem.defaultUnit
        )

        do {
            try await entryRepository.savePurchaseEntry(entry, scope: scope)
            entryActionMessage = DashboardEntryActionMessage(text: "Purchase saved")
        } catch {
            entryActionMessage = DashboardEntryActionMessage(text: error.localizedDescription, isError: true)
        }
    }

    func showMissingConsumableMessage() {
        entryActionMessage = DashboardEntryActionMessage(text: "Add a consumable first", isError: true)
    }

    func dismissEntryActionMessage(id: UUID) {
        guard entryActionMessage?.id == id else { return }
        entryActionMessage = nil
    }

    // snapshot daten übernehmen und aktive items für ui sortieren
    private func applyRealtimePayload(_ payload: DashboardRealtimePayload) {
        state.profile = payload.profile
        state.entries = payload.entries
        state.purchases = payload.purchases
        state.rewards = payload.rewards
        state.activeConsumables = payload.consumables.sorted { $0.updatedAt > $1.updatedAt }

        let activeIds = Set(state.activeConsumables.map(\.id))
        if let selected = state.selectedConsumableId, activeIds.contains(selected) == false {
            state.selectedConsumableId = nil
        }
        if state.selectedConsumableId == nil {
            state.selectedConsumableId = state.activeConsumables.first?.id
        }

        state.isLoading = false
        recomputeCards()
    }

    // kpi cards aus aktuellem item + tracking daten neu berechnen
    private func recomputeCards() {
        guard let selectedItem = state.selectedItem else {
            state.cards = defaultZeroCards(currencyCode: state.profile?.preferredCurrencyCode ?? "EUR")
            return
        }

        // fallback nur für formatierung/berechnung wenn profil snapshot noch fehlt
        let fallbackProfile = state.profile ?? UserProfile(
            id: userId,
            displayName: "User",
            preferredCurrencyCode: "EUR",
            baselineDailyConsume: 0,
            baselineCostPerConsume: nil,
            isGuestAccount: scope == .guest,
            onboardingCompleted: true
        )

        let now = Date()
        let monthInterval = Calendar.current.dateInterval(of: .month, for: now) ?? DateInterval(start: now, end: now)

        let lastConsume = calculationService.getLastConsumeDate(entries: state.entries, consumableItemId: selectedItem.id)
        let timeSince = calculationService.getTimeSinceLastConsume(entries: state.entries, consumableItemId: selectedItem.id, now: now)
        let todayConsume = calculationService.getConsumesForDay(entries: state.entries, item: selectedItem, date: now)
        let monthConsume = calculationService.getConsumesForMonth(entries: state.entries, item: selectedItem, date: now)

        let consumedSpend = calculationService.calculateConsumedMoneySpent(
            entries: state.entries,
            purchases: state.purchases,
            item: selectedItem,
            profile: fallbackProfile,
            within: monthInterval
        )
        let purchaseSpend = calculationService.calculateMoneySpent(
            purchases: state.purchases,
            consumableItemId: selectedItem.id,
            within: monthInterval
        )
        let monthSaved = calculationService.calculateSavedMoneyForMonth(
            entries: state.entries,
            purchases: state.purchases,
            item: selectedItem,
            profile: fallbackProfile,
            date: now
        )

        // item rewards + allgemeine rewards zählen
        let points = state.rewards
            .filter { $0.consumableItemId == nil || $0.consumableItemId == selectedItem.id }
            .reduce(0) { $0 + $1.points }

        let currencyCode = fallbackProfile.preferredCurrencyCode

        state.cards = [
            DashboardKPI(
                id: .lastConsume,
                title: "Last consume",
                primary: DashboardKPIValue(display: formatDateTime(lastConsume), rawNumeric: nil),
                secondary: nil
            ),
            DashboardKPI(
                id: .timeSince,
                title: "Time since",
                primary: DashboardKPIValue(display: formatDuration(timeSince), rawNumeric: timeSince),
                secondary: nil
            ),
            DashboardKPI(
                id: .todayConsume,
                title: "Today",
                primary: DashboardKPIValue(display: formatAmount(todayConsume), rawNumeric: todayConsume),
                secondary: selectedItem.defaultUnit.rawValue
            ),
            DashboardKPI(
                id: .monthConsume,
                title: "This month",
                primary: DashboardKPIValue(display: formatAmount(monthConsume), rawNumeric: monthConsume),
                secondary: selectedItem.defaultUnit.rawValue
            ),
            DashboardKPI(
                id: .monthSpent,
                title: "Month spent",
                primary: DashboardKPIValue(display: formatMoney(consumedSpend, currencyCode: currencyCode), rawNumeric: NSDecimalNumber(decimal: consumedSpend).doubleValue),
                secondary: "Purchased: \(formatMoney(purchaseSpend, currencyCode: currencyCode))"
            ),
            DashboardKPI(
                id: .monthSaved,
                title: "Month saved",
                primary: DashboardKPIValue(display: formatMoney(monthSaved, currencyCode: currencyCode), rawNumeric: NSDecimalNumber(decimal: monthSaved).doubleValue),
                secondary: "Points: \(points)"
            )
        ]
    }

    // leere karten halten grid stabil bis daten geladen sind
    private func defaultZeroCards(currencyCode: String) -> [DashboardKPI] {
        [
            DashboardKPI(id: .lastConsume, title: "Last consume", primary: DashboardKPIValue(display: "—"), secondary: nil),
            DashboardKPI(id: .timeSince, title: "Time since", primary: DashboardKPIValue(display: "—"), secondary: nil),
            DashboardKPI(id: .todayConsume, title: "Today", primary: DashboardKPIValue(display: "0"), secondary: nil),
            DashboardKPI(id: .monthConsume, title: "This month", primary: DashboardKPIValue(display: "0"), secondary: nil),
            DashboardKPI(id: .monthSpent, title: "Month spent", primary: DashboardKPIValue(display: formatMoney(.zero, currencyCode: currencyCode), rawNumeric: 0), secondary: "Purchased: \(formatMoney(.zero, currencyCode: currencyCode))"),
            DashboardKPI(id: .monthSaved, title: "Month saved", primary: DashboardKPIValue(display: formatMoney(.zero, currencyCode: currencyCode), rawNumeric: 0), secondary: "Points: 0")
        ]
    }

    private func formatDateTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // seconds -> kurze anzeige für dashboard
    private func formatDuration(_ interval: TimeInterval?) -> String {
        guard let interval, interval >= 0 else { return "—" }
        let seconds = Int(interval)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func formatMoney(_ value: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(currencyCode) \(value)"
    }

    private func formatAmount(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
