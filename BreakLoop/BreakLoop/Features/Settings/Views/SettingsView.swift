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
                    defaultAmountPerConsumeText: submission.defaultAmountPerConsumeText,
                    defaultUnit: submission.defaultUnit,
                    usageMethod: submission.usageMethod,
                    purchasePresetName: submission.purchasePresetName,
                    defaultPurchaseUnit: submission.defaultPurchaseUnit,
                    defaultUnitsPerPurchaseText: submission.defaultUnitsPerPurchaseText,
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

                Text("\(item.defaultUnit.rawValue) • \(item.usageMethod.rawValue)")
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
                    TextField("Amount", text: $form.defaultAmountPerConsumeText)
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $form.defaultUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }

                Section("Bought as") {
                    TextField("Package name", text: $form.purchasePresetName)
                        .textInputAutocapitalization(.words)

                    TextField("Amount inside", text: $form.defaultUnitsPerPurchaseText)
                        .keyboardType(.decimalPad)

                    Picker("Unit inside", selection: $form.defaultPurchaseUnit) {
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
    @Published var defaultAmountPerConsumeText: String
    @Published var defaultUnit: ConsumeUnit
    @Published var usageMethod: ConsumableUsageMethod
    @Published var purchasePresetName: String
    @Published var defaultPurchaseUnit: ConsumeUnit
    @Published var defaultUnitsPerPurchaseText: String

    init(item: ConsumableItem?) {
        let category = item?.category ?? .custom
        let presets = ConsumableSetupPresets.consumePresets(for: category)
        let matchedPreset = presets.first { $0.title == item?.consumePresetName } ?? presets.first ?? ConsumableSetupPresets.fallbackPreset

        self.name = item?.name ?? ""
        self.category = category
        self.consumePresetId = matchedPreset.id
        self.defaultAmountPerConsumeText = item?.defaultAmountPerConsume.map { String($0) } ?? matchedPreset.defaultAmountText
        self.defaultUnit = item?.defaultUnit ?? matchedPreset.unit
        self.usageMethod = item?.usageMethod ?? matchedPreset.usageMethod
        self.purchasePresetName = item?.purchasePresetName ?? Self.defaultPurchaseName(for: matchedPreset)
        self.defaultPurchaseUnit = item?.defaultPurchaseUnit ?? matchedPreset.purchaseUnit
        self.defaultUnitsPerPurchaseText = item?.defaultUnitsPerPurchase.map { String($0) } ?? matchedPreset.purchaseAmountText
    }

    var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let consumeAmount = Double(defaultAmountPerConsumeText.replacingOccurrences(of: ",", with: "."))
        let purchaseAmount = Double(defaultUnitsPerPurchaseText.replacingOccurrences(of: ",", with: "."))
        return hasName && (consumeAmount ?? 0) > 0 && (purchaseAmount ?? 0) > 0
    }

    func makeSubmission(selectedPreset: ConsumableSetupPreset) -> ConsumableFormSubmission {
        ConsumableFormSubmission(
            name: name,
            category: category,
            consumePresetName: selectedPreset.title,
            defaultAmountPerConsumeText: defaultAmountPerConsumeText,
            defaultUnit: defaultUnit,
            usageMethod: usageMethod,
            purchasePresetName: purchasePresetName,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultUnitsPerPurchaseText: defaultUnitsPerPurchaseText
        )
    }

    func applyDefaults(for category: ConsumableCategory) {
        let preset = ConsumableSetupPresets.consumePresets(for: category).first ?? ConsumableSetupPresets.fallbackPreset
        consumePresetId = preset.id
        applyPreset(preset)
    }

    func applyPreset(_ preset: ConsumableSetupPreset) {
        defaultAmountPerConsumeText = preset.defaultAmountText
        defaultUnit = preset.unit
        usageMethod = preset.usageMethod
        purchasePresetName = Self.defaultPurchaseName(for: preset)
        defaultPurchaseUnit = preset.purchaseUnit
        defaultUnitsPerPurchaseText = preset.purchaseAmountText
    }

    private static func defaultPurchaseName(for preset: ConsumableSetupPreset) -> String {
        switch preset.purchaseUnit {
        case .pack: return "Pack"
        case .gram: return "Bag"
        case .milliliter: return "Bottle"
        case .cup: return "Box"
        case .dose: return "Box"
        case .piece, .other: return "Package"
        }
    }
}

#Preview {
    SettingsView(userId: "preview", scope: .registered)
}
