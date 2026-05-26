import Foundation

struct SimpleConsumptionInput: Hashable, Sendable {
    var dailyAmountText: String
    var dailyUnit: ConsumeUnit
    var purchasePriceText: String
    var purchaseQuantityText: String
    var purchaseUnit: ConsumeUnit

    var dailyAmount: Double? {
        Double(dailyAmountText.replacingOccurrences(of: ",", with: "."))
    }

    var purchasePrice: Decimal? {
        Decimal(string: purchasePriceText.replacingOccurrences(of: ",", with: "."))
    }

    var purchaseQuantity: Double? {
        Double(purchaseQuantityText.replacingOccurrences(of: ",", with: "."))
    }

    var costPerUnit: Decimal? {
        guard let price = purchasePrice, price > 0 else { return nil }
        guard let qty = purchaseQuantity, qty > 0 else { return nil }
        return price / Decimal(qty)
    }

    func costPerConsume(consumeUnitAmount: Double) -> Decimal? {
        guard let unitCost = costPerUnit else { return nil }
        return unitCost * Decimal(consumeUnitAmount)
    }

    func monthlyEstimatedSpend(consumeUnitAmount: Double) -> Decimal? {
        guard let daily = dailyAmount, daily > 0 else { return nil }
        guard let cpc = costPerConsume(consumeUnitAmount: consumeUnitAmount) else { return nil }
        return cpc * Decimal(daily * 30)
    }
}
