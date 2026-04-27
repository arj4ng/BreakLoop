<div align="center">
  <pre>
╔════════════════════════════════════════════════════════╗
║  █████╗ ██████╗      ██╗ ██╗  ██╗ ███╗   ██╗  ██████╗  ║
║ ██╔══██╗██╔══██╗     ██║ ██║  ██║ ████╗  ██║ ██╔════╝  ║
║ ███████║██████╔╝     ██║ ███████║ ██╔██╗ ██║ ██║  ███╗ ║
║ ██╔══██║██╔══██╗██   ██║ ╚════██║ ██║╚██╗██║ ██║   ██║ ║
║ ██║  ██║██║  ██║╚█████╔╝      ██║ ██║ ╚████║ ╚██████╔╝ ║
║ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝       ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ║
╚═════════════════════[ ON THE CODE ]════════════════════╝
  </pre>

  <h1>BreakLoop</h1>
  <img src="./docs/assets/breakloop-readme-icon-256.png" alt="BreakLoop App Icon" width="128" />
  <p><strong>Konsumkosten sichtbar machen. Gewohnheit brechen. Fortschritt belohnen.</strong></p>

  <p>
    <img alt="Plattform" src="https://img.shields.io/badge/Plattform-iOS-0A84FF?style=for-the-badge" />
    <img alt="Architektur" src="https://img.shields.io/badge/Architektur-MVVM%20%2B%20Service%20Layer-34C759?style=for-the-badge" />
    <img alt="Status" src="https://img.shields.io/badge/Status-In%20Arbeit-FF9F0A?style=for-the-badge" />
  </p>
</div>

## Kurzpitch

BreakLoop ist mein iOS Bootcamp Abschlussprojekt.

Die Idee: Nutzer:innen sehen klar, was ihr Konsum wirklich kostet, setzen sich Ziele und bleiben mit kleinen Rewards eher dran.

## Warum ich die App baue

Im Alltag wirken Konsumkosten oft „nicht so schlimm".
Wenn man die Zahlen aber auf Woche, Monat und Jahr sieht, ändert sich der Blick schnell.
Genau da setzt BreakLoop an.

## Was aktuell drin ist

<ul>
  <li><code>Dashboard</code> → Scaffold + Platz für Live Insights</li>
  <li><code>Expenses</code> → Scaffold für Consume und Purchase Flow</li>
  <li><code>ConsumptionPlan</code> → Scaffold für Reduktionsziele</li>
  <li><code>Rewards</code> → Scaffold für Reward Anzeige</li>
  <li><code>Settings</code> → Scaffold für Profile und App Settings</li>
  <li><code>Shared Models</code> → User, Consumable, ConsumeEntry, PurchaseEntry, Rewards, Stats</li>
  <li><code>CalculationService</code> → Kosten, Average, Saved Money, Reward Punkte, Consume free Checks</li>
  <li><code>Firebase</code> → Auth + Firestore + Messaging integriert und konfiguriert</li>
</ul>

## Tech und Struktur

- iOS + SwiftUI
- MVVM + Service Layer
- Firebase (Auth, Firestore, Messaging)
- Feature first Struktur

```text
BreakLoop/
├── BreakLoop/
│   ├── App/
│   ├── Core/
│   ├── Shared/
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── Expenses/
│   │   ├── ConsumptionPlan/
│   │   ├── Rewards/
│   │   └── Settings/
│   └── Resources/
└── BreakLoopTests/
```

## Projektstatus

<table>
  <tr>
    <th align="left">Bereich</th>
    <th align="left">Status</th>
    <th align="left">Notiz</th>
  </tr>
  <tr>
    <td>Projektstruktur</td>
    <td>✅ Fertig</td>
    <td>Feature first Struktur steht</td>
  </tr>
  <tr>
    <td>Design System</td>
    <td>✅ Basis fertig</td>
    <td>Farben + Typografie angelegt</td>
  </tr>
  <tr>
    <td>Domain Modelle</td>
    <td>✅ Fertig</td>
    <td>Generische Konsum Modelle inkl. Stats und Rewards stehen</td>
  </tr>
  <tr>
    <td>Calculation Engine</td>
    <td>✅ Fertig</td>
    <td>Average, Cost, Saved Money und Reward Logik implementiert</td>
  </tr>
  <tr>
    <td>Firebase Setup</td>
    <td>✅ Fertig</td>
    <td>SDK eingebunden, plist gesetzt, <code>FirebaseApp.configure()</code> aktiv</td>
  </tr>
  <tr>
    <td>Repository Implementierung</td>
    <td>🟡 In Arbeit</td>
    <td>Firestore CRUD als nächster konkreter Schritt</td>
  </tr>
  <tr>
    <td>UI Umsetzung</td>
    <td>⏳ Geplant</td>
    <td>Views bleiben absichtlich noch Scaffold only</td>
  </tr>
</table>

## Roadmap

<table>
  <tr>
    <th align="left">Phase</th>
    <th align="left">Status</th>
    <th align="left">Ziel</th>
  </tr>
  <tr>
    <td><strong>1 · Scaffold</strong></td>
    <td>✅ Fertig</td>
    <td>Grundstruktur, Module, Basis Design System</td>
  </tr>
  <tr>
    <td><strong>2 · Core Tracking Engine</strong></td>
    <td>✅ Fertig</td>
    <td>Modelle + Berechnungen für Konsum, Kosten, Ersparnis und Rewards</td>
  </tr>
  <tr>
    <td><strong>3 · Firebase Data Layer</strong></td>
    <td>🟡 Nächster Schritt</td>
    <td>Auth Flow und Firestore Repositories mit echten Daten</td>
  </tr>
  <tr>
    <td><strong>4 · Entry Flows + Dashboard UI</strong></td>
    <td>⏳ Geplant</td>
    <td>Consume/Purchase Eingabe und Dashboard mit Live Werten</td>
  </tr>
  <tr>
    <td><strong>5 · Rewards + Insights + Polish</strong></td>
    <td>⏳ Geplant</td>
    <td>Streaks, Rewards Screen, bessere Auswertung, UX Feinschliff</td>
  </tr>
</table>
