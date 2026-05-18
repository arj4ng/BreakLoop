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
    @State private var editedItem: ConsumableItem?
    @State private var showsForm = false
    @State private var pendingArchiveItem: ConsumableItem?

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading")
            }

            Section {
                ForEach(viewModel.consumables) { item in
                    Button {
                        editedItem = item
                        showsForm = true
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
                    editedItem = nil
                    showsForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showsForm) {
            ConsumableFormView(item: editedItem) { draft, existingItem in
                await viewModel.saveConsumable(draft: draft, existingItem: existingItem)
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

private struct ConsumableFormView: View {
    let item: ConsumableItem?
    let onSave: (ConsumableFormDraft, ConsumableItem?) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: ConsumableCategory
    @State private var defaultUnit: ConsumeUnit
    @State private var usageMethod: ConsumableUsageMethod
    @State private var pricingMode: ConsumablePricingMode
    @State private var defaultPurchaseUnit: ConsumeUnit
    @State private var defaultUnitsPerPurchaseText: String
    @State private var isSaving = false

    private var draft: ConsumableFormDraft {
        ConsumableFormDraft(
            name: name,
            category: category,
            defaultUnit: defaultUnit,
            usageMethod: usageMethod,
            pricingMode: pricingMode,
            defaultPurchaseUnit: defaultPurchaseUnit,
            defaultUnitsPerPurchaseText: defaultUnitsPerPurchaseText
        )
    }

    init(item: ConsumableItem?, onSave: @escaping (ConsumableFormDraft, ConsumableItem?) async -> Bool) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item?.name ?? "")
        _category = State(initialValue: item?.category ?? .custom)
        _defaultUnit = State(initialValue: item?.defaultUnit ?? .piece)
        _usageMethod = State(initialValue: item?.usageMethod ?? .custom)
        _pricingMode = State(initialValue: item?.pricingMode ?? .perUnit)
        _defaultPurchaseUnit = State(initialValue: item?.defaultPurchaseUnit ?? .pack)
        _defaultUnitsPerPurchaseText = State(initialValue: item?.defaultUnitsPerPurchase.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $category) {
                        ForEach(ConsumableCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }

                    Picker("Consume unit", selection: $defaultUnit) {
                        ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }

                Section("Dynamic") {
                    Picker("Usage method", selection: $usageMethod) {
                        Text("Per piece").tag(ConsumableUsageMethod.perPiece)
                        Text("Per session").tag(ConsumableUsageMethod.perSession)
                        Text("Per gram").tag(ConsumableUsageMethod.perGram)
                        Text("Per ml").tag(ConsumableUsageMethod.perMilliliter)
                        Text("Per cup").tag(ConsumableUsageMethod.perCup)
                        Text("Per dose").tag(ConsumableUsageMethod.perDose)
                        Text("Custom").tag(ConsumableUsageMethod.custom)
                    }

                    Picker("Pricing", selection: $pricingMode) {
                        Text("Per unit").tag(ConsumablePricingMode.perUnit)
                        Text("Per purchase").tag(ConsumablePricingMode.perPurchase)
                    }
                    .pickerStyle(.segmented)

                    if pricingMode == .perPurchase {
                        Picker("Purchase unit", selection: $defaultPurchaseUnit) {
                            ForEach(ConsumeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }

                        TextField("Units per purchase", text: $defaultUnitsPerPurchaseText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Consumable" : "Edit Consumable")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let saved = await onSave(draft, item)
                            isSaving = false
                            if saved {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
        }
    }
}

#Preview {
    SettingsView(userId: "preview", scope: .registered)
}
