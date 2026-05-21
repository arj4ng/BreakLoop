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
                    settingsRow(icon: "person.crop.circle", title: "Profile")
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
                    Button {
                        formRoute = ConsumableFormRoute(item: item)
                    } label: {
                        consumableRow(item)
                    }
                    .buttonStyle(.plain)
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

private struct ConsumableFormRoute: Identifiable {
    let id: String
    let item: ConsumableItem?

    init(item: ConsumableItem?) {
        self.item = item
        self.id = item?.id ?? "new-\(UUID().uuidString)"
    }
}

private struct ConsumableFormView: View {
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
private final class ConsumableFormState: ObservableObject {
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
