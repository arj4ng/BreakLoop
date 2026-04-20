import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dashboard")
                .appTypography(AppTypography.title1)
                .foregroundStyle(AppColors.textPrimary)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(AppColors.background)
        .tint(AppColors.accent)
    }
}

#Preview {
    DashboardView()
}
