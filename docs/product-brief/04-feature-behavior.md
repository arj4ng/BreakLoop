# 04 feature verhalten

## auth + session
- nicht eingeloggt -> sign in zuerst
- eingeloggt + first login -> onboarding zuerst
- eingeloggt + onboarding fertig -> dashboard

## first onboarding
- fragt basisdaten zu konsum, preis, profil
- speichert daten für kosten + rewards baseline
- danach direkt dashboard mit ersten insights

## dashboard
- zeigt heutige kosten, monatskosten, einsparung
- updated nach jedem neuen eintrag
- bottom dock actions:
  - consumption entry (slide to submit)
  - purchase entry (slide to submit)

## expenses
- nutzer erfasst menge + preisbasis
- app berechnet kosten sofort
- werte landen im verlauf

## konsum plan
- nutzer setzt zielwert oder target datum
- app zeigt soll vs ist fortschritt

## rewards
- app prüft meilensteine nach updates
- bei treffer reward markieren

## settings
- nutzer ändert preis/gewohnheit
- app rechnet abhängige werte neu
