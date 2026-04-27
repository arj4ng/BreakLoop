# 07 firestore + onboarding hierarchy

## app routing
- `loading` -> session/profile prüfen
- `onboarding` -> daten sammeln vor auth entscheid
- `auth` -> sign in flow
- `app` -> dashboard + tracking

## firestore roots
- `users/{userId}` für registrierte accounts
- `guestUsers/{guestId}` für guest accounts

## subcollections pro account
- `consumableItems/{itemId}`
- `consumeEntries/{entryId}`
- `purchaseEntries/{entryId}`
- `rewardEntries/{entryId}`

## user doc kernfelder
- `id`
- `displayName`
- `email`
- `isGuestAccount`
- `onboardingCompleted`
- `preferredCurrencyCode`
- `baselineDailyConsume`
- `baselineCostPerConsume`
- `createdAt`
- `updatedAt`

## onboarding -> daten mapping
- slide consumable -> `firstConsumableName/category/unit`
- usage slide -> `baselineDailyConsume`
- price slide -> `baselineCostPerConsume`
- currency -> `preferredCurrencyCode`

## pricing flow regel
- `perUnit` -> `costPerConsume = enteredPrice`
- `perPurchase` -> `costPerConsume = purchasePrice / unitsPerPurchase`
- nur `perPurchase` zeigt paket menge step

## guest merge regel
- guest + register neu -> guest daten in neuen user mergen
- guest + sign in existing:
- target leer -> guest daten mergen
- target hat daten -> guest daten verwerfen nach bestätigung

## repository zuständigkeit
- `AuthService` -> session/login/signup/link/signout
- `FirestoreTrackingRepository` -> profile + items + entries + rewards
- migration helper -> snapshot export/import + empty check
