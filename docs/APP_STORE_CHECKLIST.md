# SwifterX — App Store Submission Checklist

Track each item to complete before submitting to App Store review.

---

## Phase 1 — Launch hardening (do in this order)

| Order | What | Where |
|------:|------|--------|
| 1 | App record + URLs + categories + description/keywords | **§1** below + `fastlane/metadata/` (sync with `fastlane release` or paste in ASC) |
| 2 | Screenshots (3–10 per size) | **§2** — run `fastlane screenshots` (scheme **`SwifterXUITests`** + `SwifterXUITests/SwifterXUITests.swift`); add more `snapshot("…")` steps as needed; set `skip_screenshots: false` in `Fastfile` `release` when `fastlane/screenshots` is populated |
| 3 | 1024 icon opaque RGB | **§3** — `AppIcon.appiconset` |
| 4 | Capabilities + APNs + profiles | **§4** — Apple Developer |
| 5 | Stripe live + webhooks | **§5** — Stripe + `firebase functions:secrets:set` |
| 6 | Deploy rules/indexes/functions; App Check DeviceCheck + debug tokens | **§6** + **§6a** — Firebase Console |
| 7 | Privacy manifest + export compliance | **§7**–**§8** |
| 8 | Firebase review accounts + paste review notes | **§9** |
| 9 | `fastlane beta` → internal TestFlight smoke → App Check enforcement **on** → `fastlane release` | **§10** |

**Fastlane:** set `APP_STORE_CONNECT_API_*` env vars; replace placeholder `apple_id` in `fastlane/Appfile`. `beta` / `release` run `bump_build` then `build_release` (single bump per lane).

---

## 1. App Store Connect Setup

| Task | Status | Notes |
|------|--------|-------|
| Create app record in ASC (bundle ID: `com.swifterx.app`) | ⬜ | App Store Connect → My Apps → + |
| Set primary language to English (U.S.) | ⬜ | |
| Set primary category: **Lifestyle** / secondary: **Business** | ⬜ | Matches `fastlane/metadata/primary_category.txt` + `secondary_category.txt` |
| Add app description (see `fastlane/metadata/en-US/description.txt`) | ⬜ | ≤ 4000 chars |
| Add keywords (see `fastlane/metadata/en-US/keywords.txt`) | ⬜ | ≤ 100 chars |
| Add support URL: `https://swifterx.app/support` | ⬜ | Required |
| Add privacy policy URL: `https://swifterx.app/privacy` | ⬜ | **Required** for apps that collect data or use payments |
| Add marketing URL: `https://swifterx.app` | ⬜ | Optional but recommended |

---

## 2. Screenshots (Required Device Sizes)

Run `fastlane screenshots` from the repo root (shared scheme **`SwifterXUITests`**; UI tests live in `ios/SwifterX/SwifterXUITests/`).  
Or capture manually in Simulator and export.

| Device | Size | Status |
|--------|------|--------|
| iPhone 16 Pro Max | 1320 × 2868 px | ⬜ |
| iPhone 16 | 1179 × 2556 px | ⬜ |
| iPhone SE (3rd gen) | 750 × 1334 px | ⬜ |
| iPad Pro 13-inch (M4) | 2064 × 2752 px | ⬜ |

Each device needs **3–10 screenshots**. Recommended screens to capture:
1. Splash / Home screen (with hero banner)
2. Services browse + search
3. Provider detail
4. Booking / checkout
5. Order tracking (live map)
6. Provider inbox
7. Payout dashboard

---

## 3. App Icon

| Size | Status |
|------|--------|
| 1024 × 1024 px (App Store icon, no transparency, no rounded corners) | ⬜ |
| All device sizes in `Assets.xcassets/AppIcon.appiconset` | ⬜ |

---

## 4. Apple Developer Portal

| Task | Status | Notes |
|------|--------|-------|
| Confirm bundle ID `com.swifterx.app` registered | ⬜ | developer.apple.com → Identifiers |
| Enable **Push Notifications** capability | ⬜ | In Identifier → Capabilities |
| Enable **Apple Pay** capability | ⬜ | Merchant ID: `merchant.com.swifterx.app` |
| Enable **Associated Domains** capability | ⬜ | `applinks:swifterx.app` |
| Create Distribution provisioning profile | ⬜ | Profiles → + → App Store |
| APNs Auth Key (.p8) uploaded to Firebase → Cloud Messaging | ⬜ | Project Settings → Cloud Messaging |

---

## 5. Stripe Configuration

| Task | Status | Notes |
|------|--------|-------|
| Stripe account live mode enabled | ⬜ | dashboard.stripe.com |
| Merchant ID registered in Stripe Apple Pay | ⬜ | Stripe Dashboard → Settings → Apple Pay |
| `STRIPE_SECRET_KEY` (live) set in Firebase secrets | ⬜ | `firebase functions:secrets:set STRIPE_SECRET_KEY` |
| `STRIPE_WEBHOOK_SECRET` set in Firebase secrets | ⬜ | `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET` |
| Webhook endpoint registered in Stripe Dashboard | ⬜ | URL: `https://<region>-swifterx-e7f15.cloudfunctions.net/stripeWebhook` |
| Webhook events enabled: `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`, `account.updated` | ⬜ | |

---

## 6. Firebase Production Readiness

| Task | Status | Notes |
|------|--------|-------|
| Firestore security rules deployed | ⬜ | `firebase deploy --only firestore:rules` |
| Firestore indexes deployed | ⬜ | `firebase deploy --only firestore:indexes` |
| Cloud Functions deployed | ⬜ | `firebase deploy --only functions` |
| Firebase App Check enabled (DeviceCheck for production) | ⬜ | See **6a** below — app configures providers in code |
| Crashlytics enabled | ⬜ | dSYM uploaded automatically on archive |
| Analytics enabled | ⬜ | |

### 6a. App Check (launch hardening)

The iOS app registers **Debug** (simulator / dev) or **DeviceCheck** (Release) before `FirebaseApp.configure()`.

1. **Firebase Console** → **App Check** → your iOS app → register **Device Check** as the production provider.
2. **Debug builds**: Run once from Xcode; check the Xcode console for the **App Check debug token**, then in App Check → **Manage debug tokens** → add it so simulator/dev can talk to Firestore/Functions after you turn on enforcement.
3. **Enforcement**: Start with **off**; after TestFlight smoke test, enable enforcement for **Firestore** (and **Cloud Functions** if you add `enforceAppCheck` on callables) so only attested clients get through.

---

## 7. Privacy Manifest (`PrivacyInfo.xcprivacy`)

| Data Type | Collected | Linked to User | Used for Tracking |
|-----------|-----------|----------------|-------------------|
| Name | ✅ | ✅ | ❌ |
| Email address | ✅ | ✅ | ❌ |
| Phone number | ✅ | ✅ | ❌ |
| Precise location | ✅ | ✅ | ❌ |
| User ID | ✅ | ✅ | ❌ |
| Purchase history | ✅ | ✅ | ❌ |
| Payment info | ✅ (Stripe-hosted) | ✅ | ❌ |

Verify `PrivacyInfo.xcprivacy` lists all required reasons APIs used (e.g., `NSPrivacyAccessedAPICategoryUserDefaults`).  
`NSPrivacyCollectedDataTypePaymentInfo` is declared for Stripe PaymentSheet (aligns with App Store Connect privacy labels).

---

## 8. Export Compliance (HTTPS / Encryption)

| Task | Status |
|------|--------|
| Set `ITSAppUsesNonExemptEncryption = NO` in `Info.plist` (if only using standard HTTPS/TLS) | ⬜ | Already set in `SwifterX-Info.plist` — confirm before each archive |

If you use any custom encryption beyond standard HTTPS, you need to file an ERN (Export Regulations Number).

---

## 9. App Review Notes (to submit with your review request)

You **cannot** create Firebase users from this repo alone. Create the accounts below in **Firebase Console** (or sign up once in the app), then paste the same credentials into App Store Connect → **App Review Information** → **Notes**.

### 9a. Dummy accounts to use (register these yourself)

Use these **exact emails** so your review notes match what you configure in Firebase. Set passwords to **at least 8 characters** with a number (matches typical app validation).

| Role | Email | Password (example — set the same in Firebase Auth) |
|------|--------|------------------------------------------------------|
| Customer | `reviewer@swifterx.app` | `ReviewerPass123!` |
| Provider | `provider-reviewer@swifterx.app` | `ProviderPass123!` |

**Create users in Firebase Authentication**

1. Open [Firebase Console](https://console.firebase.google.com) → your project → **Build** → **Authentication** → **Users**.
2. Click **Add user** → enter **Email** and **Password** from the table → **Add user**.
3. Repeat for the second account.
4. **Email/Password** sign-in must be enabled: **Authentication** → **Sign-in method** → **Email/Password** → On.

**Customer account — profile document**

- Sign in to the **SwifterX** app once as `reviewer@swifterx.app` and complete onboarding if prompted, **or** ensure Firestore has `users/{customerUid}` (the app usually creates this on first sign-in).

**Provider account — approval so search & jobs work**

After the provider finishes onboarding (or you create `providerProfiles/{providerUid}` manually):

1. In **Firestore** → `providerProfiles` → document ID = the provider’s **Auth UID** → set:
   - `approved` = `true`
   - `approvedAt` = server timestamp or ISO date string (optional but helpful)
2. Ensure **`providers/{sameUid}`** exists with `listingApproved` = `true` (the **`onProviderProfileWrite`** Cloud Function usually syncs this when the profile is saved from the app; otherwise set it manually in the console).

Without approval, the provider **will not appear** in customer search or be able to claim jobs.

**Sanity check before submit**

- Log in as **customer** → browse providers → start a booking flow.  
- Log in as **provider** → see job inbox / account (depending on your build).

---

### 9b. Text to paste into App Store Connect (Review Notes)

```
SwifterX is a home-services marketplace that connects customers with local service providers.

TEST ACCOUNT (Customer):
  Email: reviewer@swifterx.app
  Password: ReviewerPass123!

TEST ACCOUNT (Provider):
  Email: provider-reviewer@swifterx.app
  Password: ProviderPass123!

IMPORTANT — Provider approval:
The provider account is approved for the marketplace. If search is empty, pull to refresh on Home or wait a few seconds after login.

Payments: Stripe test mode for review. Use card 4242 4242 4242 4242, any future expiry, any CVV.

APPLE PAY (PassKit): The app binary includes PassKit because Stripe PaymentSheet integrates Apple Pay (see `CheckoutPaymentCoordinator.presentPaymentSheet`). After you tap Place Order on checkout, the Stripe payment sheet is presented; Apple Pay appears on that sheet when the review device has Wallet / Apple Pay available (US merchant). If Apple Pay is not shown, complete payment with the test card above — the same sheet is the Apple Pay integration point.

Location: Please allow location when prompted (nearby providers).

Push notifications: Optional for review; allow if prompted for order updates.
```

Change passwords in the note **only if** you used different passwords in Firebase Auth.

---

## 10. Final Build & Upload

```bash
# Set API key env vars (from App Store Connect → Users & Access → Keys)
export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export APP_STORE_CONNECT_API_KEY_CONTENT=$(base64 -i AuthKey_XXXXXXXXXX.p8)

# Push to TestFlight first for internal testing
cd /path/to/swifterx-ios   # repo root (Fastfile uses ios/SwifterX/… paths)
fastlane beta

# When ready for App Store review
fastlane release
# Then go to App Store Connect → App → Prepare for Submission → Submit for Review
```

---

## 11. Age Rating

Set in ASC → App Information → Age Rating:
- **Made for Kids**: No
- **Cartoon / Fantasy Violence**: None
- **Realistic Violence**: None
- **Sexual Content**: None
- **Profanity**: None
- **Gambling**: None
- **Medical / Health**: No
→ **Result: 4+**

---

## Post-Submission

- [ ] Monitor Crashlytics dashboard for day-1 crashes
- [ ] Check Firebase Analytics for funnel drop-offs
- [ ] Set up App Store Connect alerts for reviews
- [ ] Respond to user reviews within 24 hours
- [ ] Monitor Stripe Dashboard for failed payments
