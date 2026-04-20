// BreakLoop/ BreakLoop/ Shared/ Models/ Goal.swift

// goal
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

import Foundation


// MARK: ┏━ [08 GOALS] Goal
// MARK: ┗━ Nutzerziel für tägliche Reduktion oder Rauchstopp Datum

// ziel model generisch halten, damit rewards/progress später reusable bleiben
struct Goal: Identifiable, Codable, Hashable, Sendable {

    // MARK: ┏━ [08 GOALS] Kind
    // MARK: ┗━ Zielstrategie varianten für den quit plan flow

    enum Kind: String, Codable, Hashable, Sendable {

        // reduziert zielwert auf täglicher basis
        case reduceDaily

        // zielt auf kompletten stopp bis datum
        case quitByDate
    }

    let id: UUID
    var kind: Kind

    // nur relevant wenn kind reduceDaily ist
    var targetDailyCigarettes: Int?

    // nur relevant wenn kind quitByDate ist
    var targetDate: Date?

    // startpunkt für progress berechnung
    var startDate: Date
    let createdAt: Date
    var updatedAt: Date

    // init deckt beide zielarten mit optionalen zielwerten ab
    init(
        id: UUID = UUID(),
        kind: Kind,
        targetDailyCigarettes: Int? = nil,
        targetDate: Date? = nil,
        startDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {

        // init mapped eingaben direkt auf das model
        self.id = id
        self.kind = kind
        self.targetDailyCigarettes = targetDailyCigarettes // nur für reduceDaily relevant
        self.targetDate = targetDate // nur für quitByDate relevant
        self.startDate = startDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
