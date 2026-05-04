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
    <img alt="Status" src="https://img.shields.io/badge/Status-Aktive%20Entwicklung-FF9F0A?style=for-the-badge" />
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
  <li><code>Onboarding Flow</code> → Mehrstufig, generisch für verschiedene Konsumtypen, mit Cost/Usage Baseline</li>
  <li><code>Auth Flow</code> → Sign in, Register, Guest mit Routing über Root Flow</li>
  <li><code>Dashboard</code> → Erste Live Übersicht mit KPIs, Sign out und Flow Integration</li>
  <li><code>Shared Models</code> → User, Consumable, ConsumeEntry, PurchaseEntry, Rewards, Stats</li>
  <li><code>CalculationService</code> → Kosten, Durchschnitt, Ersparnis, Reward Logik inkl. Bonus Dedupe und Unit Mapping</li>
  <li><code>Firestore Repositories</code> → CRUD für Profile, Consumables, ConsumeEntries, PurchaseEntries, Rewards</li>
  <li><code>Firebase</code> → Auth + Firestore integriert, guestUsers/users Scope vorbereitet</li>
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
    <td>✅ Fertig</td>
    <td>Firestore CRUD inkl. guest/registered Scope, Export/Import Snapshot Logik</td>
  </tr>
  <tr>
    <td>Onboarding + Auth UI</td>
    <td>🟡 In Arbeit</td>
    <td>Flow steht, laufender UX/Polish Feinschliff</td>
  </tr>
  <tr>
    <td>Feature Screens UI</td>
    <td>🟡 In Arbeit</td>
    <td>Dashboard erster Stand, weitere Feature Screens folgen</td>
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
    <td>✅ Fertig</td>
    <td>Auth + Repositories + guest/registered Datenpfade stehen</td>
  </tr>
  <tr>
    <td><strong>4 · Onboarding & Auth UX</strong></td>
    <td>🟡 In Arbeit</td>
    <td>Onboarding/Registration/SignIn Flow mit gutem UX Verhalten und stabilem Routing</td>
  </tr>
  <tr>
    <td><strong>5 · Entry Flows + Dashboard UI</strong></td>
    <td>🟡 In Arbeit</td>
    <td>Consume/Purchase Eingabe, Dashboard Live Werte, danach Rewards/Insights Polish</td>
  </tr>
</table>

## Aktueller Fokus

- Onboarding UX finalisieren (Flow ohne harte Sprünge, klare CTA am Ende)
- Register/SignIn sauber vom Onboarding aus öffnen und Datenübergabe stabil halten
- Erste echte Entry Flows anbinden (<code>ConsumeEntry</code> / <code>PurchaseEntry</code>)
- Dashboard Aktionen mit den Entry Flows verbinden
