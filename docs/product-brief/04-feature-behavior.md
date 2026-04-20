# Feature Behavior

## Auth / Session
- Nicht eingeloggt -> Sign-in Screen zuerst.
- Eingeloggt + first login -> Onboarding Fragen zuerst.
- Eingeloggt + onboarding fertig -> direkt Dashboard.

## First-Time Onboarding
- Fragt Basisdaten: Konsum, Preis, Profil-Kontext.
- Speichert Daten für Kostenlogik + Rewards-Basis.
- Nach Submit -> Dashboard mit ersten Insights.

## Dashboard
- Zeigt: heutige Kosten, Monatskosten, Einsparung.
- Update nach jedem neuen Expense-Eintrag.
- Zeigt Bottom Dock mit zwei Actions:
  - `Smoke Entry` (slide to submit)
  - `Purchase Entry` (slide to submit)

## Expenses
- Nutzer erfasst Menge + Preisbasis.
- App berechnet Kosten sofort.
- Werte in Verlauf verfügbar.

## QuitPlan
- Nutzer setzt Zielwert oder Quit-Datum.
- App zeigt Soll vs Ist Fortschritt.

## Rewards
- App prüft Meilensteine nach Updates.
- Bei Treffer: Reward markieren.

## Settings
- Nutzer ändert Preis/Gewohnheit.
- App recalculated abhängige Kennzahlen.
