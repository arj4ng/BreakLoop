// BreakLoop/ BreakLoop/ Features/ Settings/ Views/ SettingsView.swift

// Settings view
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
import Combine


// MARK: ┏━ [10 SETTINGS] SettingsView
// MARK: ┗━ settings screen mit navigation zu consumable verwaltung

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var isProfileSheetPresented = false
    @State private var isRegisterSheetPresented = false
    private let authService: AuthServiceProtocol = FirebaseAuthService()
    let onSignOut: () -> Void

    init(userId: String, scope: FirestoreAccountScope, onSignOut: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(userId: userId, scope: scope))
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ConsumablesSettingsView(viewModel: viewModel)
                    } label: {
                        settingsRow(icon: "slider.horizontal.3", title: "Consumables", subtitle: "\(viewModel.consumables.count) active")
                    }
                }

                Section {
                    Button {
                        isProfileSheetPresented = true
                    } label: {
                        settingsRow(icon: "person.crop.circle", title: "Profile", subtitle: viewModel.profile?.displayName)
                    }
                    .buttonStyle(.plain)
                    settingsRow(icon: "bell.badge", title: "Notifications")
                    settingsRow(icon: "externaldrive", title: "Data")
                }

                Section {
                    Button(role: .destructive) {
                        onSignOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .task {
                await viewModel.loadConsumables()
                await viewModel.loadProfile()
            }
            .sheet(isPresented: $isProfileSheetPresented) {
                ProfileSettingsSheet(
                    viewModel: viewModel,
                    onInviteSignup: {
                        isProfileSheetPresented = false
                        isRegisterSheetPresented = true
                    }
                )
            }
            .sheet(isPresented: $isRegisterSheetPresented) {
                RegisterView(authService: authService, onRegistered: {
                    isRegisterSheetPresented = false
                    Task {
                        await viewModel.loadProfile()
                    }
                }, onClose: {
                    isRegisterSheetPresented = false
                })
            }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }
}

private struct ProfileSettingsSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onInviteSignup: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSavingProfile = false
    @State private var isChangingPassword = false

    private var isGuest: Bool { viewModel.profile?.isGuestAccount ?? false }
    private var emailText: String { viewModel.profile?.email ?? "No email" }
    private var canSaveProfile: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSavingProfile
    }
    private var canChangePassword: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6 &&
        !isChangingPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                if isGuest {
                    Section("Profile") {
                        Text("Guest account")
                            .font(.headline)
                        Text("Create an account to edit profile settings and security.")
                            .foregroundStyle(AppColors.textSecondary)

                        Button("Sign up") {
                            onInviteSignup()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                    }
                } else {
                    Section("Profile Info") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Display name")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)

                            TextField("Display name", text: $displayName)
                                .textInputAutocapitalization(.words)
                        }
                        LabeledContent("Email", value: emailText)
                            .foregroundStyle(AppColors.textSecondary)

                        Button(isSavingProfile ? "Saving..." : "Save profile") {
                            Task {
                                isSavingProfile = true
                                let saved = await viewModel.saveProfile(displayName: displayName)
                                isSavingProfile = false
                                if saved { dismiss() }
                            }
                        }
                        .disabled(!canSaveProfile)
                    }

                    Section("Security") {
                        SecureField("Current password", text: $currentPassword)
                        SecureField("New password", text: $newPassword)
                        SecureField("Confirm new password", text: $confirmPassword)

                        Button(isChangingPassword ? "Updating..." : "Update password") {
                            Task {
                                isChangingPassword = true
                                let changed = await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                                isChangingPassword = false
                                if changed {
                                    currentPassword = ""
                                    newPassword = ""
                                    confirmPassword = ""
                                }
                            }
                        }
                        .disabled(!canChangePassword)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.loadProfile()
                displayName = viewModel.profile?.displayName ?? ""
            }
            .onReceive(viewModel.$profile) { profile in
                guard let profile else { return }
                if displayName.isEmpty {
                    displayName = profile.displayName
                }
            }
        }
    }
}

private struct ConsumablesSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var formRoute: ConsumableFormRoute?
    @State private var pendingArchiveItem: ConsumableItem?

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading")
            }

            Section {
                ForEach(viewModel.consumables) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            formRoute = ConsumableFormRoute(item: item)
                        } label: {
                            consumableRow(item)
                        }
                        .buttonStyle(.plain)

                        quitControls(for: item)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            pendingArchiveItem = item
                        } label: {
                            Label("Remove", systemImage: "archivebox")
                        }
                    }
                }

                if viewModel.consumables.isEmpty && !viewModel.isLoading {
                    Text("No consumables")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Consumables")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    formRoute = ConsumableFormRoute(item: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $formRoute) { route in
            ConsumableFormView(item: route.item) { submission, existingItem in
                await viewModel.saveConsumable(
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
        .confirmationDialog(
            "Remove consumable?",
            isPresented: Binding(
                get: { pendingArchiveItem != nil },
                set: { if !$0 { pendingArchiveItem = nil } }
            ),
            presenting: pendingArchiveItem
        ) { item in
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.archiveConsumable(item)
                    pendingArchiveItem = nil
                }
            }
        } message: { item in
            Text("\(item.name) will be hidden. Old logs stay saved.")
        }
        .task {
            await viewModel.loadConsumables()
        }
    }

    private func consumableRow(_ item: ConsumableItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: item.category))
                .foregroundStyle(AppColors.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(item.effectiveTrackName) • \(item.effectiveCostAmountPerTrack) \(item.effectiveCostUnit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    @ViewBuilder
    private func quitControls(for item: ConsumableItem) -> some View {
        if let plan = viewModel.activeQuitPlan(for: item) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(plan.status == .paused ? "Quit paused" : "Quit active", systemImage: "flag.checkered")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.accent)

                    Spacer()

                    Text(plan.startDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: 8) {
                    if plan.status == .paused {
                        settingsActionButton("Resume", icon: "play.fill") {
                            await viewModel.resumeQuitPlan(plan)
                        }
                    } else {
                        settingsActionButton("Pause", icon: "pause.fill") {
                            await viewModel.pauseQuitPlan(plan)
                        }
                    }

                    settingsActionButton("End", icon: "checkmark.circle") {
                        await viewModel.endQuitPlan(plan)
                    }

                    settingsActionButton("Relapse", icon: "arrow.uturn.backward", role: .destructive) {
                        await viewModel.relapseQuitPlan(plan)
                    }
                }
            }
            .padding(12)
            .background(AppColors.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Button {
                Task {
                    await viewModel.startQuitPlan(for: item)
                }
            } label: {
                Label("Start Quit Plan", systemImage: "flag.checkered")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
    }

    private func settingsActionButton(
        _ title: String,
        icon: String,
        role: ButtonRole? = nil,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        Button(role: role) {
            Task {
                await action()
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(role == .destructive ? .red : AppColors.accent)
    }

    private func icon(for category: ConsumableCategory) -> String {
        switch category {
        case .nicotine: return "smoke.fill"
        case .alcohol: return "wineglass.fill"
        case .cannabis: return "leaf.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .medicine: return "pills.fill"
        case .custom: return "circle.grid.2x2.fill"
        }
    }
}

struct ConsumableFormRoute: Identifiable {
    let id: String
    let item: ConsumableItem?

    init(item: ConsumableItem?) {
        self.item = item
        self.id = item?.id ?? "new-\(UUID().uuidString)"
    }
}

struct ConsumableFormView: View {
    let item: ConsumableItem?
    let onSave: @MainActor (ConsumableFormSubmission, ConsumableItem?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @StateObject private var form: ConsumableFormState
    @State private var isSaving = false

    private var consumePresets: [ConsumableSetupPreset] {
        ConsumableSetupPresets.consumePresets(for: form.category)
    }

    private var selectedConsumePreset: ConsumableSetupPreset {
        consumePresets.first(where: { $0.id == form.consumePresetId }) ?? ConsumableSetupPresets.fallbackPreset
    }

    private var canSave: Bool {
        form.canSave
    }

    init(item: ConsumableItem?, onSave: @escaping @MainActor (ConsumableFormSubmission, ConsumableItem?) async -> Bool) {
        self.item = item
        self.onSave = onSave
        _form = StateObject(wrappedValue: ConsumableFormState(item: item))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $form.name)
                        .textInputAutocapitalization(.words)

                    Picker("Type", selection: $form.category) {
                        ForEach(ConsumableCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }

                    Picker("Consumed as", selection: $form.consumePresetId) {
                        ForEach(consumePresets) { preset in
                            Text(preset.title).tag(preset.id)
                        }
                    }
                }

                Section("One consume") {
                    TextField("Track name", text: $form.trackName)
                        .textInputAutocapitalization(.words)

                    TextField("Amount", text: $form.trackAmountText)
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $form.trackUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }

                Section("Cost basis") {
                    TextField("One consume uses", text: $form.costAmountPerTrackText)
                        .keyboardType(.decimalPad)

                    Picker("Cost unit", selection: $form.costUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }

                Section("Bought as") {
                    TextField("Purchase name", text: $form.purchaseName)
                        .textInputAutocapitalization(.words)

                    TextField("Default amount", text: $form.purchaseAmountText)
                        .keyboardType(.decimalPad)

                    Picker("Purchase unit", selection: $form.purchaseUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Consumable" : "Edit Consumable")
            .onChange(of: form.category) { _, newCategory in
                form.applyDefaults(for: newCategory)
            }
            .onChange(of: form.consumePresetId) { _, _ in
                form.applyPreset(selectedConsumePreset)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let submission = form.makeSubmission(selectedPreset: selectedConsumePreset)
                        let existingItem = item
                        isSaving = true

                        Task { @MainActor in
                            let saved = await onSave(submission, existingItem)
                            isSaving = false

                            if saved {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }
}

@MainActor
final class ConsumableFormState: ObservableObject {
    @Published var name: String
    @Published var category: ConsumableCategory
    @Published var consumePresetId: String
    @Published var trackName: String
    @Published var trackAmountText: String
    @Published var trackUnit: ConsumeUnit
    @Published var usageMethod: ConsumableUsageMethod
    @Published var costAmountPerTrackText: String
    @Published var costUnit: ConsumeUnit
    @Published var purchaseName: String
    @Published var purchaseAmountText: String
    @Published var purchaseUnit: ConsumeUnit

    init(item: ConsumableItem?) {
        let category = item?.category ?? .custom
        let presets = ConsumableSetupPresets.consumePresets(for: category)
        let matchedPreset = presets.first { $0.title == item?.consumePresetName } ?? presets.first ?? ConsumableSetupPresets.fallbackPreset

        self.name = item?.name ?? ""
        self.category = category
        self.consumePresetId = matchedPreset.id
        self.trackName = item?.trackName ?? item?.consumePresetName ?? matchedPreset.trackName
        self.trackAmountText = item?.trackAmount.map { String($0) } ?? item?.defaultAmountPerConsume.map { String($0) } ?? matchedPreset.trackAmountText
        self.trackUnit = item?.trackUnit ?? item?.defaultUnit ?? matchedPreset.trackUnit
        self.usageMethod = item?.usageMethod ?? matchedPreset.usageMethod
        self.costAmountPerTrackText = item?.costAmountPerTrack.map { String($0) } ?? item.map { String($0.effectiveCostAmountPerTrack) } ?? matchedPreset.costAmountPerTrackText
        self.costUnit = item?.costUnit ?? item?.effectiveCostUnit ?? matchedPreset.costUnit
        self.purchaseName = item?.purchaseName ?? item?.purchasePresetName ?? matchedPreset.purchaseName
        self.purchaseAmountText = item?.defaultPurchaseAmount.map { String($0) } ?? item?.defaultUnitsPerPurchase.map { String($0) } ?? matchedPreset.defaultPurchaseAmountText
        self.purchaseUnit = item?.defaultPurchaseUnit ?? matchedPreset.defaultPurchaseUnit
    }

    var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTrackName = !trackName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let trackAmount = Double(trackAmountText.replacingOccurrences(of: ",", with: "."))
        let costAmount = Double(costAmountPerTrackText.replacingOccurrences(of: ",", with: "."))
        let purchaseAmount = Double(purchaseAmountText.replacingOccurrences(of: ",", with: "."))
        return hasName && hasTrackName && (trackAmount ?? 0) > 0 && (costAmount ?? 0) > 0 && (purchaseAmount ?? 0) > 0
    }

    func makeSubmission(selectedPreset: ConsumableSetupPreset) -> ConsumableFormSubmission {
        ConsumableFormSubmission(
            name: name,
            category: category,
            consumePresetName: selectedPreset.title,
            trackName: trackName,
            trackAmountText: trackAmountText,
            trackUnit: trackUnit,
            usageMethod: usageMethod,
            costAmountPerTrackText: costAmountPerTrackText,
            costUnit: costUnit,
            purchaseName: purchaseName,
            purchaseAmountText: purchaseAmountText,
            purchaseUnit: purchaseUnit
        )
    }

    func applyDefaults(for category: ConsumableCategory) {
        let preset = ConsumableSetupPresets.consumePresets(for: category).first ?? ConsumableSetupPresets.fallbackPreset
        consumePresetId = preset.id
        applyPreset(preset)
    }

    func applyPreset(_ preset: ConsumableSetupPreset) {
        trackName = preset.trackName
        trackAmountText = preset.trackAmountText
        trackUnit = preset.trackUnit
        usageMethod = preset.usageMethod
        costAmountPerTrackText = preset.costAmountPerTrackText
        costUnit = preset.costUnit
        purchaseName = preset.purchaseName
        purchaseAmountText = preset.defaultPurchaseAmountText
        purchaseUnit = preset.defaultPurchaseUnit
    }
}

#Preview {
    SettingsView(userId: "preview", scope: .registered)
}
