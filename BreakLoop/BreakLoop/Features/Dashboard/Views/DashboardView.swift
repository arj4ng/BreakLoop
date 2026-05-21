// BreakLoop/ BreakLoop/ Features/ Dashboard/ Views/ DashboardView.swift

// dashboard
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

import Charts
import SwiftUI


// MARK: ┏━ [04 DASHBOARD] DashboardView
// MARK: ┗━ Hauptcontainer vom Dashboard mit Design System Typografie und Farben

// screen leicht halten, komplexe logic ins viewmodel
struct DashboardView: View {
    // eigene tab auswahl, weil native iOS 26 tabbar als floating capsule rendert
    private enum DashboardTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case details = "Details"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .details: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // StateObject hält viewmodel über view refreshes stabil
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTab: DashboardTab = .dashboard
    @State private var isPurchaseSheetPresented = false
    @State private var selectedChartPeriod: DashboardChartPeriod = .daily
    let onSignOut: () -> Void

    init(userId: String, scope: FirestoreAccountScope, onSignOut: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userId: userId, scope: scope))
        self.onSignOut = onSignOut
    }

    var body: some View {
        selectedTabContent
        .tint(AppColors.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
        }
        .overlay(alignment: .bottom) {
            entryActionToast
        }
        .sheet(isPresented: $isPurchaseSheetPresented) {
            PurchaseEntrySheet(item: viewModel.selectedItem) { price, quantity, unit in
                Task {
                    await viewModel.savePurchase(price: price, quantity: quantity, unit: unit)
                    isPurchaseSheetPresented = false
                }
            }
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.entryActionMessage?.id) { _, newId in
            guard let newId else { return }

            // toast bleibt kurz sichtbar und entfernt nur sich selbst
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                viewModel.dismissEntryActionMessage(id: newId)
            }
        }
        .task {
            // task läuft beim anzeigen der view und startet realtime listener
            viewModel.start()
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .dashboard:
            dashboardTab
        case .details:
            detailsTab
        case .settings:
            settingsTab
        }
    }

    private var dashboardTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dashboardContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 148)
        }
        .background(AppColors.background)
    }

    private var detailsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(title: "Details")
                detailsContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(AppColors.background)
    }

    private var settingsTab: some View {
        SettingsView(userId: viewModel.userId, scope: viewModel.scope, onSignOut: onSignOut)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            EntryActionDock(
                onPurchaseTap: {
                    if viewModel.selectedItem == nil {
                        viewModel.showMissingConsumableMessage()
                    } else {
                        isPurchaseSheetPresented = true
                    }
                },
                onConsumeCompleted: {
                    Task {
                        await viewModel.quickLogConsume()
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            dashboardTabBar
        }
        .background(
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background.opacity(0.88), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var dashboardTabBar: some View {
        HStack(spacing: 8) {
            ForEach(DashboardTab.allCases) { tab in
                let isSelected = selectedTab == tab

                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))

                        Text(tab.rawValue)
                            .appTypography(AppTypography.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(isSelected ? AppColors.textOnAccent : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? AppColors.buttonPrimaryBackground : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? AppColors.accentSoft.opacity(0.45) : Color.clear, lineWidth: 1)
                    )
                }
                .hapticTap(.light)
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func header(title: String) -> some View {
        HStack {
            Text(title)
                .appTypography(AppTypography.title1)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button("Sign Out") {
                onSignOut()
            }
            .hapticTap(.medium)
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
    }

    private var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            dashboardOverviewHeader
            statusContent
            consumablePicker
            activityMonitorCard
            dashboardCostSection
            dashboardConsumptionSection
            emptyHint
        }
    }

    private var dashboardOverviewHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overview")
                    .font(.system(size: 31, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)

                Text(lastConsumeSubtitle)
                    .appTypography(AppTypography.caption1)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            dashboardPill(
                symbol: todayConsumeCount > 0 ? "flame.fill" : "leaf.fill",
                value: todayConsumeCount > 0 ? formatCompact(todayConsumeCount) : nil,
                color: todayConsumeCount > 0 ? AppColors.accent : Color.green
            )

            dashboardPill(
                symbol: "star.fill",
                value: formatCompact(monthSavedRaw),
                color: Color.orange
            )
        }
    }

    private func dashboardPill(symbol: String, value: String?, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(AppColors.surfaceElevated, in: Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppColors.border.opacity(0.18), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusContent: some View {
        // loading/error state aus viewmodel auch wirklich anzeigen
        if viewModel.state.isLoading {
            ProgressView("Loading dashboard")
                .appTypography(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }

        if let errorMessage = viewModel.state.errorMessage {
            Text(errorMessage)
                .appTypography(AppTypography.caption1)
                .foregroundStyle(Color("Danger"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var consumablePicker: some View {
        if viewModel.state.activeConsumables.isEmpty && !viewModel.state.isLoading {
            Text("No consumables yet")
                .appTypography(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
        } else if viewModel.shouldShowConsumablePicker {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.state.activeConsumables) { item in
                        Button {
                            viewModel.selectConsumable(id: item.id)
                        } label: {
                            Text(item.name)
                                .appTypography(AppTypography.buttonSecondary)
                                .foregroundStyle(viewModel.state.selectedConsumableId == item.id ? AppColors.textOnAccent : AppColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.state.selectedConsumableId == item.id ? AppColors.buttonPrimaryBackground : AppColors.surface)
                                )
                        }
                        .hapticTap(.light)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var activityMonitorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity Monitor")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            DashboardActivityPulseView(entries: selectedEntries)
                .frame(height: 72)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.16),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 2, x: 0, y: 2)
    }

    private var dashboardCostSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cost")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            DashboardStatCard(
                title: "Usage Balance",
                value: formatMoney(monthSavedRaw - monthSpentRaw),
                indicatorColor: monthSavedRaw >= monthSpentRaw ? .green : .red,
                indicatorSymbol: monthSavedRaw >= monthSpentRaw ? "arrow.up" : "arrow.down",
                height: 100,
                valueFont: .system(size: 37, weight: .bold)
            )

            LazyVGrid(columns: dashboardColumns, spacing: 10) {
                DashboardStatCard(
                    title: "Recovered Cost",
                    value: formatMoney(monthSavedRaw),
                    indicatorColor: .green,
                    indicatorSymbol: "leaf.fill",
                    valueFont: .system(size: 24, weight: .bold)
                )

                DashboardStatCard(
                    title: "Total Spent",
                    value: formatMoney(purchaseSpentThisMonth),
                    indicatorColor: AppColors.accent,
                    indicatorSymbol: "cart.fill",
                    valueFont: .system(size: 24, weight: .bold)
                )
            }
        }
    }

    private var dashboardConsumptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Consumption")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            LazyVGrid(columns: dashboardColumns, spacing: 10) {
                DashboardStatCard(
                    title: "Today",
                    value: formatAmount(todayConsumeCount),
                    indicatorColor: AppColors.accent,
                    indicatorSymbol: "plus.circle.fill",
                    valueFont: .system(size: 24, weight: .bold)
                )

                DashboardStatCard(
                    title: "This Month",
                    value: formatAmount(monthConsumeCount),
                    indicatorColor: Color.purple,
                    indicatorSymbol: "chart.bar.fill",
                    valueFont: .system(size: 24, weight: .bold)
                )
            }

            DashboardUsageChartCard(
                entries: selectedEntries,
                period: $selectedChartPeriod,
                unitLabel: viewModel.selectedItem?.effectiveTrackUnit.rawValue ?? "unit"
            )
        }
    }

    @ViewBuilder
    private var emptyHint: some View {
        if viewModel.state.activeConsumables.isEmpty || !viewModel.state.hasAnyEntryData {
            VStack(alignment: .leading, spacing: 10) {
                Text("Start tracking")
                    .appTypography(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(14)
            .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            consumablePicker

            VStack(alignment: .leading, spacing: 10) {
                Text("Entry history")
                    .appTypography(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dashboardColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var selectedEntries: [ConsumeEntry] {
        guard let item = viewModel.selectedItem else { return [] }
        return viewModel.state.entries
            .filter { !$0.isDeleted && $0.consumableItemId == item.id }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var selectedPurchases: [PurchaseEntry] {
        guard let item = viewModel.selectedItem else { return [] }
        return viewModel.state.purchases
            .filter { !$0.isDeleted && $0.consumableItemId == item.id }
    }

    private var lastConsumeSubtitle: String {
        if let value = card(.lastConsume)?.primary.display {
            return "Last Consume: \(value)"
        }
        return "Last Consume: Not available"
    }

    private var todayConsumeCount: Double {
        card(.todayConsume)?.primary.rawNumeric ?? 0
    }

    private var monthConsumeCount: Double {
        card(.monthConsume)?.primary.rawNumeric ?? 0
    }

    private var monthSpentRaw: Decimal {
        decimal(from: card(.monthSpent)?.primary.rawNumeric ?? 0)
    }

    private var monthSavedRaw: Decimal {
        decimal(from: card(.monthSaved)?.primary.rawNumeric ?? 0)
    }

    private var purchaseSpentThisMonth: Decimal {
        let now = Date()
        let interval = Calendar.current.dateInterval(of: .month, for: now) ?? DateInterval(start: now, end: now)
        return selectedPurchases
            .filter { interval.contains($0.purchaseDate) }
            .reduce(.zero) { $0 + $1.price }
    }

    private func card(_ id: DashboardKPI.Kind) -> DashboardKPI? {
        viewModel.state.cards.first { $0.id == id }
    }

    private func decimal(from value: Double) -> Decimal {
        Decimal(value)
    }

    private func formatMoney(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.state.profile?.preferredCurrencyCode ?? "EUR"
        formatter.locale = .current
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private func formatAmount(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func formatCompact(_ value: Double) -> String {
        formatAmount(value)
    }

    private func formatCompact(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        return formatAmount(doubleValue)
    }

    @ViewBuilder
    private var entryActionToast: some View {
        if let message = viewModel.entryActionMessage {
            HStack(spacing: 10) {
                Text(message.text)
                    .appTypography(AppTypography.caption1)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if message.allowsUndo {
                    Button("Undo") {
                        Task {
                            await viewModel.undoLastQuickConsume()
                        }
                    }
                    .hapticTap(.light)
                    .appTypography(AppTypography.buttonSecondary)
                    .foregroundStyle(AppColors.accent)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(message.isError ? Color("Danger").opacity(0.55) : AppColors.accentSoft.opacity(0.45), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 132)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private enum DashboardChartPeriod: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }
}

private struct DashboardChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct DashboardStatCard: View {
    let title: String
    let value: String
    var indicatorColor: Color = AppColors.accent
    var indicatorSymbol: String? = nil
    var height: CGFloat = 80
    var valueFont: Font = .title2.weight(.bold)

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)

            HStack(alignment: .center) {
                Text(value)
                    .font(valueFont)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .monospacedDigit()

                Spacer(minLength: 8)

                if let indicatorSymbol {
                    Image(systemName: indicatorSymbol)
                        .foregroundStyle(indicatorColor)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: height, idealHeight: height, maxHeight: height, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
    }
}

private struct DashboardActivityPulseView: View {
    let entries: [ConsumeEntry]
    @State private var haloAnimate = false

    private var points: [DashboardChartPoint] {
        let cutoff = Date().addingTimeInterval(-8 * 3600)
        return entries
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
            .enumerated()
            .map { index, entry in
                let wave = index.isMultiple(of: 2) ? 0.62 : 0.38
                return DashboardChartPoint(date: entry.timestamp, value: wave)
            }
    }

    var body: some View {
        if points.isEmpty {
            Text("No consume in last 8 hours")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                RuleMark(y: .value("Baseline", 0.5))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.12))

                ForEach(points) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Pulse", point.value)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(AppColors.accent.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("Pulse", point.value)
                    )
                    .symbolSize(140)
                    .foregroundStyle(AppColors.accent)
                }

                if let last = points.last {
                    PointMark(
                        x: .value("Time", last.date),
                        y: .value("Pulse", last.value)
                    )
                    .symbolSize(haloAnimate ? 260 : 120)
                    .foregroundStyle(AppColors.accent.opacity(haloAnimate ? 0.16 : 0.34))
                }
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) { value in
                    AxisGridLine().foregroundStyle(AppColors.textSecondary.opacity(0.12))
                    AxisTick().foregroundStyle(AppColors.textSecondary.opacity(0.2))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .transaction { $0.animation = nil }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    haloAnimate = true
                }
            }
            .onDisappear {
                haloAnimate = false
            }
        }
    }
}

private struct DashboardUsageChartCard: View {
    let entries: [ConsumeEntry]
    @Binding var period: DashboardChartPeriod
    let unitLabel: String

    private var points: [DashboardChartPoint] {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .daily:
            return buckets(count: 7, component: .day, calendar: calendar, now: now)
        case .weekly:
            return buckets(count: 8, component: .weekOfYear, calendar: calendar, now: now)
        case .monthly:
            return buckets(count: 6, component: .month, calendar: calendar, now: now)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Period", selection: $period) {
                ForEach(DashboardChartPeriod.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value("Period", point.date, unit: chartUnit),
                        y: .value(unitLabel, point.value)
                    )
                    .foregroundStyle(AppColors.accent)
                    .cornerRadius(4)
                }
            }
            .chartLegend(.hidden)
            .chartYScale(domain: 0...max(1, points.map(\.value).max() ?? 1))
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(AppColors.textSecondary.opacity(0.12))
                    AxisValueLabel().foregroundStyle(AppColors.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: chartStride)) { value in
                    AxisValueLabel(format: chartFormat)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(height: 150)
            .opacity(points.allSatisfy { $0.value == 0 } ? 0.45 : 1)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
    }

    private var chartUnit: Calendar.Component {
        switch period {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }

    private var chartStride: Calendar.Component {
        chartUnit
    }

    private var chartFormat: Date.FormatStyle {
        switch period {
        case .daily: return .dateTime.weekday(.short)
        case .weekly: return .dateTime.week()
        case .monthly: return .dateTime.month(.abbreviated)
        }
    }

    private func buckets(
        count: Int,
        component: Calendar.Component,
        calendar: Calendar,
        now: Date
    ) -> [DashboardChartPoint] {
        let currentStart = calendar.dateInterval(of: component, for: now)?.start ?? now
        let firstStart = calendar.date(byAdding: component, value: -(count - 1), to: currentStart) ?? currentStart

        return (0..<count).map { offset in
            let start = calendar.date(byAdding: component, value: offset, to: firstStart) ?? firstStart
            let end = calendar.date(byAdding: component, value: 1, to: start) ?? start
            let total = entries
                .filter { $0.timestamp >= start && $0.timestamp < end }
                .reduce(0) { $0 + $1.amount }

            return DashboardChartPoint(date: start, value: total)
        }
    }
}

private struct PurchaseEntrySheet: View {
    let item: ConsumableItem?
    let onSave: (Decimal, Double, ConsumeUnit) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var priceText = ""
    @State private var quantityText = ""
    @State private var selectedUnit: ConsumeUnit

    init(item: ConsumableItem?, onSave: @escaping (Decimal, Double, ConsumeUnit) -> Void) {
        self.item = item
        self.onSave = onSave
        _quantityText = State(initialValue: item.map { Self.formatNumber($0.effectiveDefaultPurchaseAmount) } ?? "")
        _selectedUnit = State(initialValue: item?.effectiveDefaultPurchaseUnit ?? .piece)
    }

    private var parsedPrice: Decimal? {
        Decimal(string: priceText.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedQuantity: Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        guard let price = parsedPrice, let quantity = parsedQuantity else { return false }
        return price > 0 && quantity > 0 && item != nil
    }

    private var previewText: String? {
        guard let item, let price = parsedPrice, let quantity = parsedQuantity, quantity > 0 else { return nil }
        guard let quantityInCostUnit = convertedQuantity(quantity, from: selectedUnit, item: item), quantityInCostUnit > 0 else {
            return "Set conversion in consumable settings"
        }

        let costPerUnit = price / Decimal(quantityInCostUnit)
        let costPerConsume = costPerUnit * Decimal(item.effectiveCostAmountPerTrack)
        return "≈ \(formatMoney(costPerConsume)) per \(item.effectiveTrackName)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item?.name ?? "No consumable selected")
                        .appTypography(AppTypography.headline)
                }

                Section {
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)

                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }

                if let previewText {
                    Section {
                        Text(previewText)
                            .appTypography(AppTypography.caption1)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("New Purchase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let parsedPrice, let parsedQuantity else { return }
                        onSave(parsedPrice, parsedQuantity, selectedUnit)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func convertedQuantity(_ quantity: Double, from unit: ConsumeUnit, item: ConsumableItem) -> Double? {
        if unit == item.effectiveCostUnit {
            return quantity
        }

        if unit == .pack, item.effectiveCostUnit != .pack {
            return quantity * item.effectiveDefaultPurchaseAmount
        }

        return nil
    }

    private func formatMoney(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private static func formatNumber(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
#Preview {
    DashboardView(userId: "preview", scope: .registered, onSignOut: {})
}
