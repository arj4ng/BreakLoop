// BreakLoop/ BreakLoop/ Shared/ Services/ CalculationService.swift

// calculation service
//
// Created by Arjang Khademi on 27.04.2026
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


// MARK: ┏━ [06 CALCULATION] CalculationService
// MARK: ┗━ zentrale tracking berechnung für consumes, costs, savings, rewards

struct CalculationService {

    // kalender injizierbar für tests mit fixem date setup
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }


    // MARK: - consume time

    // letztes consume event für item holen, deleted entries ignorieren
    func getLastConsumeDate(
        entries: [ConsumeEntry],
        consumableItemId: String
    ) -> Date? {
        filteredEntries(entries, consumableItemId: consumableItemId)
            .map(\.timestamp)
            .max()
    }

    // zeit seit letztem consume als seconds interval
    func getTimeSinceLastConsume(
        entries: [ConsumeEntry],
        consumableItemId: String,
        now: Date = .now
    ) -> TimeInterval? {
        guard let lastDate = getLastConsumeDate(entries: entries, consumableItemId: consumableItemId) else {
            return nil
        }

        return max(0, now.timeIntervalSince(lastDate))
    }


    // MARK: - consume counts

    func getConsumesForDay(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Double {

        // nutzt aktuelle kalendergrenzen für tag
        let interval = dayInterval(for: date)

        return totalConsumes(
            entries: entries,
            item: item,
            within: interval
        )
    }

    func getConsumesForWeek(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Double {

        // week interval kommt aus calendar weekOfYear
        let interval = weekInterval(for: date)

        return totalConsumes(
            entries: entries,
            item: item,
            within: interval
        )
    }

    func getConsumesForMonth(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Double {

        // month interval kommt aus calendar month
        let interval = monthInterval(for: date)

        return totalConsumes(
            entries: entries,
            item: item,
            within: interval
        )
    }


    // MARK: - averages

    // tagesdurchschnitt mit lookback, fallback auf baseline
    func calculateDailyAverage(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        profile: UserProfile,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays,
        now: Date = .now
    ) -> Double {
        guard lookbackDays > 0 else { return max(0, profile.baselineDailyConsume) }

        let startDate = calendar.date(byAdding: .day, value: -(lookbackDays - 1), to: dayInterval(for: now).start) ?? now
        let range = DateInterval(start: startDate, end: now)

        let total = totalConsumes(entries: entries, item: item, within: range)

        // first day / no history -> baseline oder 0
        if total == 0 {
            return max(0, profile.baselineDailyConsume)
        }

        return total / Double(lookbackDays)
    }

    func calculateWeeklyAverage(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        profile: UserProfile,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays,
        now: Date = .now
    ) -> Double {
        calculateDailyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: now
        ) * 7
    }

    func calculateMonthlyAverage(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        profile: UserProfile,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays,
        now: Date = .now
    ) -> Double {
        calculateDailyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: now
        ) * 30
    }


    // MARK: - money

    func calculateMoneySpent(
        purchases: [PurchaseEntry],
        consumableItemId: String,
        within interval: DateInterval
    ) -> Decimal {
        filteredPurchases(purchases, consumableItemId: consumableItemId)
            .filter { interval.contains($0.purchaseDate) }
            .reduce(.zero) { $0 + $1.price }
    }

    // estimated kosten pro consume über purchases + fallback item/profile
    func calculateEstimatedCostPerConsume(
        item: ConsumableItem,
        purchases: [PurchaseEntry],
        profile: UserProfile
    ) -> Decimal {
        let itemPurchases = filteredPurchases(purchases, consumableItemId: item.id)

        // weighted average pro unit aus purchases
        let totalSpent = itemPurchases.reduce(Decimal.zero) { $0 + $1.price }
        let totalQuantity = itemPurchases.reduce(0.0) { $0 + max(0, $1.quantity) }

        // primär datenquelle = weighted purchase average
        if totalQuantity > 0 {
            let costPerUnit = totalSpent / decimal(from: totalQuantity)
            let amountPerConsume = max(0.0001, item.defaultAmountPerConsume ?? 1)
            return costPerUnit * decimal(from: amountPerConsume)
        }

        // fallback 1 = item default cost
        if let defaultCost = item.defaultCostPerConsume, defaultCost > 0 {
            return defaultCost
        }

        // fallback 2 = profil baseline cost
        if let baselineCost = profile.baselineCostPerConsume, baselineCost > 0 {
            return baselineCost
        }

        return .zero
    }

    func calculateSavedMoneyForDay(
        entries: [ConsumeEntry],
        purchases: [PurchaseEntry],
        item: ConsumableItem,
        profile: UserProfile,
        date: Date,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays
    ) -> Decimal {
        let averagePerDay = calculateDailyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: date
        )

        let today = getConsumesForDay(entries: entries, item: item, date: date)

        // avoided nie negativ damit sparen nur bei reduktion zählt
        let avoided = max(0, averagePerDay - today)
        let costPerConsume = calculateEstimatedCostPerConsume(item: item, purchases: purchases, profile: profile)

        return decimal(from: avoided) * costPerConsume
    }

    func calculateSavedMoneyForWeek(
        entries: [ConsumeEntry],
        purchases: [PurchaseEntry],
        item: ConsumableItem,
        profile: UserProfile,
        date: Date,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays
    ) -> Decimal {
        let averagePerWeek = calculateWeeklyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: date
        )

        let thisWeek = getConsumesForWeek(entries: entries, item: item, date: date)

        // avoided nie negativ damit sparen nur bei reduktion zählt
        let avoided = max(0, averagePerWeek - thisWeek)
        let costPerConsume = calculateEstimatedCostPerConsume(item: item, purchases: purchases, profile: profile)

        return decimal(from: avoided) * costPerConsume
    }

    func calculateSavedMoneyForMonth(
        entries: [ConsumeEntry],
        purchases: [PurchaseEntry],
        item: ConsumableItem,
        profile: UserProfile,
        date: Date,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays
    ) -> Decimal {
        let averagePerMonth = calculateMonthlyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: date
        )

        let thisMonth = getConsumesForMonth(entries: entries, item: item, date: date)

        // avoided nie negativ damit sparen nur bei reduktion zählt
        let avoided = max(0, averagePerMonth - thisMonth)
        let costPerConsume = calculateEstimatedCostPerConsume(item: item, purchases: purchases, profile: profile)

        return decimal(from: avoided) * costPerConsume
    }


    // MARK: - rewards

    // points = avoided consumes + consume free bonus
    func calculateRewardPoints(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        profile: UserProfile,
        date: Date,
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays
    ) -> Int {
        let averagePerDay = calculateDailyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: date
        )

        let today = getConsumesForDay(entries: entries, item: item, date: date)

        // floor vermeidet halbe avoided counts bei points
        let avoided = Int(max(0, floor(averagePerDay - today)))

        var points = avoided * TrackingConstants.pointsPerAvoidedConsume

        if detectConsumeFreeDay(entries: entries, item: item, date: date) {
            points += TrackingConstants.consumeFreeDayBonus
        }

        if detectConsumeFreeWeek(entries: entries, item: item, date: date) {
            points += TrackingConstants.consumeFreeWeekBonus
        }

        if detectConsumeFreeMonth(entries: entries, item: item, date: date) {
            points += TrackingConstants.consumeFreeMonthBonus
        }

        return max(0, points)
    }

    func detectConsumeFreeDay(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        getConsumesForDay(entries: entries, item: item, date: date) == 0
    }

    func detectConsumeFreeWeek(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        getConsumesForWeek(entries: entries, item: item, date: date) == 0
    }

    func detectConsumeFreeMonth(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        getConsumesForMonth(entries: entries, item: item, date: date) == 0
    }


    // MARK: - private helpers

    private func totalConsumes(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        within interval: DateInterval
    ) -> Double {
        filteredEntries(entries, consumableItemId: item.id)
            .filter { interval.contains($0.timestamp) }
            .reduce(0) { partial, entry in
                partial + normalizedConsumeAmount(entry: entry, item: item)
            }
    }

    // normalisiert amount auf consume-count basis für unterschiedliche units
    private func normalizedConsumeAmount(entry: ConsumeEntry, item: ConsumableItem) -> Double {
        let safeAmount = max(0, entry.amount)

        // wenn unit gleich, dann amount per consume anwenden
        if entry.unit == item.defaultUnit {
            let amountPerConsume = max(0.0001, item.defaultAmountPerConsume ?? 1)
            return safeAmount / amountPerConsume
        }

        // einfache fallback konvertierung falls units nicht matchen
        let fromFactor = unitFactor(for: entry.unit)
        let toFactor = unitFactor(for: item.defaultUnit)

        guard toFactor > 0 else { return 0 }

        let converted = safeAmount * (fromFactor / toFactor)
        let amountPerConsume = max(0.0001, item.defaultAmountPerConsume ?? 1)
        return converted / amountPerConsume
    }

    // faktor nur grober fallback, später kann custom conversion pro item kommen
    private func unitFactor(for unit: ConsumeUnit) -> Double {
        switch unit {
        case .piece: return 1
        case .pack: return 20
        case .gram: return 1
        case .milliliter: return 1
        case .cup: return 1
        case .dose: return 1
        case .other: return 1
        }
    }

    private func filteredEntries(
        _ entries: [ConsumeEntry],
        consumableItemId: String
    ) -> [ConsumeEntry] {

        // soft deleted logs fliegen aus allen calculations raus
        entries
            .filter { $0.consumableItemId == consumableItemId }
            .filter { !$0.isDeleted }
    }

    private func filteredPurchases(
        _ purchases: [PurchaseEntry],
        consumableItemId: String
    ) -> [PurchaseEntry] {

        // soft deleted käufe fliegen aus kostenberechnung raus
        purchases
            .filter { $0.consumableItemId == consumableItemId }
            .filter { !$0.isDeleted }
    }

    private func dayInterval(for date: Date) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private func weekInterval(for date: Date) -> DateInterval {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date)
        return interval ?? dayInterval(for: date)
    }

    private func monthInterval(for date: Date) -> DateInterval {
        let interval = calendar.dateInterval(of: .month, for: date)
        return interval ?? dayInterval(for: date)
    }

    private func decimal(from value: Double) -> Decimal {
        Decimal(string: String(value)) ?? .zero
    }
}
