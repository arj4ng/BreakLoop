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
    @State private var isPurchaseSheetPresented = false
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
            PurchaseEntrySheet(item: viewModel.selectedItem) { price, quantity in
                Task {
                    await viewModel.savePurchase(price: price, quantity: quantity)
                    isPurchaseSheetPresented = false
                }
            }
            .presentationDetents([.height(300)])
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
        VStack(alignment: .leading, spacing: 14) {
            statusContent
            consumablePicker
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

private struct PurchaseEntrySheet: View {
    let item: ConsumableItem?
    let onSave: (Decimal, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var priceText = ""
    @State private var quantityText = ""

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
                        onSave(parsedPrice, parsedQuantity)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
#Preview {
    DashboardView(userId: "preview", scope: .registered, onSignOut: {})
}
