# Minimal Pseudocode

## Global Flow
```text
onAppStart:
  if not signed in -> show sign in
  if signed in and onboarding missing -> show onboarding
  else load settings + expenses
  compute summary metrics
  show dashboard
```

## Auth / Session
```text
onSignInSuccess(user):
  if first login or onboarding incomplete -> route onboarding
  else -> route dashboard
```

## First-Time Onboarding
```text
onOnboardingSubmit(profile):
  validate profile inputs
  store baseline consume + price data
  compute initial baseline metrics
  route dashboard
```

## Dashboard
```text
onDashboardOpen:
  read summary metrics
  render cost + savings cards
  render bottom entry dock
```

## Expenses
```text
onExpenseSubmit(input):
  validate input
  store expense entry
  recompute totals
  notify dashboard + rewards
```

## QuitPlan
```text
onGoalSave(goal):
  store goal
  compute progress baseline
  show next milestone
```

## Rewards
```text
onProgressUpdate(progress):
  if milestone reached -> unlock reward
  persist reward state
  show reward feedback
```

## Settings
```text
onSettingsChange(values):
  store values
  recompute all derived metrics
  refresh visible screens
```
