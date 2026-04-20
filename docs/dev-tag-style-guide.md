# Dev Tag + Code Style Notizen

## Tag Übersicht

| Tag | Bedeutung |
|---|---|
| `01 APP FLOW` | App lifecycle, root routing, bootstrap |
| `02 AUTH` | Sign-in, session state, sign-out |
| `03 ONBOARDING` | First-time user setup flow |
| `04 DASHBOARD` | Dashboard UI + insight view logic |
| `05 SMOKE ENTRY` | Smoke entry flow |
| `06 PURCHASE ENTRY` | Purchase entry flow |
| `07 EXPENSES` | Cost/expense aggregation |
| `08 GOALS` | Quit/reduction goals |
| `09 REWARDS` | Milestones, reward unlock logic |
| `10 SETTINGS` | Preferences, user config |
| `11 MODELS` | Domain models/value types |
| `12 SERVICES` | Data/service/repository layer |
| `13 UI COMPONENTS` | Reusable UI components |
| `14 DESIGN COLORS` | Design system colors/tokens |
| `15 DESIGN TYPE` | Design system typography/tokens |
| `16 TESTING` | Test files/scenarios |

## Header Muster

```swift
// MARK: ┏━ [TAG] Titel
// MARK: ┗━ Kurze Beschreibung
```

Beispiel:

```swift
// MARK: ┏━ [05 SMOKE ENTRY] SmokeEntryViewModel
// MARK: ┗━ Eingabe, validierung, submit status
```

## Kommentar Stil

- Kommentare/notizen auf deutsch
- Code/identifier auf english
- Notizen kurz, klein, direkt
- keine unnötigen erklärungen für obvious code
- bei komplexeren stellen kurze note direkt davor
- bei init: eine kurze top-note, nicht jede `self` zeile einzeln kommentieren
- wenn inline note nötig ist, nur bei wirklich wichtiger stelle

## File Header Muster

```swift
// BreakLoop/ Pfad/ Datei.swift
// kurze datei bezeichnung
//
// Created by Arjang Khademi on DD.MM.YYYY
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
```

## Kurzer Self Check vor Commit

- passt tag zum block?
- header lesbar und kurz?
- notizen natürlich und knapp?
- keine over-commenting stellen?
