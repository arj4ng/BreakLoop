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
    // StateObject hält viewmodel über view refreshes stabil
    @StateObject private var viewModel: DashboardViewModel
    let onSignOut: () -> Void

    init(userId: String, scope: FirestoreAccountScope, onSignOut: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userId: userId, scope: scope))
        self.onSignOut = onSignOut
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Dashboard")
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(AppColors.background)
        .tint(AppColors.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
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
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [AppColors.background.opacity(0), AppColors.background.opacity(0.88), AppColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .task {
            // task läuft beim anzeigen der view und startet realtime listener
            viewModel.start()
        }
    }
}
#Preview {
    DashboardView(userId: "preview", scope: .registered, onSignOut: {})
}
