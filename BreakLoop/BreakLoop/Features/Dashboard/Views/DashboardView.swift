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
    let onSignOut: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dashboard")
                    .appTypography(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button("Sign Out") {
                    onSignOut()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(AppColors.background)
        .tint(AppColors.accent)
    }
}
#Preview {
    DashboardView(onSignOut: {})
}
