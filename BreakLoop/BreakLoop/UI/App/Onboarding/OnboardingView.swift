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
    var initialMode: OnboardingInitialMode
    var quitStartDate: Date
    var displayName: String
    var preferredCurrencyCode: String
    var baselineDailyConsume: Double
    var baselineCostPerConsume: Decimal?
    var firstConsumableName: String
    var firstConsumableCategory: ConsumableCategory
    var firstConsumableUnit: ConsumeUnit
    var firstConsumableUsageMethod: OnboardingUsageMethod
    var firstConsumablePricingMode: OnboardingPricingMode
    var firstConsumablePurchaseUnit: ConsumeUnit?
    var firstConsumableUnitsPerPurchase: Double?
    var firstConsumableTrackName: String
    var firstConsumableTrackAmount: Double
    var firstConsumableTrackUnit: ConsumeUnit
    var firstConsumableCostAmountPerTrack: Double
    var firstConsumableCostUnit: ConsumeUnit
    var firstConsumablePurchaseName: String
    var firstConsumableDefaultPurchaseAmount: Double
    var addFirstConsumable: Bool
}

enum OnboardingInitialMode: String, Codable, Sendable {
    case reduce
    case quit
}

enum OnboardingPricingMode: String, Codable, Sendable {
    case perUnit
    case perPurchase
}

enum OnboardingUsageMethod: String, Codable, Sendable {
    case perPiece
    case perSession
    case perGram
    case perMilliliter
    case perCup
    case perDose
    case custom
}


// MARK: ┏━ [01 APP FLOW] OnboardingView
// MARK: ┗━ premium guided onboarding mit einem klaren fokus pro screen

struct OnboardingView: View {
    private let contentTopSpacing: CGFloat = 8
    private let cardRadius: CGFloat = 16
    private let sectionSpacing: CGFloat = 18
    private let bottomBarReservedHeight: CGFloat = 190

    private enum Step: Int, CaseIterable {
        case welcome
        case mode
        case consumable
        case dailyAmount
        case unitPrice
        case quantityPerPurchase
        case summary
    }

    private enum UnitOption: String, CaseIterable, Identifiable {
        case piece
        case gram
        case milliliter
        case cup
        case dose
        case pack
        case other

        var id: String { rawValue }

        var label: String {
            switch self {
            case .piece: return "piece"
            case .gram: return "g"
            case .milliliter: return "ml"
            case .cup: return "cup"
            case .dose: return "dose"
            case .pack: return "pack"
            case .other: return "other"
            }
        }

        var consumeUnit: ConsumeUnit {
            switch self {
            case .piece: return .piece
            case .gram: return .gram
            case .milliliter: return .milliliter
            case .cup: return .cup
            case .dose: return .dose
            case .pack: return .pack
            case .other: return .other
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

    private enum TrackType: String, CaseIterable, Identifiable {
        case cigarettes
        case vape
        case weed
        case alcohol
        case caffeine
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .cigarettes: return "Cigarettes"
            case .vape: return "Vape"
            case .weed: return "Weed"
            case .alcohol: return "Alcohol"
            case .caffeine: return "Caffeine"
            case .custom: return "Custom"
            }
        }

        var icon: String {
            switch self {
            case .cigarettes: return "flame"
            case .vape: return "drop.fill"
            case .weed: return "leaf.fill"
            case .alcohol: return "wineglass.fill"
            case .caffeine: return "cup.and.saucer.fill"
            case .custom: return "square.and.pencil"
            }
        }

        var category: ConsumableCategory {
            switch self {
            case .cigarettes, .vape:
                return .nicotine
            case .weed:
                return .cannabis
            case .alcohol:
                return .alcohol
            case .caffeine:
                return .caffeine
            case .custom:
                return .custom
            }
        }

        var unit: UnitOption {
            switch self {
            case .cigarettes: return .piece
            case .vape: return .dose
            case .weed: return .gram
            case .alcohol: return .cup
            case .caffeine: return .cup
            case .custom: return .other
            }
        }

        var allowedUnits: [UnitOption] {
            switch self {
            case .cigarettes: return [.piece, .pack]
            case .vape: return [.dose, .milliliter, .piece, .pack]
            case .weed: return [.piece, .gram, .dose, .other]
            case .alcohol: return [.cup, .milliliter, .piece, .pack]
            case .caffeine: return [.cup, .milliliter, .piece, .dose]
            case .custom: return UnitOption.allCases
            }
        }

        var usageMethod: OnboardingUsageMethod {
            switch self {
            case .cigarettes: return .perPiece
            case .vape: return .perSession
            case .weed: return .perGram
            case .alcohol: return .perCup
            case .caffeine: return .perCup
            case .custom: return .custom
            }
        }

        var pricingModeDefault: PricingMode {
            switch self {
            case .cigarettes, .vape, .alcohol:
                return .package
            case .caffeine, .custom:
                return .unit
            case .weed:
                return .package
            }
        }

        var usageExample: String {
            switch self {
            case .cigarettes: return "cigarettes/day"
            case .vape: return "sessions/day"
            case .weed: return "g/day"
            case .alcohol: return "drinks/day"
            case .caffeine: return "cups/day"
            case .custom: return "units/day"
            }
        }

        var priceExample: String {
            switch self {
            case .cigarettes: return "one pack"
            case .vape: return "one pod or bottle"
            case .weed: return "1g"
            case .alcohol: return "one bottle or can"
            case .caffeine: return "one cup"
            case .custom: return "one unit"
            }
        }

        var quantityPresets: [Double] {
            switch self {
            case .cigarettes: return [20, 25, 30]
            case .vape: return [1, 2, 4]
            case .weed: return [1, 3.5, 5, 10]
            case .alcohol: return [1, 6, 12]
            case .caffeine: return [1, 2, 3]
            case .custom: return [1, 5, 10, 20]
            }
        }

        var dailyPresets: [Double] {
            switch self {
            case .cigarettes: return [3, 5, 8, 10, 12, 15, 20]
            case .vape: return [3, 5, 8, 10, 15, 20, 30]
            case .weed: return [0.2, 0.5, 1, 1.5, 2]
            case .alcohol: return [1, 2, 3, 4, 5, 6]
            case .caffeine: return [1, 2, 3, 4, 5, 6]
            case .custom: return [1, 2, 3, 5, 8, 10]
            }
        }

        var weeklyPresets: [Double] {
            switch self {
            case .cigarettes:
                return [21, 35, 56, 70, 105, 140]
            case .vape:
                return [21, 35, 56, 70, 105, 140]
            case .weed:
                return [1.4, 3.5, 7, 10.5, 14]
            case .alcohol:
                return [7, 14, 21, 28, 35, 42]
            case .caffeine:
                return [7, 14, 21, 28, 35, 42]
            case .custom:
                return [7, 14, 21, 35, 56, 70]
            }
        }

        var defaultDailyAmount: Double {
            switch self {
            case .weed:
                return 0.5
            default:
                return dailyPresets.first ?? 1
            }
        }
    }

    private enum PricingMode {
        case unit
        case package
    }

    private enum UsageFrequency: String, CaseIterable, Identifiable {
        case daily
        case weekly

        var id: String { rawValue }

        var label: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            }
        }

        var shortLabel: String {
            switch self {
            case .daily: return "day"
            case .weekly: return "week"
            }
        }
    }

    private enum MassDisplayUnit: String, CaseIterable, Identifiable {
        case gram = "g"
        case milligram = "mg"

        var id: String { rawValue }
    }

    private enum FieldFocus: Hashable {
        case customName
        case customUnitName
        case unitPrice
        case quantityCustom
    }

    let initialProfile: UserProfile?
    private let onChooseAuth: (AuthEntryIntent, OnboardingDraft?) -> Void
    private let onCompleteConsumable: ((OnboardingDraft) -> Void)?
    private let onDismissConsumableFlow: (() -> Void)?
    private let isConsumableOnly: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: Step = .welcome
    @State private var initialMode: OnboardingInitialMode = .reduce
    @State private var quitStartDate: Date = .now

    @State private var selectedType: TrackType?
    @State private var customConsumableName: String = ""
    @State private var customUnit: UnitOption = .other
    @State private var customUnitName: String = ""
    @State private var customPricingMode: PricingMode = .unit
    @State private var customUsageMethod: OnboardingUsageMethod = .custom

    @State private var displayName: String = ""
    @State private var dailyAmount: Double = 10
    @State private var usageFrequency: UsageFrequency = .daily
    @State private var massDisplayUnit: MassDisplayUnit = .gram

    @State private var selectedCurrencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @State private var unitPriceText: String = ""

    @State private var quantityInPurchase: Double = 20
    @State private var quantityCustomText: String = ""
    @State private var scrollTarget: String?
    @State private var scrollContentOffset: CGFloat = 0
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var scrollBodyHeight: CGFloat = 0
    @State private var isForwardNavigation: Bool = true
    @FocusState private var focusedField: FieldFocus?

    init(initialProfile: UserProfile?, onChooseAuth: @escaping (AuthEntryIntent, OnboardingDraft?) -> Void) {
        self.initialProfile = initialProfile
        self.onChooseAuth = onChooseAuth
        self.onCompleteConsumable = nil
        self.onDismissConsumableFlow = nil
        self.isConsumableOnly = false
    }

    init(
        initialProfile: UserProfile?,
        onCompleteConsumable: @escaping (OnboardingDraft) -> Void,
        onDismissConsumableFlow: (() -> Void)? = nil
    ) {
        self.initialProfile = initialProfile
        self.onChooseAuth = { _, _ in }
        self.onCompleteConsumable = onCompleteConsumable
        self.onDismissConsumableFlow = onDismissConsumableFlow
        self.isConsumableOnly = true
        _step = State(initialValue: .mode)
    }

    private var hasScrolledUnderChrome: Bool {
        scrollContentOffset < -8
    }

    private var shouldEnableScroll: Bool {
        // solange layout messung noch nicht da ist, scroll nie blocken
        if scrollViewportHeight <= 0 || scrollBodyHeight <= 0 {
            return true
        }
        return scrollBodyHeight > (scrollViewportHeight - 1)
    }

    private var stepTransition: AnyTransition {
        if isForwardNavigation {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    private var progressIndex: Int {
        visibleSteps.firstIndex(of: step) ?? 0
    }

    private var totalSteps: Int {
        visibleSteps.count
    }

    private var visibleProgressIndexes: [Int] {
        let maxDots = 5
        guard totalSteps > maxDots else {
            return Array(0..<totalSteps)
        }

        let halfWindow = maxDots / 2
        let rawStart = progressIndex - halfWindow
        let maxStart = totalSteps - maxDots
        let start = min(max(rawStart, 0), maxStart)
        return Array(start..<(start + maxDots))
    }

    private var effectiveType: TrackType {
        selectedType ?? .cigarettes
    }

    private var effectiveUnitOption: UnitOption {
        if effectiveType == .custom {
            return customUnit
        }
        return effectiveType.unit
    }

    private var effectiveConsumableName: String {
        if effectiveType == .custom {
            let trimmed = customConsumableName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom" : trimmed
        }
        return effectiveType.title
    }

    private var effectiveUsageMethod: OnboardingUsageMethod {
        if effectiveType == .custom {
            return customUsageMethod
        }
        if effectiveType == .weed, effectiveUnitOption == .gram {
            return .perGram
        }
        return effectiveType.usageMethod
    }

    private var setupPreset: ConsumableSetupPreset {
        let presets = ConsumableSetupPresets.consumePresets(for: effectiveType.category)
        let presetId: String

        switch effectiveType {
        case .cigarettes:
            presetId = "cigarette"
        case .vape:
            presetId = "vapePuff"
        case .weed:
            presetId = effectiveUnitOption == .gram ? "gram" : "joint"
        case .alcohol:
            presetId = "beer"
        case .caffeine:
            presetId = "coffee"
        case .custom:
            presetId = "custom"
        }

        return presets.first { $0.id == presetId } ?? presets.first ?? ConsumableSetupPresets.fallbackPreset
    }

    private var purchaseUnitLabel: String {
        label(for: setupPreset.defaultPurchaseUnit)
    }

    private var dailyAmountValue: Double {
        return max(0, dailyAmount)
    }

    private var isMassInputToggleVisible: Bool {
        effectiveUnitOption == .gram
    }

    private var effectiveAmountUnitLabel: String {
        if isMassInputToggleVisible {
            return massDisplayUnit.rawValue
        }

        if effectiveType == .custom, customUnit == .other {
            let trimmed = customUnitName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed.lowercased()
            }
        }

        return effectiveUnitOption.label
    }

    private func label(for unit: ConsumeUnit) -> String {
        switch unit {
        case .piece: return "pieces"
        case .pack: return "packs"
        case .gram: return "g"
        case .milliliter: return "ml"
        case .cup: return "cups"
        case .dose: return "doses"
        case .other: return "units"
        }
    }

    private var displayedUsageAmount: Double {
        var value = dailyAmountValue
        if usageFrequency == .weekly {
            value *= 7
        }
        if isMassInputToggleVisible, massDisplayUnit == .milligram {
            value *= 1000
        }
        return value
    }

    private var displayedUsageAmountBinding: Binding<Double> {
        Binding<Double>(
            get: { displayedUsageAmount },
            set: { newValue in
                dailyAmount = roundedDailyAmount(convertDisplayedAmountToDaily(newValue))
            }
        )
    }

    private var displayedUsagePresets: [Double] {
        let sourcePresets = usageFrequency == .weekly ? effectiveType.weeklyPresets : effectiveType.dailyPresets

        return sourcePresets.map { preset in
            var value = preset
            if isMassInputToggleVisible, massDisplayUnit == .milligram {
                value *= 1000
            }
            return value
        }
    }

    private var displayAdjustStep: Double {
        switch effectiveType {
        case .weed:
            return isMassInputToggleVisible && massDisplayUnit == .milligram ? 100 : 1
        case .custom:
            switch effectiveUnitOption {
            case .gram:
                return isMassInputToggleVisible && massDisplayUnit == .milligram ? 100 : 1
            case .milliliter:
                return 10
            default:
                return 1
            }
        default:
            return 1
        }
    }

    private var monthlyUsageEstimate: Double {
        dailyAmountValue * 30
    }

    private var quantityValue: Double {
        if let custom = parseDouble(quantityCustomText), custom > 0 {
            return custom
        }
        return max(1, quantityInPurchase)
    }

    private var unitPriceValue: Decimal? {
        parseDecimal(unitPriceText)
    }

    private var pricingMode: PricingMode {
        switch effectiveType {
        case .cigarettes, .vape, .weed, .alcohol, .caffeine:
            return effectiveType.pricingModeDefault
        case .custom:
            return customPricingMode
        }
    }

    private var visibleSteps: [Step] {
        if effectiveType == .weed {
            if isConsumableOnly {
                return [.mode, .consumable, .dailyAmount, .unitPrice, .summary]
            }
            return [.welcome, .mode, .consumable, .dailyAmount, .unitPrice, .summary]
        }

        if isConsumableOnly {
            switch pricingMode {
            case .unit:
                return [.mode, .consumable, .dailyAmount, .unitPrice, .summary]
            case .package:
                return [.mode, .consumable, .dailyAmount, .unitPrice, .quantityPerPurchase, .summary]
            }
        }

        switch pricingMode {
        case .unit:
            return [.welcome, .mode, .consumable, .dailyAmount, .unitPrice, .summary]
        case .package:
            return [.welcome, .mode, .consumable, .dailyAmount, .unitPrice, .quantityPerPurchase, .summary]
        }
    }

    private var priceQuestionTitle: String {
        if effectiveType == .weed {
            return "How much did that bag cost?"
        }
        switch pricingMode {
        case .unit:
            return "What does one \(effectiveUnitOption.label) usually cost?"
        case .package:
            return "What does one \(setupPreset.purchaseName.lowercased()) usually cost?"
        }
    }

    private var priceQuestionSubtitle: String {
        if effectiveType == .weed {
            return "Enter full price you pay for one bag. Next screen asks how many grams that bag has."
        }
        switch pricingMode {
        case .unit:
            return "Enter direct price per \(effectiveUnitOption.label)."
        case .package:
            return "Use package price. Next step maps content per package."
        }
    }

    private var quantityQuestionTitle: String {
        if effectiveType == .weed {
            return "How many grams in that bag?"
        }
        return "How much is in one purchase?"
    }

    private var quantityQuestionSubtitle: String {
        switch effectiveType {
        case .weed:
            return "Example: if you buy a 5g bag, enter 5."
        case .cigarettes:
            return "Used to calculate cost per cigarette."
        case .vape:
            return "Used to calculate cost per session."
        case .alcohol:
            return "Used to calculate cost per drink."
        default:
            return "Needed to calculate cost per \(setupPreset.trackName)."
        }
    }

    private var costPerUnit: Decimal? {
        simpleInput.costPerUnit
    }

    private var costPerConsume: Decimal? {
        simpleInput.costPerConsume(consumeUnitAmount: consumeUnitCostAmount)
    }

    private var monthlySpend: Decimal? {
        simpleInput.monthlyEstimatedSpend(consumeUnitAmount: consumeUnitCostAmount)
    }

    private var monthlySavingsAt25: Decimal? {
        guard let spend = monthlySpend else { return nil }
        return spend * Decimal(string: "0.25")!
    }

    private var monthlySpendPreviewOnPriceStep: Decimal? {
        if effectiveType == .weed {
            return monthlySpend
        }
        switch pricingMode {
        case .unit:
            return monthlySpend
        case .package:
            return nil
        }
    }

    private var isCurrentStepValid: Bool {
        switch step {
        case .welcome:
            return true
        case .mode:
            return true
        case .consumable:
            if selectedType == nil { return false }
            if effectiveType == .custom {
                let hasName = !customConsumableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if customUnit == .other {
                    return hasName && !customUnitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return hasName
            }
            return true
        case .dailyAmount:
            return dailyAmountValue > 0
        case .unitPrice:
            if effectiveType == .weed {
                return (simpleInput.purchasePrice ?? 0) > 0 && (simpleInput.purchaseQuantity ?? 0) > 0
            }
            return (unitPriceValue ?? 0) > 0
        case .quantityPerPurchase:
            if pricingMode == .unit { return true }
            return quantityValue > 0
        case .summary:
            return true
        }
    }

    private func convertDisplayedAmountToDaily(_ value: Double) -> Double {
        var daily = max(0, value)

        if isMassInputToggleVisible, massDisplayUnit == .milligram {
            daily /= 1000
        }

        if usageFrequency == .weekly {
            daily /= 7
        }

        return daily
    }

    private var customConfigAnchorId: String { "custom-config-anchor" }
    private var unitPriceAnchorId: String { "unit-price-anchor" }
    private var quantityAnchorId: String { "quantity-anchor" }
    private var customUnitAnchorId: String { "custom-unit-anchor" }

    private var consumeUnitCostAmount: Double {
        let amountText = setupPreset.costAmountPerTrackText.replacingOccurrences(of: ",", with: ".")
        return Double(amountText) ?? 1
    }

    private var simpleInput: SimpleConsumptionInput {
        SimpleConsumptionInput(
            dailyAmountText: String(dailyAmountValue),
            dailyUnit: effectiveUnitOption.consumeUnit,
            purchasePriceText: unitPriceText,
            purchaseQuantityText: quantityCustomText.isEmpty ? String(quantityInPurchase) : quantityCustomText,
            purchaseUnit: setupPreset.defaultPurchaseUnit
        )
    }

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

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    GeometryReader { viewportProxy in
                        ScrollView(showsIndicators: false) {
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: OnboardingScrollOffsetPreferenceKey.self,
                                        value: proxy.frame(in: .named("onboardingScrollArea")).minY
                                    )
                            }
                            .frame(height: 0)

                            Group {
                                switch step {
                                case .welcome:
                                    welcomeStep
                                case .mode:
                                    modeStep
                                case .consumable:
                                    consumableStep
                                case .dailyAmount:
                                    dailyStep
                                case .unitPrice:
                                    priceStep
                                case .quantityPerPurchase:
                                    if pricingMode == .package {
                                        quantityStep
                                    } else {
                                        summaryStep
                                    }
                                case .summary:
                                    summaryStep
                                }
                            }
                            .transition(stepTransition)
                            .animation(.spring(response: 0.35, dampingFraction: 0.88), value: step)
                            .padding(.top, contentTopSpacing)
                            .padding(.bottom, bottomBarReservedHeight)
                            .background(
                                GeometryReader { contentProxy in
                                    Color.clear.preference(
                                        key: OnboardingScrollContentHeightPreferenceKey.self,
                                        value: contentProxy.size.height
                                    )
                                }
                            )
                        }
                        .scrollDisabled(!shouldEnableScroll)
                        .onChange(of: scrollTarget) { _, target in
                            guard let target else { return }
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(target, anchor: .center)
                            }
                        }
                        .onAppear {
                            scrollViewportHeight = viewportProxy.size.height
                        }
                        .onChange(of: viewportProxy.size.height) { _, newHeight in
                            scrollViewportHeight = newHeight
                        }
                        .overlay(alignment: .top) {
                            LinearGradient(
                                colors: [
                                    Color("Background").opacity(hasScrolledUnderChrome ? 0.72 : 0),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 30)
                            .allowsHitTesting(false)
                        }
                    }
                }
                .coordinateSpace(name: "onboardingScrollArea")
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            bootstrapInitialValues()
        }
        .onChange(of: focusedField) { _, field in
            switch field {
            case .customName:
                scrollTarget = customConfigAnchorId
            case .customUnitName:
                scrollTarget = customUnitAnchorId
            case .unitPrice:
                scrollTarget = unitPriceAnchorId
            case .quantityCustom:
                scrollTarget = quantityAnchorId
            case nil:
                break
            }
        }
        .onPreferenceChange(OnboardingScrollOffsetPreferenceKey.self) { value in
            scrollContentOffset = value
        }
        .onPreferenceChange(OnboardingScrollContentHeightPreferenceKey.self) { value in
            scrollBodyHeight = value
        }
        .safeAreaInset(edge: .bottom, spacing: -34) {
            bottomChrome
                .padding(.horizontal, 20)
                .padding(.bottom, -34)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var header: some View {
        let isFirstVisibleStep = step == visibleSteps.first

        return ZStack {
            HStack {
                Button {
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .hapticTap(.light)
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
                .opacity(isFirstVisibleStep ? 0 : 1)
                .disabled(isFirstVisibleStep)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(visibleProgressIndexes, id: \.self) { index in
                        Capsule()
                            .fill(index <= progressIndex ? Color("BrandAccentStrong") : Color("Border"))
                            .frame(width: index == progressIndex ? 20 : 8, height: 8)
                            .opacity(index == progressIndex ? 1 : 0.72)
                    }
                }
                .frame(width: 76, alignment: .trailing)
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
        .padding(.bottom, 6)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(hasScrolledUnderChrome ? 1 : 0)

                LinearGradient(
                    colors: [
                        Color.blue.opacity(hasScrolledUnderChrome ? 0.22 : 0),
                        Color.cyan.opacity(hasScrolledUnderChrome ? 0.08 : 0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    private var bottomChrome: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.clear, Color("Background").opacity(0.74), Color("Background").opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .allowsHitTesting(false)

            Rectangle()
                .fill(Color("Background"))
                .frame(height: 34)
                .allowsHitTesting(false)

            bottomBar
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            stepTitle(
                "Quick start",
                subtitle: "Track consume habits, money, progress, and rewards in one flow."
            )

            Text("This takes less than a minute.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color("TextSecondary"))

            VStack(alignment: .leading, spacing: 6) {
                Label("You can edit everything later", systemImage: "checkmark.circle.fill")
                Label("Your first setup powers money insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))

        }
    }

    private var modeStep: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            stepTitle(
                "How do you want to start?",
                subtitle: "Pick tracking mode for first consumable."
            )

            VStack(spacing: 12) {
                modeCard(
                    mode: .reduce,
                    title: "Reduce",
                    subtitle: "Track consume and purchases. See cost, savings, and usage patterns.",
                    icon: "chart.line.downtrend.xyaxis"
                )

                modeCard(
                    mode: .quit,
                    title: "Quit",
                    subtitle: "Start with quit streak, avoided units, saved money, and recovery milestones.",
                    icon: "flag.checkered"
                )
            }
        }
    }

    private var consumableStep: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            stepTitle(
                "What do you want to track first?",
                subtitle: "Pick one. You can add more later."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(TrackType.allCases) { type in
                    Button {
                        selectedType = type
                        if type != .custom {
                            customConsumableName = ""
                            customUnitName = ""
                            focusedField = nil
                        }
                        if type == .custom {
                            customPricingMode = .unit
                            customUsageMethod = .custom
                            customUnit = .other
                        }
                        dailyAmount = type.defaultDailyAmount
                        if let firstPreset = type.quantityPresets.first {
                            quantityInPurchase = firstPreset
                            quantityCustomText = ""
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2.weight(.semibold))
                            Text(type.title)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(selectedType == type ? Color("TextOnAccent") : Color("TextPrimary"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 94)
                        .background(
                            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                                .fill(selectedType == type ? Color("ButtonPrimaryBackground") : Color("Surface").opacity(0.72))
                        )
                    }
                    .hapticTap(.light)
                    .buttonStyle(.plain)
                }
            }

            if selectedType == .custom {
                VStack(alignment: .leading, spacing: 14) {
                    inputRow(label: "What should we call it?") {
                        TextField("e.g. Nicotine Pouch", text: $customConsumableName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(false)
                            .foregroundStyle(Color("TextPrimary"))
                            .focused($focusedField, equals: .customName)
                    }
                    .id(customConfigAnchorId)

                    if !customConsumableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Tracking: \(customConsumableName.trimmingCharacters(in: .whitespacesAndNewlines))")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color("TextSecondary"))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose unit")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))

                        pickerRow(label: "Unit") {
                            Picker("Unit", selection: $customUnit) {
                                ForEach(selectedType?.allowedUnits ?? UnitOption.allCases) { unit in
                                    Text(unit.label).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("TextPrimary"))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Usage method")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))

                        Picker("Usage method", selection: $customUsageMethod) {
                            Text("Per piece").tag(OnboardingUsageMethod.perPiece)
                            Text("Per session").tag(OnboardingUsageMethod.perSession)
                            Text("Per gram").tag(OnboardingUsageMethod.perGram)
                            Text("Per ml").tag(OnboardingUsageMethod.perMilliliter)
                            Text("Per cup").tag(OnboardingUsageMethod.perCup)
                            Text("Per dose").tag(OnboardingUsageMethod.perDose)
                            Text("Custom").tag(OnboardingUsageMethod.custom)
                        }
                        .pickerStyle(.menu)
                        .tint(Color("TextPrimary"))
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .background(Color("InputBackground"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if customUnit == .other {
                        inputRow(label: "Custom unit name") {
                            TextField("e.g. tab, puff, sip", text: $customUnitName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(Color("TextPrimary"))
                                .focused($focusedField, equals: .customUnitName)
                        }
                        .id(customUnitAnchorId)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pricing mode")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))

                        Picker("Pricing", selection: $customPricingMode) {
                            Text("Per unit").tag(PricingMode.unit)
                            Text("Per purchase").tag(PricingMode.package)
                        }
                        .pickerStyle(.segmented)
                        .tint(Color("ButtonPrimaryBackground"))

                        Text("Per unit = €10 for 1g\nPer purchase = €10 for bag/pack")
                            .font(.footnote)
                            .foregroundStyle(Color("TextSecondary"))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var dailyStep: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            stepTitle(
                "How much do you usually use each day?",
                subtitle: "Switch day/week and set your typical amount."
            )

            HStack(spacing: 10) {
                Picker("Frequency", selection: $usageFrequency) {
                    ForEach(UsageFrequency.allCases) { frequency in
                        Text(frequency.label).tag(frequency)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color("ButtonPrimaryBackground"))
            }

            if isMassInputToggleVisible {
                inputRow(label: "Amount") {
                    HStack(spacing: 10) {
                        TextField(
                            "e.g. 1.5",
                            value: displayedUsageAmountBinding,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color("TextPrimary"))

                        Spacer()

                        Picker("Mass unit", selection: $massDisplayUnit) {
                            ForEach(MassDisplayUnit.allCases) { unit in
                                Text(unit.rawValue.uppercased()).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color("TextPrimary"))
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(displayedUsagePresets, id: \.self) { value in
                        chipButton(
                            label: prettyNumber(value),
                            selected: abs(displayedUsageAmount - value) < 0.0001
                        ) {
                            dailyAmount = roundedDailyAmount(convertDisplayedAmountToDaily(value))
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            VStack(spacing: 12) {
                Text("Typical usage")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))

                Text("\(prettyNumber(displayedUsageAmount)) \(effectiveAmountUnitLabel)/\(usageFrequency.shortLabel)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("TextPrimary"))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                HStack(spacing: 14) {
                    adjustButton(symbol: "minus") {
                        let updated = max(0, displayedUsageAmount - displayAdjustStep)
                        dailyAmount = roundedDailyAmount(convertDisplayedAmountToDaily(updated))
                    }

                    Text("Adjust amount")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("TextSecondary"))

                    adjustButton(symbol: "plus") {
                        let updated = min(4000, displayedUsageAmount + displayAdjustStep)
                        dailyAmount = roundedDailyAmount(convertDisplayedAmountToDaily(updated))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color("Surface").opacity(0.78))
            )

            Text("At \(prettyNumber(dailyAmountValue))/day = about \(prettyNumber(monthlyUsageEstimate))/month")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("TextSecondary"))
                .padding(.horizontal, 2)
        }
    }

    private var priceStep: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            stepTitle(
                priceQuestionTitle,
                subtitle: priceQuestionSubtitle
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("Currency")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextSecondary"))

                    Spacer()

                    Menu {
                        ForEach(CurrencyOption.allCases) { currency in
                            Button(currency.rawValue) {
                                HapticService.selection()
                                selectedCurrencyCode = currency.rawValue
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedCurrencyCode)
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(Color("TextPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color("SurfaceElevated"))
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(effectiveType == .weed ? "Bag price" : "Price")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextSecondary"))

                    HStack(spacing: 6) {
                        Text(currencySymbol)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("TextSecondary"))

                        TextField("0", text: $unitPriceText)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))
                            .focused($focusedField, equals: .unitPrice)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color("SurfaceElevated").opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .id(unitPriceAnchorId)

                if effectiveType == .weed {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grams in bag")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))

                        HStack(spacing: 6) {
                            TextField("0", text: $quantityCustomText)
                                .keyboardType(.decimalPad)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Color("TextPrimary"))
                                .focused($focusedField, equals: .quantityCustom)

                            Text("g")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color("TextSecondary"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color("SurfaceElevated").opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color("Surface").opacity(0.78))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("At your current pace")
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))

                if let preview = monthlySpendPreviewOnPriceStep {
                    Text("\(formatCurrency(preview)) / month")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("BrandAccentStrong"))
                } else {
                    Text("Complete next step for monthly estimate")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("TextSecondary"))
                }

                if effectiveType == .weed,
                   let price = simpleInput.purchasePrice,
                   let grams = simpleInput.purchaseQuantity,
                   grams > 0,
                   let perUnit = simpleInput.costPerUnit,
                   let monthly = monthlySpend {
                    Text("\(formatCurrency(price)) / \(prettyNumber(grams))g = \(formatCurrency(perUnit))/g")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("TextSecondary"))

                    Text("\(prettyNumber(dailyAmountValue))g × 30 × \(formatCurrency(perUnit)) = \(formatCurrency(monthly))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("BrandAccentStrong"))
                }
            }
        }
    }

    private var quantityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(
                quantityQuestionTitle,
                subtitle: quantityQuestionSubtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(effectiveType.quantityPresets, id: \.self) { value in
                        chipButton(
                            label: prettyNumber(value),
                            selected: quantityInPurchase == value && quantityCustomText.isEmpty
                        ) {
                            quantityInPurchase = value
                            quantityCustomText = ""
                        }
                    }
                }
            }

            Stepper(value: $quantityInPurchase, in: 1...1000, step: 1) {
                Text("\(prettyNumber(quantityInPurchase)) \(purchaseUnitLabel) per purchase")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
            }

            inputRow(label: "Enter custom amount") {
                TextField("Enter amount", text: $quantityCustomText)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Color("TextPrimary"))
                    .focused($focusedField, equals: .quantityCustom)
            }
            .id(quantityAnchorId)

            VStack(alignment: .leading, spacing: 8) {
                Text("Cost per \(purchaseUnitLabel)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))

                Text(costPerUnit.map(formatCurrency) ?? "—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("TextPrimary"))

                Text("Cost per \(setupPreset.trackName)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))

                Text(costPerConsume.map(formatCurrency) ?? "—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("BrandAccentStrong"))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color("Surface").opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                            .stroke(Color("Border").opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(
                "Ready to break the loop?",
                subtitle: initialMode == .quit
                    ? (isConsumableOnly ? "Quit plan starts from chosen date." : "Quit plan starts after account setup.")
                    : "Here is your starting point."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("You currently average")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))

                Text("\(prettyNumber(dailyAmountValue)) \(effectiveUnitOption.label)/day")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("TextPrimary"))

                Text("Estimated monthly spend")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))

                Text(monthlySpend.map(formatCurrency) ?? "—")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("TextPrimary"))

                Text("If you reduce by 25%")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))

                Text("Save \(monthlySavingsAt25.map(formatCurrency) ?? "—")/month")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("BrandAccentStrong"))

                HStack(spacing: 6) {
                    Image(systemName: initialMode == .quit ? "flag.checkered" : "sparkles")
                    Text(initialMode == .quit ? "Dashboard opens in quit mode" : "Consumption-free day reward: +50 XP")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(Color("Surface").opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                            .stroke(Color("Border").opacity(0.22), lineWidth: 1)
                    )
            )

            if initialMode == .quit {
                quitDatePickerCard
            }

        }
    }

    private var quitDatePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quit date")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))

                Text("Today is selected by default.")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
            }

            DatePicker("", selection: $quitStartDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Color("ButtonPrimaryBackground"))
                .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(Color("Surface").opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                        .stroke(Color("Border").opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var bottomBar: some View {
        if isConsumableOnly, step == .summary {
            return AnyView(
                VStack(spacing: 10) {
                    Button {
                        onCompleteConsumable?(makeDraft())
                    } label: {
                        Label("Add Consumable", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .hapticTap(.medium)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("ButtonPrimaryBackground"))
                    .clipShape(Capsule())

                    Button {
                        onDismissConsumableFlow?()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(compactSignInText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                    }
                    .hapticTap(.light)
                    .buttonStyle(.borderedProminent)
                    .tint(compactSignInFill)
                    .overlay(
                        Capsule()
                            .stroke(compactSignInBorder, lineWidth: 1)
                    )
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            )
        }

        if step == .summary {
            return AnyView(
                VStack(spacing: 10) {
                    Button {
                        onChooseAuth(.register, makeDraft())
                    } label: {
                        Label("Create Account", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .hapticTap(.medium)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("ButtonPrimaryBackground"))
                    .clipShape(Capsule())

                    Button {
                        onChooseAuth(.guest, makeDraft())
                    } label: {
                        Label("Continue as Guest", systemImage: "person.crop.circle.badge.questionmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(summaryGuestText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .hapticTap(.medium)
                    .buttonStyle(.borderedProminent)
                    .tint(summaryGuestTint)
                    .clipShape(Capsule())
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            )
        }

        let isWelcomeStep = step == .welcome

        return AnyView(
            VStack(spacing: 10) {
                Button {
                    handlePrimaryAction()
                } label: {
                    Label(primaryCTA, systemImage: step == .summary ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .hapticTap(.medium)
                .buttonStyle(.borderedProminent)
                .tint(Color("ButtonPrimaryBackground"))
                .opacity(isCurrentStepValid ? 1 : 0.62)
                .clipShape(Capsule())
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(isCurrentStepValid ? 0 : 1)
                )
                .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
                .disabled(!isCurrentStepValid)

                if !isConsumableOnly {
                    Button {
                        onChooseAuth(.signIn, nil)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.subheadline.weight(.semibold))

                            Text("Sign In")
                                .font(isWelcomeStep ? .headline : .subheadline.weight(.semibold))
                        }
                        .foregroundStyle(isWelcomeStep ? Color("TextOnAccent") : compactSignInText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isWelcomeStep ? 13 : 9)
                    }
                    .hapticTap(isWelcomeStep ? .medium : .light)
                    .buttonStyle(.borderedProminent)
                    .tint(isWelcomeStep ? Color("ButtonPrimaryBackground") : compactSignInFill)
                    .overlay(
                        Capsule()
                            .stroke(isWelcomeStep ? Color.clear : compactSignInBorder, lineWidth: 1)
                    )
                    .shadow(color: isWelcomeStep ? Color.black.opacity(0.18) : Color.clear, radius: 10, y: 4)
                    .opacity(isWelcomeStep ? 1 : 0.92)
                    .scaleEffect(isWelcomeStep ? 1 : 0.985)
                    .animation(.easeInOut(duration: 0.22), value: isWelcomeStep)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
        )
    }

    private var primaryCTA: String {
        switch step {
        case .welcome:
            return "Get Started"
        case .mode:
            return "Continue"
        default:
            return "Next"
        }
    }

    private var compactSignInFill: Color {
        colorScheme == .light
            ? Color("SurfaceElevated").opacity(0.94)
            : Color("ButtonSecondaryBackground").opacity(0.8)
    }

    private var compactSignInBorder: Color {
        colorScheme == .light
            ? Color("BorderStrong").opacity(0.55)
            : Color("Border").opacity(0.45)
    }

    private var compactSignInText: Color {
        colorScheme == .light ? Color("TextSecondary") : Color("ButtonSecondaryText")
    }

    private var summaryGuestTint: Color {
        colorScheme == .light ? Color("BrandAccent") : Color("ButtonSecondaryBackground")
    }

    private var summaryGuestText: Color {
        colorScheme == .light ? Color("TextOnAccent") : Color("ButtonSecondaryText")
    }

    @ViewBuilder
    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .lineSpacing(1.5)
                .foregroundStyle(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(Color("TextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func modeCard(mode: OnboardingInitialMode, title: String, subtitle: String, icon: String) -> some View {
        let selected = initialMode == mode

        Button {
            initialMode = mode
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(selected ? Color("TextOnAccent") : Color("BrandAccentStrong"))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(selected ? Color.white.opacity(0.18) : Color("SurfaceElevated"))
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(selected ? Color("TextOnAccent") : Color("TextPrimary"))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(selected ? Color("TextOnAccent").opacity(0.82) : Color("TextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(selected ? Color("TextOnAccent") : Color("TextSecondary"))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(selected ? Color("ButtonPrimaryBackground") : Color("Surface").opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                            .stroke(selected ? Color.clear : Color("Border").opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .hapticTap(.light)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func inputRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))

            content()
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(Color("Surface").opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color("Border").opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func pickerRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .lineLimit(1)

            Spacer()

            content()
                .frame(minHeight: 24, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color("Surface").opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color("Border").opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func chipButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color("TextOnAccent") : Color("TextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(minHeight: 40)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(selected ? Color("ButtonPrimaryBackground") : Color("Surface").opacity(0.76))
                )
        }
        .hapticTap(.light)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func adjustButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color("SurfaceElevated"))
                        .overlay(
                            Circle()
                                .stroke(Color("Border").opacity(0.35), lineWidth: 1)
                        )
                )
        }
        .hapticTap(.light)
        .buttonStyle(.plain)
    }

    private func goBack() {
        guard let idx = visibleSteps.firstIndex(of: step), idx > 0 else { return }
        let previous = visibleSteps[idx - 1]
        isForwardNavigation = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            step = previous
        }
    }

    private func handlePrimaryAction() {
        if step == .summary {
            if isConsumableOnly {
                onCompleteConsumable?(makeDraft())
            }
            return
        }

        guard let idx = visibleSteps.firstIndex(of: step), idx + 1 < visibleSteps.count else { return }
        let next = visibleSteps[idx + 1]
        isForwardNavigation = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            step = next
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

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrencyCode
        formatter.locale = .current
        return formatter.currencySymbol ?? selectedCurrencyCode
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

        return "\(currencySymbol)\(value)"
    }

    private func prettyNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private func roundedDailyAmount(_ value: Double) -> Double {
        let clamped = max(0, value)
        return (clamped * 1000).rounded() / 1000
    }

    private func bootstrapInitialValues() {
        if let initialProfile {
            if initialProfile.baselineDailyConsume > 0 {
                dailyAmount = initialProfile.baselineDailyConsume
            }
            selectedCurrencyCode = initialProfile.preferredCurrencyCode
            if let cost = initialProfile.baselineCostPerConsume {
                unitPriceText = NSDecimalNumber(decimal: cost).stringValue
            }
        }

        if !CurrencyOption.allCases.map(\.rawValue).contains(selectedCurrencyCode) {
            selectedCurrencyCode = "EUR"
        }
    }

    private func makeDraft() -> OnboardingDraft {
        OnboardingDraft(
            initialMode: initialMode,
            quitStartDate: quitStartDate,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            preferredCurrencyCode: selectedCurrencyCode,
            baselineDailyConsume: max(0, dailyAmountValue),
            baselineCostPerConsume: costPerConsume,
            firstConsumableName: effectiveConsumableName,
            firstConsumableCategory: effectiveType.category,
            firstConsumableUnit: setupPreset.trackUnit,
            firstConsumableUsageMethod: effectiveUsageMethod,
            firstConsumablePricingMode: pricingMode == .unit ? .perUnit : .perPurchase,
            firstConsumablePurchaseUnit: setupPreset.defaultPurchaseUnit,
            firstConsumableUnitsPerPurchase: quantityValue,
            firstConsumableTrackName: setupPreset.trackName,
            firstConsumableTrackAmount: setupPreset.trackAmount,
            firstConsumableTrackUnit: setupPreset.trackUnit,
            firstConsumableCostAmountPerTrack: Double(setupPreset.costAmountPerTrackText.replacingOccurrences(of: ",", with: ".")) ?? 1,
            firstConsumableCostUnit: setupPreset.costUnit,
            firstConsumablePurchaseName: setupPreset.purchaseName,
            firstConsumableDefaultPurchaseAmount: quantityValue,
            addFirstConsumable: true
        )
    }
}

#Preview {
    OnboardingView(initialProfile: nil, onChooseAuth: { _, _ in })
}

private struct OnboardingScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct OnboardingScrollContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
