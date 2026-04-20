# BreakLoop

BreakLoop zeigt Rauchkosten klar.
App hilft Gewohnheit ändern.
Fortschritt bringt Belohnung.

## Problem und Nutzen

- Rauchen kostet viel Geld, oft unsichtbar im Alltag.
- Nutzer sehen echte Ausgaben pro Tag, Woche, Monat, Jahr.
- Sichtbarkeit + Ziele = mehr Motivation für Veränderung.

## MVP Features (geplant)

- `Dashboard`: Überblick über Kosten, Verlauf, Einsparung.
- `Expenses`: Zigaretten- und Ausgaben-Tracking.
- `QuitPlan`: Ziele, Reduktionsplan, Meilensteine.
- `Rewards`: Belohnungen bei erreichten Zielen.
- `Settings`: Preise, Gewohnheiten, Präferenzen.

## Architektur (kompakt)

- Pattern: `MVVM` + `Service Layer`.
- UI in `Views`.
- Logik in `ViewModels`.
- Datenstrukturen in `Models`.
- Infrastruktur in `Services`.

### Aktuelle Ordnerstruktur

```text
BreakLoop/
├── BreakLoop/
│   ├── App/
│   ├── Core/
│   ├── Shared/
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── Expenses/
│   │   ├── QuitPlan/
│   │   ├── Rewards/
│   │   └── Settings/
│   └── Resources/
└── BreakLoopTests/
```

## Getting Started

### Voraussetzungen

- macOS mit aktuellem Xcode.
- iOS Simulator oder physisches iPhone.

### Lokal starten

1. Projekt öffnen: `BreakLoop/BreakLoop.xcodeproj`
2. Scheme prüfen: `BreakLoop`
3. Zielgerät wählen.
4. Run (`Cmd + R`).

## Roadmap

### Phase 1: Scaffold (fertig)

- Grundstruktur erstellt.
- Feature-Module angelegt.
- Platzhalter-Dateien für MVVM + Services vorhanden.

### Phase 2: Expense Tracking

- Eingabe täglicher Zigarettenmenge.
- Preis pro Packung/Zigarette speichern.
- Kostenberechnung (Tag/Woche/Monat/Jahr).
- Persistenz lokal (erste Version).

### Phase 3: Quit Goals

- Ziel setzen (Reduktion oder Quit-Datum).
- Fortschritt gegen Ziel berechnen.
- Erinnerungslogik vorbereiten.

### Phase 4: Rewards

- Meilensteine definieren.
- Reward-Logik bei Zielerreichung.
- Einfache visuelle Erfolgsanzeige.

### Phase 5: Insights und Polish

- Trends und einfache Auswertungen.
- UX-Verbesserungen + Accessibility-Basis.
- Stabilität, Fehlerfälle, Feinschliff.

## Status und Next Steps

- Aktuell: Struktur steht, Features leer.
- Nächster Fokus: `Expenses` Datenmodell + erste Eingabemaske + Kostenformel.
- Danach: `Dashboard` mit Live-Zusammenfassung.
