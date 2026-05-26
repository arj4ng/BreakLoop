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
    private let epsilon: Double = 0.000_001

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

        // baseline immer aus vergangenheit, aktueller tag fliegt raus
        let todayStart = dayInterval(for: now).start
        let startDate = calendar.date(byAdding: .day, value: -lookbackDays, to: todayStart) ?? todayStart
        let range = DateInterval(start: startDate, end: todayStart)

        guard range.duration > 0 else { return max(0, profile.baselineDailyConsume) }

        let total = totalConsumes(entries: entries, item: item, within: range)

        // first day / no history -> baseline oder 0
        if isZero(total) {
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
        let dailyAverage = calculateDailyAverage(
            entries: entries,
            item: item,
            profile: profile,
            lookbackDays: lookbackDays,
            now: now
        )

        return dailyAverage * Double(daysInMonth(for: now))
    }


    // MARK: - money

    // reine kaufausgaben im zeitraum
    func calculateMoneySpent(
        purchases: [PurchaseEntry],
        consumableItemId: String,
        within interval: DateInterval
    ) -> Decimal {
        filteredPurchases(purchases, consumableItemId: consumableItemId)
            .filter { interval.contains($0.purchaseDate) }
            .reduce(.zero) { $0 + $1.price }
    }

    // consumebasierte ausgabe im zeitraum auf basis cost per consume
    func calculateConsumedMoneySpent(
        entries: [ConsumeEntry],
        purchases: [PurchaseEntry],
        item: ConsumableItem,
        profile: UserProfile,
        within interval: DateInterval
    ) -> Decimal {
        let consumed = totalConsumes(entries: entries, item: item, within: interval)
        guard consumed > 0 else { return .zero }

        let costPerConsume = calculateEstimatedCostPerConsume(item: item, purchases: purchases, profile: profile)
        guard costPerConsume > 0 else { return .zero }

        return decimal(from: consumed) * costPerConsume
    }

    // estimated kosten pro consume über purchases + fallback item/profile
    func calculateEstimatedCostPerConsume(
        item: ConsumableItem,
        purchases: [PurchaseEntry],
        profile: UserProfile,
        useProfileFallback: Bool = false
    ) -> Decimal {
        let itemPurchases = filteredPurchases(purchases, consumableItemId: item.id)

        // weighted average pro costUnit aus purchases
        var totalSpendInCostUnit = Decimal.zero
        var totalCostQuantity = 0.0

        for purchase in itemPurchases {
            guard
                let costQuantity = convertedQuantity(
                    quantity: purchase.quantity,
                    from: purchase.unit,
                    to: item.effectiveCostUnit,
                    item: item
                ),
                costQuantity > 0
            else {
                continue
            }

            let safeCostQuantity = decimal(from: costQuantity)

            // primär gespeicherte unit cost nutzen, fallback auf price/qty
            if let normalizedCost = normalizedCalculatedCostPerCostUnit(purchase: purchase, item: item), normalizedCost > 0 {
                totalSpendInCostUnit += normalizedCost * safeCostQuantity
            } else if purchase.price > 0 {
                totalSpendInCostUnit += purchase.price
            }

            totalCostQuantity += costQuantity
        }

        // primär datenquelle = weighted purchase average
        if totalCostQuantity > 0, totalSpendInCostUnit > 0 {
            let costPerUnit = totalSpendInCostUnit / decimal(from: totalCostQuantity)
            return costPerUnit * decimal(from: item.effectiveCostAmountPerTrack)
        }

        // fallback = profil baseline cost nur wenn explizit erlaubt
        if useProfileFallback, let baselineCost = profile.baselineCostPerConsume, baselineCost > 0 {
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
        lookbackDays: Int = TrackingConstants.defaultAverageLookbackDays,
        rewardEntries: [RewardEntry] = []
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

        if detectConsumeFreeDay(entries: entries, item: item, date: date) &&
            !hasRewardBonusAlready(
                rewardEntries: rewardEntries,
                itemId: item.id,
                type: .consumeFreeDay,
                date: date
            ) {
            points += TrackingConstants.consumeFreeDayBonus
        }

        if detectConsumeFreeWeek(entries: entries, item: item, date: date) &&
            !hasRewardBonusAlready(
                rewardEntries: rewardEntries,
                itemId: item.id,
                type: .consumeFreeWeek,
                date: date
            ) {
            points += TrackingConstants.consumeFreeWeekBonus
        }

        if detectConsumeFreeMonth(entries: entries, item: item, date: date) &&
            !hasRewardBonusAlready(
                rewardEntries: rewardEntries,
                itemId: item.id,
                type: .consumeFreeMonth,
                date: date
            ) {
            points += TrackingConstants.consumeFreeMonthBonus
        }

        return max(0, points)
    }

    func detectConsumeFreeDay(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        isZero(getConsumesForDay(entries: entries, item: item, date: date))
    }

    func detectConsumeFreeWeek(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        isZero(getConsumesForWeek(entries: entries, item: item, date: date))
    }

    func detectConsumeFreeMonth(
        entries: [ConsumeEntry],
        item: ConsumableItem,
        date: Date
    ) -> Bool {
        isZero(getConsumesForMonth(entries: entries, item: item, date: date))
    }

    // stabiler period key für dedupe beim speichern von bonus rewards
    func rewardPeriodKey(for type: RewardType, date: Date) -> String? {
        switch type {
        case .consumeFreeDay:
            let comp = calendar.dateComponents([.year, .month, .day], from: date)
            guard let year = comp.year, let month = comp.month, let day = comp.day else { return nil }
            return "day-\(year)-\(month)-\(day)"
        case .consumeFreeWeek:
            let comp = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            guard let year = comp.yearForWeekOfYear, let week = comp.weekOfYear else { return nil }
            return "week-\(year)-\(week)"
        case .consumeFreeMonth:
            let comp = calendar.dateComponents([.year, .month], from: date)
            guard let year = comp.year, let month = comp.month else { return nil }
            return "month-\(year)-\(month)"
        default:
            return nil
        }
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
        guard
                let converted = convertedQuantity(
                    quantity: entry.amount,
                    from: entry.unit,
                    to: item.effectiveTrackUnit,
                    item: item
                )
        else {
            return 0
        }

        let amountPerConsume = max(0.0001, item.effectiveTrackAmount)
        return converted / amountPerConsume
    }

    // konvertiert quantity zwischen kompatiblen einheiten
    private func convertedQuantity(
        quantity: Double,
        from sourceUnit: ConsumeUnit,
        to targetUnit: ConsumeUnit,
        item: ConsumableItem
    ) -> Double? {
        let safeQuantity = max(0, quantity)
        guard safeQuantity > 0 else { return 0 }

        if sourceUnit == targetUnit {
            return safeQuantity
        }

        // pack conversion nutzt item metadata, kein hardcoded 20er wert
        if sourceUnit == .pack, targetUnit != .pack {
            let purchaseAmount = item.effectiveDefaultPurchaseAmount
            guard purchaseAmount > 0 else { return nil }
            return safeQuantity * purchaseAmount
        }

        if targetUnit == .pack, sourceUnit != .pack {
            let purchaseAmount = item.effectiveDefaultPurchaseAmount
            guard purchaseAmount > 0 else { return nil }
            return safeQuantity / purchaseAmount
        }

        // sonst keine implizite cross unit conversion
        return nil
    }

    private func normalizedCalculatedCostPerCostUnit(
        purchase: PurchaseEntry,
        item: ConsumableItem
    ) -> Decimal? {
        guard purchase.calculatedCostPerUnit > 0 else { return nil }

        guard
            let unitsInCostUnit = convertedQuantity(
                quantity: 1,
                from: purchase.unit,
                to: item.effectiveCostUnit,
                item: item
            ),
            unitsInCostUnit > 0
        else {
            return nil
        }

        return purchase.calculatedCostPerUnit / decimal(from: unitsInCostUnit)
    }

    private func hasRewardBonusAlready(
        rewardEntries: [RewardEntry],
        itemId: String,
        type: RewardType,
        date: Date
    ) -> Bool {
        guard let periodInterval = rewardPeriodInterval(for: type, date: date) else { return false }
        let periodKey = rewardPeriodKey(for: type, date: date)

        return rewardEntries.contains { entry in
            guard entry.type == type else { return false }

            // item gebundene rewards nur bei gleichem item matchen
            if let rewardItemId = entry.consumableItemId, rewardItemId != itemId {
                return false
            }

            // neue einträge dedupe über key
            if let periodKey, let storedKey = entry.periodKey {
                return periodKey == storedKey
            }

            // fallback für alte docs ohne key
            return periodInterval.contains(entry.createdAt)
        }
    }

    private func rewardPeriodInterval(for type: RewardType, date: Date) -> DateInterval? {
        switch type {
        case .consumeFreeDay:
            return dayInterval(for: date)
        case .consumeFreeWeek:
            return weekInterval(for: date)
        case .consumeFreeMonth:
            return monthInterval(for: date)
        default:
            return nil
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

    private func daysInMonth(for date: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }

    private func isZero(_ value: Double) -> Bool {
        abs(value) <= epsilon
    }

    private func decimal(from value: Double) -> Decimal {
        Decimal(string: String(value)) ?? .zero
    }
}
