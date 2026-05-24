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
    private enum ConsumableActionTarget: Identifiable {
        case delete(ConsumableItem)
        case relapse(ConsumableItem)

        var id: String {
            switch self {
            case .delete(let item): return "delete-\(item.id)"
            case .relapse(let item): return "relapse-\(item.id)"
        }
    }
    }
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
    @State private var selectedDetailsMode: DashboardDetailsMode = .purchases
    @State private var isRecoveryHistoryExpanded = false
    @State private var isConsumableMenuExpanded = false
    @State private var isQuickAddConsumablePresented = false
    @State private var editConsumableRoute: ConsumableFormRoute?
    @State private var addConsumableError: String?
    @State private var pendingConsumableAction: ConsumableActionTarget?
    @State private var pendingStartQuitItem: ConsumableItem?
    @State private var pendingStartQuitDate: Date = .now
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let onSignOut: () -> Void

    init(userId: String, scope: FirestoreAccountScope, onSignOut: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userId: userId, scope: scope))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(userId: userId, scope: scope))
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
        .sheet(isPresented: $isQuickAddConsumablePresented) {
            OnboardingView(
                initialProfile: viewModel.state.profile,
                onCompleteConsumable: { draft in
                    Task {
                        await saveConsumableFromDraft(draft)
                        isQuickAddConsumablePresented = false
                    }
                },
                onDismissConsumableFlow: {
                    isQuickAddConsumablePresented = false
                }
            )
        }
        .sheet(item: $editConsumableRoute) { route in
            ConsumableFormView(item: route.item) { submission, existingItem in
                let model = settingsViewModel
                return await model.saveConsumable(
                    name: submission.name,
                    category: submission.category,
                    consumePresetName: submission.consumePresetName,
                    trackName: submission.trackName,
                    trackAmountText: submission.trackAmountText,
                    trackUnit: submission.trackUnit,
                    usageMethod: submission.usageMethod,
                    costAmountPerTrackText: submission.costAmountPerTrackText,
                    costUnit: submission.costUnit,
                    purchaseName: submission.purchaseName,
                    purchaseAmountText: submission.purchaseAmountText,
                    purchaseUnit: submission.purchaseUnit,
                    existingItem: existingItem
                )
            }
        }
        .alert("Could not add consumable", isPresented: Binding(get: { addConsumableError != nil }, set: { if !$0 { addConsumableError = nil } })) {
            Button("OK", role: .cancel) {
                addConsumableError = nil
            }
        } message: {
            Text(addConsumableError ?? "Unknown error")
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
        .confirmationDialog(
            "Delete consumable?",
            isPresented: Binding(
                get: {
                    if case .delete = pendingConsumableAction { return true }
                    return false
                },
                set: { if !$0 { pendingConsumableAction = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                guard case .delete(let item) = pendingConsumableAction else { return }
                Task {
                    await settingsViewModel.archiveConsumable(item)
                    pendingConsumableAction = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingConsumableAction = nil
            }
        } message: {
            Text("This hides \(actionItemName) from dashboard.")
        }
        .sheet(item: $pendingStartQuitItem) { item in
            NavigationStack {
                Form {
                    Section {
                        Text(item.name)
                            .appTypography(AppTypography.headline)
                        Text("When did you quit?")
                            .appTypography(AppTypography.caption1)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Section("Quit date") {
                        DatePicker("Quit date", selection: $pendingStartQuitDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                .navigationTitle("Start quitting")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            pendingStartQuitItem = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Start") {
                            let selectedItem = item
                            let quitDate = pendingStartQuitDate
                            Task {
                                await settingsViewModel.startQuitPlan(for: selectedItem, startDate: quitDate)
                                pendingStartQuitItem = nil
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Log relapse?",
            isPresented: Binding(
                get: {
                    if case .relapse = pendingConsumableAction { return true }
                    return false
                },
                set: { if !$0 { pendingConsumableAction = nil } }
            )
        ) {
            Button("Relapse", role: .destructive) {
                guard case .relapse(let item) = pendingConsumableAction else { return }
                Task {
                    viewModel.selectConsumable(id: item.id)
                    await viewModel.relapseSelectedPlan()
                    pendingConsumableAction = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingConsumableAction = nil
            }
        } message: {
            Text("This logs relapse for \(actionItemName).")
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
                header(title: viewModel.isSelectedConsumableInQuitMode ? "Recovery" : "Details")
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
            if !viewModel.isSelectedConsumableInQuitMode {
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
            }

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
                        Image(systemName: tabIcon(for: tab))
                            .font(.system(size: 19, weight: .semibold))

                        Text(tabTitle(for: tab))
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

    private func tabTitle(for tab: DashboardTab) -> String {
        if tab == .details && viewModel.isSelectedConsumableInQuitMode {
            return "Recovery"
        }
        return tab.rawValue
    }

    private func tabIcon(for tab: DashboardTab) -> String {
        if tab == .details && viewModel.isSelectedConsumableInQuitMode {
            return "flag.checkered"
        }
        return tab.icon
    }

    private func header(title: String) -> some View {
        HStack {
            Text(title)
                .appTypography(AppTypography.title1)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusContent
            consumablePicker

            if viewModel.isSelectedConsumableInQuitMode {
                quitDashboardContent
            } else {
                dashboardOverviewHeader
                activityMonitorCard
                dashboardCostSection
                dashboardConsumptionSection
                emptyHint
            }
        }
    }

    private var quitDashboardContent: some View {
        VStack(spacing: 12) {
            quitStreakModule

            QuitPlanStatCard(
                systemImage: "eurosign.circle.fill",
                title: "Money saved",
                value: formatMoney(viewModel.selectedQuitMetrics.moneySaved)
            )

            HStack(spacing: 10) {
                QuitPlanStatCard(
                    systemImage: "scalemass.fill",
                    title: "Units avoided",
                    value: "\(formatAmount(viewModel.selectedQuitMetrics.unitsAvoided)) \(viewModel.selectedItem?.effectiveTrackUnit.rawValue ?? "unit")"
                )

                QuitPlanStatCard(
                    systemImage: "flame.fill",
                    title: "Daily burn rate",
                    value: formatMoney(viewModel.selectedQuitMetrics.dailyBurnRate)
                )
            }

            quitNextStageCard
        }
    }

    private var quitStreakModule: some View {
        let metrics = viewModel.selectedQuitMetrics
        let modules = [
            QuitStreakModule(label: "Days", value: max(0, metrics.daysQuit)),
            QuitStreakModule(label: "Weeks", value: max(0, metrics.daysQuit / 7)),
            QuitStreakModule(label: "Months", value: max(0, metrics.daysQuit / 30)),
            QuitStreakModule(label: "Years", value: max(0, metrics.daysQuit / 365))
        ]

        return VStack(spacing: 10) {
            Text("Quit Streak")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: dashboardColumns, spacing: 10) {
                ForEach(modules) { module in
                    QuitPlanStreakCard(module: module)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background((colorScheme == .light ? Color(.systemBackground) : Color.clear), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(colorScheme == .light ? 0.32 : 0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
    }

    private var quitNextStageCard: some View {
        let template = viewModel.selectedRecoveryTemplate
        let metrics = viewModel.selectedQuitMetrics
        let next = template?.stages.first { $0.days > metrics.daysQuit }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: next == nil ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(next == nil ? Color.green : AppColors.accent)
                    .frame(width: 30, height: 30)
                    .background((next == nil ? Color.green : AppColors.accent).opacity(0.14), in: Circle())

                Text("Next recovery stage")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            if let next {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    Text(next.durationLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text(next.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(next.description)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                Text("All template stages completed")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Keep momentum. Recovery timeline fully cleared.")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background((colorScheme == .light ? Color(.systemBackground) : Color.clear), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(colorScheme == .light ? 0.32 : 0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
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
            HStack(spacing: 8) {
                Text("No consumables yet")
                    .appTypography(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Button {
                    isQuickAddConsumablePresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textOnAccent)
                        .frame(width: 32, height: 32)
                        .background(AppColors.buttonPrimaryBackground, in: Capsule())
                }
                .hapticTap(.light)
                .buttonStyle(.plain)
            }
        } else if viewModel.shouldShowConsumablePicker {
            Button {
                isConsumableMenuExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedItem?.name ?? "Select consumable")
                        .appTypography(AppTypography.buttonSecondary)
                        .foregroundStyle(AppColors.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .rotationEffect(.degrees(isConsumableMenuExpanded ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.surface, in: Capsule())
            }
            .hapticTap(.light)
            .buttonStyle(.plain)
            .overlay(alignment: .topLeading) {
                if isConsumableMenuExpanded {
                    VStack(spacing: 2) {
                        ForEach(viewModel.state.activeConsumables) { item in
                            let hasActiveQuit = itemHasActiveQuitPlan(item)

                            HStack(spacing: 8) {
                                Button {
                                    viewModel.selectConsumable(id: item.id)
                                    isConsumableMenuExpanded = false
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(item.name)
                                            .appTypography(AppTypography.buttonSecondary)
                                            .foregroundStyle(viewModel.state.selectedConsumableId == item.id ? Color.white : Color.black)

                                        if hasActiveQuit {
                                            Text("QUIT")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(viewModel.state.selectedConsumableId == item.id ? Color.white : Color.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(
                                                    Capsule()
                                                        .fill(viewModel.state.selectedConsumableId == item.id ? Color.white.opacity(0.2) : AppColors.accent.opacity(0.14))
                                                )
                                        }

                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(viewModel.state.selectedConsumableId == item.id ? AppColors.buttonPrimaryBackground : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)

                Menu {
                    Button("Modify") {
                        editConsumableRoute = ConsumableFormRoute(item: item)
                    }
                    if hasActiveQuit {
                        Button("Relapse") {
                            pendingConsumableAction = .relapse(item)
                        }
                    } else {
                        Button("Start quitting") {
                            pendingStartQuitDate = .now
                            pendingStartQuitItem = item
                        }
                    }
                    Button("Delete", role: .destructive) {
                        pendingConsumableAction = .delete(item)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.75))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 8)
        }

                        Divider()
                            .overlay(AppColors.border.opacity(0.4))

                        Button {
                            isConsumableMenuExpanded = false
                            isQuickAddConsumablePresented = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text("Add consumable")
                                Spacer()
                            }
                            .appTypography(AppTypography.buttonSecondary)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
                    )
                    .offset(y: 44)
                    .zIndex(20)
                    .shadow(color: Color.black.opacity(0.28), radius: 20, x: 0, y: 14)
                    .frame(minWidth: 280, alignment: .leading)
                }
            }
            .zIndex(isConsumableMenuExpanded ? 30 : 1)
        }
    }

    private var actionItemName: String {
        switch pendingConsumableAction {
        case .delete(let item), .relapse(let item):
            return item.name
        case .none:
            return "this consumable"
        }
    }

    private func itemHasActiveQuitPlan(_ item: ConsumableItem) -> Bool {
        viewModel.state.quitPlans.contains {
            $0.consumableItemId == item.id && !$0.isArchived && ($0.status == .active || $0.status == .paused)
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

            if viewModel.isSelectedConsumableInQuitMode {
                quitRecoveryContent
            } else {
                detailsSummary
                detailsModePicker
                selectedDetailsList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quitRecoveryContent: some View {
        let stages = viewModel.selectedRecoveryTemplate?.stages ?? []
        let daysQuit = viewModel.selectedQuitMetrics.daysQuit
        let achievedCount = stages.filter { daysQuit >= $0.days }.count
        let achievedStages = stages.filter { daysQuit >= $0.days }
        let upcomingStages = stages.filter { daysQuit < $0.days }
        let isCollapsible = achievedStages.count >= 4
        let visibleAchievedStages = isCollapsible ? Array(achievedStages.suffix(2)) : achievedStages
        let remainingAchievedIDs = Set(visibleAchievedStages.map(\.id))
        let hasHiddenAchievedHistory = achievedStages.contains { !remainingAchievedIDs.contains($0.id) }
        let showsGenericTimelineInfo = {
            guard let category = viewModel.selectedItem?.category else { return false }
            return category == .medicine || category == .custom
        }()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Timeline")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text("\(achievedCount) of \(stages.count) milestones achieved")
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)

            if showsGenericTimelineInfo {
                Text("Generic timeline: based on common behavior-change phases, not substance-specific recovery.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(spacing: 16) {
                if isCollapsible && hasHiddenAchievedHistory {
                    QuitPlanPrimaryButton(title: isRecoveryHistoryExpanded ? "Hide Achieved History" : "Show Achieved History") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRecoveryHistoryExpanded.toggle()
                        }
                    }
                    .overlay(alignment: .trailing) {
                        Image(systemName: isRecoveryHistoryExpanded ? "chevron.up" : "chevron.down")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.background)
                            .padding(.trailing, 16)
                            .allowsHitTesting(false)
                    }
                }

                if isRecoveryHistoryExpanded || !isCollapsible {
                    VStack(spacing: 20) {
                        ForEach(Array((isCollapsible ? achievedStages : stages).enumerated()), id: \.element.id) { index, stage in
                            QuitPlanMilestoneRow(
                                stage: stage,
                                achieved: daysQuit >= stage.days,
                                showLine: index < (isCollapsible ? achievedStages : stages).count - 1
                            )
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        ForEach(Array(visibleAchievedStages.enumerated()), id: \.element.id) { index, stage in
                            QuitPlanMilestoneRow(
                                stage: stage,
                                achieved: true,
                                showLine: index < visibleAchievedStages.count - 1
                            )
                        }
                    }
                    .overlay(alignment: .top) {
                        if visibleAchievedStages.count > 1 {
                            quitPlanFadedTop
                        }
                    }
                }

                if isCollapsible && !upcomingStages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        VStack(spacing: 20) {
                            ForEach(Array(upcomingStages.enumerated()), id: \.element.id) { index, stage in
                                QuitPlanMilestoneRow(
                                    stage: stage,
                                    achieved: false,
                                    showLine: index < upcomingStages.count - 1
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(AppColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var quitPlanFadedTop: some View {
        LinearGradient(
            colors: [
                AppColors.surfaceElevated,
                AppColors.surfaceElevated.opacity(0.88),
                AppColors.surfaceElevated.opacity(0.62),
                AppColors.surfaceElevated.opacity(0.28),
                AppColors.surfaceElevated.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 53)
        .allowsHitTesting(false)
    }

    private var detailsSummary: some View {
        LazyVGrid(columns: dashboardColumns, spacing: 10) {
            DashboardStatCard(
                title: "Purchases",
                value: "\(selectedPurchases.count)",
                indicatorColor: AppColors.accent,
                indicatorSymbol: "cart.fill",
                valueFont: .system(size: 24, weight: .bold)
            )

            DashboardStatCard(
                title: "Consumes",
                value: "\(selectedEntries.count)",
                indicatorColor: Color.purple,
                indicatorSymbol: "plus.circle.fill",
                valueFont: .system(size: 24, weight: .bold)
            )
        }
    }

    private var detailsModePicker: some View {
        Picker("Entries", selection: $selectedDetailsMode) {
            ForEach(DashboardDetailsMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var selectedDetailsList: some View {
        switch selectedDetailsMode {
        case .purchases:
            purchaseEntryList
        case .consumes:
            consumeEntryList
        }
    }

    private var purchaseEntryList: some View {
        DashboardEntrySection(title: "Purchases") {
            if selectedPurchases.isEmpty {
                detailEmptyRow("No purchases yet")
            } else {
                ForEach(selectedPurchases.sorted { $0.purchaseDate > $1.purchaseDate }) { purchase in
                    detailRow(
                        icon: "cart.fill",
                        color: AppColors.accent,
                        title: formatMoney(purchase.price),
                        subtitle: "\(formatAmount(purchase.quantity)) \(purchase.unit.rawValue) • \(formatDateTime(purchase.purchaseDate))",
                        trailing: costPerUnitText(purchase)
                    )
                }
            }
        }
    }

    private var consumeEntryList: some View {
        DashboardEntrySection(title: "Consumes") {
            if selectedEntries.isEmpty {
                detailEmptyRow("No consumes yet")
            } else {
                ForEach(selectedEntries.sorted { $0.timestamp > $1.timestamp }) { entry in
                    detailRow(
                        icon: "plus.circle.fill",
                        color: Color.purple,
                        title: "\(formatAmount(entry.amount)) \(entry.unit.rawValue)",
                        subtitle: formatDateTime(entry.timestamp),
                        trailing: nil
                    )
                }
            }
        }
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

    private func saveConsumableFromDraft(_ draft: OnboardingDraft) async {
        let repository = FirestoreTrackingRepository()
        let itemId = UUID().uuidString
        let now = Date()

        let item = ConsumableItem(
            id: itemId,
            userId: viewModel.userId,
            name: draft.firstConsumableName,
            category: draft.firstConsumableCategory,
            defaultUnit: draft.firstConsumableUnit,
            usageMethod: mapUsageMethod(draft.firstConsumableUsageMethod),
            pricingMode: mapPricingMode(draft.firstConsumablePricingMode),
            defaultPurchaseUnit: draft.firstConsumablePurchaseUnit,
            defaultAmountPerConsume: draft.firstConsumableTrackAmount,
            defaultUnitsPerPurchase: draft.firstConsumableUnitsPerPurchase,
            defaultCostPerConsume: nil,
            note: nil,
            consumePresetName: draft.firstConsumableTrackName,
            purchasePresetName: draft.firstConsumablePurchaseName,
            trackName: draft.firstConsumableTrackName,
            trackAmount: draft.firstConsumableTrackAmount,
            trackUnit: draft.firstConsumableTrackUnit,
            costAmountPerTrack: draft.firstConsumableCostAmountPerTrack,
            costUnit: draft.firstConsumableCostUnit,
            purchaseName: draft.firstConsumablePurchaseName,
            defaultPurchaseAmount: draft.firstConsumableDefaultPurchaseAmount,
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )

        do {
            try await repository.saveConsumableItem(item, scope: viewModel.scope)

            if draft.initialMode == .quit {
                let plan = QuitPlan(
                    id: UUID().uuidString,
                    userId: viewModel.userId,
                    consumableItemId: item.id,
                    status: .active,
                    mode: .quit,
                    startDate: draft.quitStartDate,
                    baselineDailyConsume: draft.baselineDailyConsume,
                    baselineCostPerConsume: draft.baselineCostPerConsume,
                    templateId: RecoveryTemplateRegistry.defaultTemplateID(for: item.category),
                    category: item.category,
                    createdAt: now,
                    updatedAt: now
                )

                try await repository.saveQuitPlan(plan, scope: viewModel.scope)
            }

            viewModel.selectConsumable(id: item.id)
        } catch {
            addConsumableError = error.localizedDescription
        }
    }

    private func mapUsageMethod(_ value: OnboardingUsageMethod) -> ConsumableUsageMethod {
        switch value {
        case .perPiece: return .perPiece
        case .perSession: return .perSession
        case .perGram: return .perGram
        case .perMilliliter: return .perMilliliter
        case .perCup: return .perCup
        case .perDose: return .perDose
        case .custom: return .custom
        }
    }

    private func mapPricingMode(_ value: OnboardingPricingMode) -> ConsumablePricingMode {
        switch value {
        case .perUnit: return .perUnit
        case .perPurchase: return .perPurchase
        }
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

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func costPerUnitText(_ purchase: PurchaseEntry) -> String {
        guard purchase.calculatedCostPerUnit > 0 else { return "—" }
        return "\(formatMoney(purchase.calculatedCostPerUnit))/\(purchase.unit.rawValue)"
    }

    private func detailEmptyRow(_ text: String) -> some View {
        Text(text)
            .appTypography(AppTypography.caption1)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }

    private func detailRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        trailing: String?
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .appTypography(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .appTypography(AppTypography.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 8)

            if let trailing {
                Text(trailing)
                    .appTypography(AppTypography.caption1)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.vertical, 8)
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

private enum DashboardDetailsMode: String, CaseIterable, Identifiable {
    case purchases = "Purchases"
    case consumes = "Consumes"

    var id: String { rawValue }
}

private struct DashboardChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct QuitStreakModule: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

private struct QuitPlanStreakCard: View {
    let module: QuitStreakModule
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Text("\(module.value)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)

            Text(module.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(16)
        .frame(height: 98)
        .background((colorScheme == .light ? Color(.systemBackground) : Color.clear), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.border.opacity(colorScheme == .light ? 0.32 : 0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
    }
}

private struct QuitPlanStatCard: View {
    let systemImage: String
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(AppColors.accent)
                .frame(width: 44, height: 44)
                .background(AppColors.accent.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()
        }
        .padding(16)
        .background((colorScheme == .light ? Color(.systemBackground) : Color.clear), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(colorScheme == .light ? 0.32 : 0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

private struct QuitPlanPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.textPrimary)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.background)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

private struct QuitPlanMilestoneRow: View {
    let stage: RecoveryStage
    let achieved: Bool
    let showLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: achieved ? "checkmark.circle.fill" : "lock.circle.fill")
                    .font(.title2)
                    .foregroundStyle(achieved ? AppColors.textPrimary : AppColors.textSecondary)

                if showLine {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(stage.durationLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)

                Text(stage.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(stage.description)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
    }
}

private struct DashboardStatCard: View {
    let title: String
    let value: String
    var indicatorColor: Color = AppColors.accent
    var indicatorSymbol: String? = nil
    var height: CGFloat = 80
    var valueFont: Font = .title2.weight(.bold)
    @Environment(\.colorScheme) private var colorScheme

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
        .background((colorScheme == .light ? Color(.systemBackground) : Color.clear), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border.opacity(colorScheme == .light ? 0.32 : 0.16), lineWidth: 1)
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

private struct DashboardEntrySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.border.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 2, x: 0, y: 2)
        }
    }
}

private struct QuitOverviewHeader: View {
    let itemName: String
    let plan: QuitPlan?
    let metrics: DashboardQuitMetrics
    let formatMoney: (Decimal) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quit mode")
                        .font(.system(size: 31, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(itemName)
                        .appTypography(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Text(plan?.status.rawValue.capitalized ?? "Active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textOnAccent)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(AppColors.buttonPrimaryBackground, in: Capsule())
            }

            HStack(spacing: 8) {
                dashboardPill(symbol: "calendar", value: "\(metrics.daysQuit)d", color: .green)
                dashboardPill(symbol: "leaf.fill", value: formatMoney(metrics.moneySaved), color: .green)
            }
        }
    }

    private func dashboardPill(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(AppColors.surfaceElevated, in: Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppColors.border.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct RelapseDock: View {
    let onRelapseTap: () -> Void

    var body: some View {
        Button {
            onRelapseTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .font(.system(size: 22, weight: .bold))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Relapse")
                        .appTypography(AppTypography.headline)

                    Text("Return to tracking")
                        .appTypography(AppTypography.caption1)
                        .foregroundStyle(AppColors.textOnAccent.opacity(0.75))
                }

                Spacer()
            }
            .foregroundStyle(AppColors.textOnAccent)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(AppColors.buttonPrimaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.accentSoft.opacity(0.45), lineWidth: 1)
            )
        }
        .hapticTap(.medium)
        .buttonStyle(.plain)
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
