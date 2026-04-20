# BreakLoop

BreakLoop ist mein iOS-Bootcamp-Abschlussprojekt.

Die Idee: Raucher:innen sehen endlich klar, was ihr Konsum wirklich kostet, setzen sich Ziele und bleiben mit kleinen Rewards eher dran.

## Warum ich die App baue

Im Alltag wirken Zigarettenkosten oft „nicht so schlimm".
Wenn man die Zahlen aber auf Woche, Monat und Jahr sieht, ändert sich der Blick schnell.
Genau da setzt BreakLoop an.

## Was im MVP drin ist

- `Dashboard`: Kostenüberblick + erste Insights
- `Expenses`: Smoke- und Purchase-Entries
- `QuitPlan`: Reduktions- oder Quit-Ziel
- `Rewards`: Meilensteine sichtbar machen
- `Settings`: Preis- und Basiswerte anpassen

## Aktueller Stand

- Projektstruktur steht
- Design-System-Basis (Farben + Typografie) steht
- Domain-Modelle sind angelegt
- Nächster Fokus: Expense-Flow + Kostenberechnung

## Tech / Struktur

- iOS + SwiftUI
- MVVM + Service Layer
- Feature-first Struktur

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

## Lokal starten

1. `BreakLoop/BreakLoop.xcodeproj` öffnen
2. Scheme `BreakLoop` wählen
3. Simulator oder Device wählen
4. `Cmd + R`

## Geplante nächsten Schritte

1. Expense-Eingabe fertig machen (smoke + purchase)
2. Kostenlogik (Tag/Woche/Monat/Jahr) anschließen
3. Dashboard mit echten Werten füllen
4. QuitPlan + Rewards Flow anbinden

## Hinweis

Aktueller Stand ist bewusst MVP/Bootcamp-fokussiert.
