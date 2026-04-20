# 05 pseudo flow

## app start
```text
onAppStart:
  if not signed in -> show sign in
  if signed in and onboarding missing -> show onboarding
  else load settings + expenses
  compute summary metrics
  show dashboard
```

## auth
```text
onSignInSuccess(user):
  if first login or onboarding incomplete -> route onboarding
  else -> route dashboard
```

## onboarding
```text
onOnboardingSubmit(profile):
  validate profile inputs
  store baseline consume + price data
  compute initial baseline metrics
  route dashboard
```

## dashboard
```text
onDashboardOpen:
  read summary metrics
  render cost + savings cards
  render bottom entry dock
```

## expenses
```text
onExpenseSubmit(input):
  validate input
  store expense entry
  recompute totals
  notify dashboard + rewards
```

## konsum plan
```text
onGoalSave(goal):
  store goal
  compute progress baseline
  show next milestone
```

## rewards
```text
onProgressUpdate(progress):
  if milestone reached -> unlock reward
  persist reward state
  show reward feedback
```

## settings
```text
onSettingsChange(values):
  store values
  recompute all derived metrics
  refresh visible screens
```
