// BreakLoop/ BreakLoop/ Shared/ Models/ TrackingMockData.swift

// tracking mock data
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

import Foundation


enum TrackingMockData {

    // demo profil für tests und previews
    static let userProfile = UserProfile(
        id: "user_demo_01",
        email: "demo@breakloop.app",
        displayName: "Demo User",
        baselineDailyConsume: 10,
        baselineCostPerConsume: Decimal(string: "0.45"),
        onboardingCompleted: true
    )

    // zwei items zeigen unterschiedliche units und costs
    static let consumableItems: [ConsumableItem] = [
        ConsumableItem(
            id: "item_cig_01",
            userId: "user_demo_01",
            name: "Cigarette",
            category: .nicotine,
            defaultUnit: .piece,
            defaultAmountPerConsume: 1,
            defaultCostPerConsume: Decimal(string: "0.45")
        ),
        ConsumableItem(
            id: "item_coffee_01",
            userId: "user_demo_01",
            name: "Coffee",
            category: .caffeine,
            defaultUnit: .cup,
            defaultAmountPerConsume: 1,
            defaultCostPerConsume: Decimal(string: "1.20")
        )
    ]

    // sample consume logs für recency, averages und streak checks
    static let consumeEntries: [ConsumeEntry] = [
        ConsumeEntry(
            id: "consume_01",
            userId: "user_demo_01",
            consumableItemId: "item_cig_01",
            timestamp: .now.addingTimeInterval(-3600 * 2),
            amount: 1,
            unit: .piece,
            trigger: .stress,
            cravingLevel: 6
        ),
        ConsumeEntry(
            id: "consume_02",
            userId: "user_demo_01",
            consumableItemId: "item_cig_01",
            timestamp: .now.addingTimeInterval(-3600 * 7),
            amount: 1,
            unit: .piece,
            trigger: .habit,
            cravingLevel: 5
        )
    ]

    // sample kauf damit cost per consume bereits daten hat
    static let purchaseEntries: [PurchaseEntry] = [
        PurchaseEntry(
            id: "purchase_01",
            userId: "user_demo_01",
            consumableItemId: "item_cig_01",
            purchaseDate: .now.addingTimeInterval(-86_400 * 3),
            price: Decimal(string: "9.00") ?? 9,
            quantity: 20,
            unit: .piece,
            productName: "Classic Pack"
        )
    ]
}
