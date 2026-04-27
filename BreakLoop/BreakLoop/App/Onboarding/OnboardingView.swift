// BreakLoop/ BreakLoop/ App/ Onboarding/ OnboardingView.swift

// onboarding view
//
// Created by Arjang Khademi on 27.04.2026
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


struct OnboardingDraft: Sendable {
    var displayName: String
    var baselineDailyConsume: Double
    var baselineCostPerConsume: Decimal?
    var firstConsumableName: String
    var firstConsumableCategory: ConsumableCategory
    var firstConsumableUnit: ConsumeUnit
    var addFirstConsumable: Bool
}


// MARK: ┏━ [01 APP FLOW] OnboardingView
// MARK: ┗━ gateway zuerst, optional setup slides danach, auth auswahl nativ am ende

struct OnboardingView: View {
    private enum BaselineUnitOption: String, CaseIterable, Identifiable {
        case piece
        case pack
        case grams
        case milliliters
        case liters
        case custom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .piece: return "piece"
            case .pack: return "pack"
            case .grams: return "g"
            case .milliliters: return "ml"
            case .liters: return "L"
            case .custom: return "custom"
            }
        }

        var consumeUnit: ConsumeUnit {
            switch self {
            case .piece: return .piece
            case .pack: return .pack
            case .grams: return .gram
            case .milliliters: return .milliliter
            case .liters: return .other
            case .custom: return .other
            }
        }
    }

    private enum CurrencyOption: String, CaseIterable, Identifiable {
        case eur = "EUR"
        case usd = "USD"
        case gbp = "GBP"
        case chf = "CHF"
        case `try` = "TRY"

        var id: String { rawValue }
    }

    let initialProfile: UserProfile?
    let onChooseAuth: (AuthEntryIntent, OnboardingDraft?) -> Void

    // index für setup slides
    @State private var pageIndex: Int = 0

    // native auth chooser am ende vom setup
    @State private var showsAuthChoiceDialog: Bool = false

    // form state
    @State private var displayName: String = ""
    @State private var firstConsumableCategory: ConsumableCategory = .custom
    @State private var firstConsumableName: String = ""
    @State private var consumableUnit: BaselineUnitOption = .piece
    @State private var consumableCustomUnitName: String = ""
    @State private var baselineDailyAmountText: String = ""
    @State private var purchasePriceText: String = ""
    @State private var purchaseAmountText: String = ""
    @State private var selectedCurrencyCode: String = Locale.current.currency?.identifier ?? "EUR"

    private let totalPages = 4

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            Circle()
                .fill(Color("BrandAccentSoft").opacity(0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: 120, y: -260)

            Circle()
                .fill(Color("BrandAccent").opacity(0.17))
                .frame(width: 220, height: 220)
                .blur(radius: 52)
                .offset(x: -140, y: -140)

            setupContent
        }
        .onAppear {
            bootstrapInitialValues()
        }
        .confirmationDialog("How do you want to continue?", isPresented: $showsAuthChoiceDialog, titleVisibility: .visible) {
            Button("Sign In") {
                onChooseAuth(.signIn, makeDraft())
            }
            Button("Create Account") {
                onChooseAuth(.register, makeDraft())
            }
            Button("Continue as Guest") {
                onChooseAuth(.guest, makeDraft())
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose login method. Your setup data will be kept.")
        }
    }

    private var setupContent: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack {
                    Button {
                        if pageIndex > 0 { pageIndex -= 1 }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color("TextSecondary"))
                    .background(
                        Capsule()
                            .fill(Color("Surface"))
                            .overlay(
                                Capsule()
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                    )
                    .opacity(pageIndex == 0 ? 0 : 1)
                    .disabled(pageIndex == 0)

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index <= pageIndex ? Color("BrandAccentStrong") : Color("Border"))
                                .frame(width: index == pageIndex ? 20 : 8, height: 8)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("BrandAccentStrong"))

                    Text("BreakLoop")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("TextPrimary"))
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if pageIndex == 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color("BrandAccentStrong"))

                            Text("Quick start")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Color("TextPrimary"))
                        }

                        Text("Track consume habits")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("TextPrimary"))

                        Text("See spend, progress, and rewards in one flow")
                            .font(.body)
                            .foregroundStyle(Color("TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use Sign In below or continue setup to add first data")
                            .font(.body)
                            .foregroundStyle(Color("TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    } else if pageIndex == 1 {
                        consumableSlide
                    } else if pageIndex == 2 {
                        usageSlide
                    } else if pageIndex == 3 {
                        costSlide
                    } else {
                        EmptyView()
                    }
                }
                .padding(.top, 12)
            }

            VStack(spacing: 10) {
                Button {
                    if pageIndex < totalPages - 1 {
                        pageIndex += 1
                    } else {
                        showsAuthChoiceDialog = true
                    }
                } label: {
                    Label(pageIndex == totalPages - 1 ? "Continue" : "Next", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("ButtonPrimaryBackground"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.9), lineWidth: 1)
                )
                .disabled(!isCurrentSlideValid)

                Button {
                    onChooseAuth(.signIn, nil)
                } label: {
                    Label("Sign In", systemImage: "person.crop.circle.badge.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("ButtonPrimaryBackground"))
            }
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            if pageIndex == 0 {
                Label("Developed by @arj4ng", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.bottom, -18)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func pageTitle(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(Color("TextSecondary"))
        }
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .default ? .words : .never)
            .autocorrectionDisabled(keyboard != .default)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundStyle(Color("TextPrimary"))
            .background(Color("SurfaceElevated"))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("Border"), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var consumableSlide: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageTitle(
                title: "First consumable",
                subtitle: "Choose what you want to track first"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Consumable name")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))

                inputFieldBare(title: "Name (e.g. Flower, Vape Liquid)", text: $firstConsumableName, keyboard: .default)

                categoryPicker

                unitPicker(title: "Default unit", selection: $consumableUnit)

                if consumableUnit == .custom {
                    inputFieldBare(title: "Custom unit name", text: $consumableCustomUnitName, keyboard: .default)
                }

                if let error = consumableValidationError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color("Danger"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("Surface").opacity(0.72))
            )

        }
    }

    @ViewBuilder
    private var usageSlide: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageTitle(
                title: "Usage baseline",
                subtitle: "How much do you usually consume per day?"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Typical amount per day")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))

                inputFieldBare(title: "Amount per day", text: $baselineDailyAmountText, keyboard: .decimalPad)

                Text("Per day in \(consumableUnitLabelForCopy)")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))

                if let error = usageValidationError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color("Danger"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("Surface").opacity(0.72))
            )
        }
    }

    @ViewBuilder
    private var costSlide: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageTitle(
                title: "Cost baseline",
                subtitle: "Set package cost and package content for baseline math"
            )

            VStack(alignment: .leading, spacing: 10) {
                currencyPicker

                Text("Package price")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))

                currencyInputField(title: "Price", text: $purchasePriceText)

                Text(purchaseAmountLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))

                inputFieldBare(title: purchaseAmountPlaceholder, text: $purchaseAmountText, keyboard: .decimalPad)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated cost per \(consumableUnitLabelForCopy)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("TextSecondary"))

                    Text(estimatedCostPerConsumeDisplay)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("TextPrimary"))

                    Text("Estimated daily cost baseline")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("TextSecondary"))

                    Text(estimatedDailyCostDisplay)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("BrandAccentStrong"))
                }
                .padding(.top, 2)

                if let error = costValidationError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color("Danger"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("Surface").opacity(0.72))
            )
        }
    }

    @ViewBuilder
    private var categoryPicker: some View {
        HStack(spacing: 8) {
            Text("Category")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Spacer()

            Picker("Category", selection: $firstConsumableCategory) {
                ForEach(ConsumableCategory.allCases, id: \.self) { category in
                    Text(category.rawValue.capitalized).tag(category)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("TextPrimary"))
        }
    }

    @ViewBuilder
    private var currencyPicker: some View {
        HStack(spacing: 8) {
            Text("Currency")
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Spacer()

            Picker("Currency", selection: $selectedCurrencyCode) {
                ForEach(CurrencyOption.allCases) { option in
                    Text(option.rawValue).tag(option.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("TextPrimary"))
        }
    }

    @ViewBuilder
    private func unitPicker(title: String, selection: Binding<BaselineUnitOption>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            Spacer()

            Picker(title, selection: selection) {
                ForEach(BaselineUnitOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("TextPrimary"))
        }
    }

    @ViewBuilder
    private func currencyInputField(title: String, text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text(currencySymbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("TextSecondary"))

            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(Color("TextPrimary"))
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func inputFieldBare(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .default ? .words : .never)
            .autocorrectionDisabled(keyboard != .default)
            .padding(.horizontal, 2)
            .padding(.vertical, 10)
            .foregroundStyle(Color("TextPrimary"))
            .background(Color.clear)
    }

    private var purchaseAmountLabel: String {
        "Amount in one package (\(consumableUnitLabelForCopy))"
    }

    private var purchaseAmountPlaceholder: String {
        "e.g. 20"
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrencyCode
        formatter.locale = .current
        return formatter.currencySymbol ?? selectedCurrencyCode
    }

    private var baselineDailyValue: Double? {
        parseDouble(baselineDailyAmountText)
    }

    private var baselinePurchasePriceValue: Decimal? {
        parseDecimal(purchasePriceText)
    }

    private var baselinePurchaseQuantityValue: Decimal? {
        parseDecimal(purchaseAmountText)
    }

    private var estimatedCostPerConsume: Decimal? {
        guard let price = baselinePurchasePriceValue, let quantity = baselinePurchaseQuantityValue else { return nil }
        guard price > 0, quantity > 0 else { return nil }
        return price / quantity
    }

    private var estimatedCostPerConsumeDisplay: String {
        guard let value = estimatedCostPerConsume else { return "—" }
        return formatCurrency(value)
    }

    private var estimatedDailyCost: Decimal? {
        guard let costPerUnit = estimatedCostPerConsume else { return nil }
        let dailyAmount = Decimal(baselineDailyValue ?? 0)
        guard dailyAmount > 0 else { return nil }
        return costPerUnit * dailyAmount
    }

    private var estimatedDailyCostDisplay: String {
        guard let value = estimatedDailyCost else { return "—" }
        return formatCurrency(value)
    }

    private var consumableUnitLabelForCopy: String {
        consumableUnit == .custom ? (consumableCustomUnitName.isEmpty ? "custom unit" : consumableCustomUnitName) : consumableUnit.label
    }

    private var consumableValidationError: String? {
        guard pageIndex == 1 else { return nil }

        if firstConsumableName.isEmpty && consumableUnit != .custom {
            return nil
        }

        if firstConsumableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Consumable name required"
        }

        if consumableUnit == .custom && consumableCustomUnitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Custom unit required"
        }

        return nil
    }

    private var usageValidationError: String? {
        guard pageIndex == 2 else { return nil }

        guard !baselineDailyAmountText.isEmpty else { return nil }

        guard let value = baselineDailyValue else { return "Use valid number for amount" }
        guard value > 0 else { return "Amount must be greater than 0" }

        return nil
    }

    private var costValidationError: String? {
        guard pageIndex == 3 else { return nil }

        if purchasePriceText.isEmpty && purchaseAmountText.isEmpty {
            return nil
        }

        guard !purchasePriceText.isEmpty, !purchaseAmountText.isEmpty else { return "Price and amount required" }
        guard let price = baselinePurchasePriceValue else { return "Use valid number for price" }
        guard let quantity = baselinePurchaseQuantityValue else { return "Use valid number for amount" }
        guard price > 0 else { return "Price must be greater than 0" }
        guard quantity > 0 else { return "Amount must be greater than 0" }

        return nil
    }

    private var isConsumableSlideValid: Bool {
        !firstConsumableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (consumableUnit != .custom || !consumableCustomUnitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
        consumableValidationError == nil
    }

    private var isUsageSlideValid: Bool {
        guard let value = baselineDailyValue else { return false }
        return value > 0 && usageValidationError == nil
    }

    private var isCostSlideValid: Bool {
        guard let price = baselinePurchasePriceValue, let amount = baselinePurchaseQuantityValue else { return false }
        return price > 0 && amount > 0 && costValidationError == nil
    }

    private var isCurrentSlideValid: Bool {
        switch pageIndex {
        case 1:
            return isConsumableSlideValid
        case 2:
            return isUsageSlideValid
        case 3:
            return isCostSlideValid
        default:
            return true
        }
    }

    private func parseDouble(_ text: String) -> Double? {
        let sanitized = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.-".contains($0) }
        return Double(sanitized)
    }

    private func parseDecimal(_ text: String) -> Decimal? {
        let sanitized = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.-".contains($0) }
        return Decimal(string: sanitized)
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        formatter.locale = .current
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrencyCode
        formatter.locale = .current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        if let result = formatter.string(from: NSDecimalNumber(decimal: value)) {
            return result
        }

        return "\(currencySymbol)\(formatDecimal(value))"
    }

    private func bootstrapInitialValues() {
        if !CurrencyOption.allCases.map(\.rawValue).contains(selectedCurrencyCode) {
            selectedCurrencyCode = "EUR"
        }

        if let initialProfile {
            if initialProfile.displayName != "Guest" && initialProfile.displayName != "User" {
                displayName = initialProfile.displayName
            }
            if initialProfile.baselineDailyConsume > 0 {
                baselineDailyAmountText = String(initialProfile.baselineDailyConsume)
            }
            if let cost = initialProfile.baselineCostPerConsume {
                purchasePriceText = NSDecimalNumber(decimal: cost).stringValue
                purchaseAmountText = "1"
            }
        }
    }

    private func makeDraft() -> OnboardingDraft {
        let daily = baselineDailyValue ?? 0
        let cost = estimatedCostPerConsume
        let mappedUnit = mapBaselineUnitToConsumeUnit()

        return OnboardingDraft(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            baselineDailyConsume: max(0, daily),
            baselineCostPerConsume: cost,
            firstConsumableName: firstConsumableName.trimmingCharacters(in: .whitespacesAndNewlines),
            firstConsumableCategory: firstConsumableCategory,
            firstConsumableUnit: mappedUnit,
            addFirstConsumable: true
        )
    }

    private func mapBaselineUnitToConsumeUnit() -> ConsumeUnit {
        consumableUnit.consumeUnit
    }
}

#Preview {
    OnboardingView(initialProfile: nil, onChooseAuth: { _, _ in })
}
