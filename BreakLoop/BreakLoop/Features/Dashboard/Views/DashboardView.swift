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
            VStack(alignment: .leading, spacing: 14) {
                header(title: "Dashboard")
                dashboardContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(title: "Settings")
                settingsContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(AppColors.background)
    }

    private var bottomControls: some View {
        VStack(spacing: 0) {
            EntryActionDock(
                onPurchaseTap: {
                    // placeholder bis purchase entry flow integriert ist
                },
                onConsumeCompleted: {
                    // placeholder bis consume entry flow integriert ist
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
        VStack(alignment: .leading, spacing: 14) {
            statusContent
            consumableTabs
            kpiGrid
            emptyHint
        }
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
    private var consumableTabs: some View {
        if viewModel.state.activeConsumables.isEmpty && !viewModel.state.isLoading {
            Text("No consumables yet")
                .appTypography(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
        } else {
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

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(viewModel.state.cards) { card in
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.title)
                        .appTypography(AppTypography.caption1)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(card.primary.display)
                        .appTypography(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let secondary = card.secondary {
                        Text(secondary)
                            .appTypography(AppTypography.caption2)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var emptyHint: some View {
        if viewModel.state.activeConsumables.isEmpty || !viewModel.state.hasAnyEntryData {
            VStack(alignment: .leading, spacing: 10) {
                Text("Start tracking")
                    .appTypography(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Add your first consume and purchase entries to unlock live insights.")
                    .appTypography(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Text("Use the bottom dock to log consume or purchase.")
                    .appTypography(AppTypography.caption1)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(14)
            .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Entry history")
                .appTypography(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Long-press manage flow will list consume and purchase entries for the selected consumable here.")
                .appTypography(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dashboard settings")
                .appTypography(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Tracking preferences and account actions will live here.")
                .appTypography(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
#Preview {
    DashboardView(userId: "preview", scope: .registered, onSignOut: {})
}
