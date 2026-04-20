<div align="center">
  <h1>🚭 BreakLoop</h1>
  <p><strong>Rauchkosten sichtbar machen. Gewohnheit brechen. Fortschritt belohnen.</strong></p>

  <p>
    <img alt="Plattform" src="https://img.shields.io/badge/Plattform-iOS-0A84FF?style=for-the-badge" />
    <img alt="Architektur" src="https://img.shields.io/badge/Architektur-MVVM%20%2B%20Service%20Layer-34C759?style=for-the-badge" />
    <img alt="Status" src="https://img.shields.io/badge/Status-Bootcamp%20MVP-FF9F0A?style=for-the-badge" />
  </p>
</div>

<br/>

## Kurzpitch

BreakLoop zeigt echte Rauchkosten pro Tag, Woche, Monat, Jahr.  
App unterstützt Verhaltensänderung über Ziele, Fortschritt, Rewards.

## Problem → Nutzen

<table>
  <tr>
    <th align="left">Problem</th>
    <th align="left">Nutzen</th>
  </tr>
  <tr>
    <td>Rauchkosten im Alltag unsichtbar</td>
    <td>Kosten werden sofort messbar</td>
  </tr>
  <tr>
    <td>Motivation fällt ohne Feedback</td>
    <td>Ziele + Fortschritt erhöhen Motivation</td>
  </tr>
  <tr>
    <td>Keine Belohnung bei Reduktion</td>
    <td>Rewards markieren echte Erfolge</td>
  </tr>
</table>

## MVP Features

<div>
  <ul>
    <li><code>Dashboard</code> → Kostenüberblick, Verlauf, Einsparung</li>
    <li><code>Expenses</code> → Zigaretten- und Ausgaben-Tracking</li>
    <li><code>QuitPlan</code> → Ziele, Reduktionsplan, Meilensteine</li>
    <li><code>Rewards</code> → Belohnungen bei Zielerreichung</li>
    <li><code>Settings</code> → Preise, Gewohnheiten, Präferenzen</li>
  </ul>
</div>

## Architektur

<details open>
  <summary><strong>MVVM + Service Layer</strong></summary>
  <br/>
  <ul>
    <li>UI in <code>Views</code></li>
    <li>Feature-Logik in <code>ViewModels</code></li>
    <li>Datenstrukturen in <code>Models</code></li>
    <li>Infrastruktur in <code>Services</code></li>
  </ul>
</details>

### Ordnerstruktur

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

<ol>
  <li>Projekt öffnen: <code>BreakLoop/BreakLoop.xcodeproj</code></li>
  <li>Scheme wählen: <code>BreakLoop</code></li>
  <li>Zielgerät wählen (Simulator oder Device)</li>
  <li>Run mit <code>Cmd + R</code></li>
</ol>

## Roadmap

<table>
  <tr>
    <th align="left">Phase</th>
    <th align="left">Status</th>
    <th align="left">Ziele</th>
  </tr>
  <tr>
    <td><strong>1 · Scaffold</strong></td>
    <td>✅ Fertig</td>
    <td>Grundstruktur, Module, Platzhalter-Typen</td>
  </tr>
  <tr>
    <td><strong>2 · Expense Tracking</strong></td>
    <td>🟡 Nächster Schritt</td>
    <td>Eingabe, Preislogik, Kostenberechnung, Persistenz</td>
  </tr>
  <tr>
    <td><strong>3 · Quit Goals</strong></td>
    <td>⏳ Geplant</td>
    <td>Ziele, Fortschrittsberechnung, Erinnerungsbasis</td>
  </tr>
  <tr>
    <td><strong>4 · Rewards</strong></td>
    <td>⏳ Geplant</td>
    <td>Meilensteine, Reward-Logik, Erfolgsanzeige</td>
  </tr>
  <tr>
    <td><strong>5 · Insights & Polish</strong></td>
    <td>⏳ Geplant</td>
    <td>Trends, UX-Polish, Accessibility-Basis</td>
  </tr>
</table>

## Aktueller Stand

- Struktur steht.
- Features noch ohne Business-Logik.
- Nächster Fokus: `Expenses` Datenmodell + Eingabemaske + Kostenformel.

