// BreakLoop/ BreakLoop/ Shared/ Models/ PurchaseEntry.swift

// purchase entry
//
// Created by Arjang Khademi on 27.04.2026
/*
  ╔════════════════════════════════════════════════════════╗
  ║  █████╗ ██████╗      ██╗ ██╗  ██╗  ███╗   ██╗  ██████╗ ║
  ║ ██╔══██╗██╔══██╗     ██║ ██║  ██║  ████╗  ██║ ██╔════╝ ║
  ║ ███████║██████╔╝     ██║ ███████║  ██╔██╗ ██║ ██║  ███╗║
  ║ ██╔══██║██╔══██╗██   ██║ ╚════██║  ██║╚██╗██║ ██║   ██║║
  ║ ██║  ██║██║  ██║╚█████╔╝      ██║  ██║ ╚████║ ╚██████╔╝║
  ║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝  ╚═╝  ╚═══╝  ╚═════╝ ║
  ╚═════════════════════════════════════════ [ DEV TAG ] ══╝
*/

import Foundation


// MARK: ┏━ [11 MODELS] PurchaseEntry
// MARK: ┗━ kaufdatensatz mit kosten pro einheit für spätere consume cost calc

// calculatedCostPerUnit wird beim speichern gesetzt für stabile history
struct PurchaseEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let consumableItemId: String
    var purchaseDate: Date
    var price: Decimal
    var quantity: Double
    var unit: ConsumeUnit
    var calculatedCostPerUnit: Decimal
    var productName: String?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAt: Date?

    init(
        id: String,
        userId: String,
        consumableItemId: String,
        purchaseDate: Date = .now,
        price: Decimal,
        quantity: Double,
        unit: ConsumeUnit,
        calculatedCostPerUnit: Decimal? = nil,
        productName: String? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDeleted: Bool = false,
        deletedAt: Date? = nil
    ) {

        let safeQuantity = max(0, quantity)

        // kosten pro einheit einmalig rechnen damit edits nachvollziehbar bleiben
        let unitCost: Decimal
        if let calculatedCostPerUnit {
            unitCost = calculatedCostPerUnit
        } else if safeQuantity > 0 {
            unitCost = price / Decimal(safeQuantity)
        } else {
            unitCost = .zero
        }

        self.id = id
        self.userId = userId
        self.consumableItemId = consumableItemId
        self.purchaseDate = purchaseDate
        self.price = max(0, price)
        self.quantity = safeQuantity
        self.unit = unit
        self.calculatedCostPerUnit = unitCost
        self.productName = productName
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
    }
}
