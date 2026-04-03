# SwifterX — Payments & bookings

## Overview

1. **Checkout** creates a Firestore order (`paymentStatus: unpaid`, `status: pending`).
2. **Cloud Function** `createStripePaymentIntent` reads `order.price` from Firestore, creates a Stripe PaymentIntent, stores `stripePaymentIntentId`, sets `paymentStatus: processing`.
3. **iOS** presents **Stripe PaymentSheet** with the `clientSecret`.
4. **Cloud Function** `confirmOrderPayment` verifies the PaymentIntent with Stripe, then sets `paymentStatus: paid` and `status: confirmed`.

Amounts are **never** taken from the client for the charge; the server uses the order document.

## iOS setup

1. **Add Swift Package** (if not already in the project):  
   `https://github.com/stripe/stripe-ios-spm` → product **StripePaymentSheet**.

2. **Publishable key** in `SwifterX-Info.plist` → `StripePublishableKey`  
   - Use a real `pk_test_...` or `pk_live_...` key (must **not** contain the substring `REPLACE_ME`).  
   - While the placeholder `pk_test_REPLACE_ME` is present, the app runs in **dev mode** (orders are created as paid/confirmed with no Stripe UI).

## Firebase / Stripe backend

1. From repo root (`swifterx-ios/`):

   ```bash
   cd firebase/functions && npm install && cd ../..
   ```

2. **Stripe Dashboard** → Developers → API keys → copy **Secret key** (`sk_test_...` or `sk_live_...`).

3. **Configure Functions secret key** (use one approach):

   **A — Deployed Cloud Functions (required for production):**

   ```bash
   firebase login
   firebase use <your-project-id>
   firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET"
   ```

   **B — Local emulator / `node`:** create `firebase/functions/.env` (see `.env.example`). This file is **gitignored**; never commit secrets.

4. **Deploy**:

   ```bash
   firebase deploy --only functions,firestore:rules
   ```

5. **Callable region**: default is `us-central1`. If you change it, set the same region in iOS:

   ```swift
   Functions.functions(region: "your-region")
   ```

## Firestore rules

Orders must be created as either:

- `paymentStatus: unpaid` + `status: pending` (Stripe path), or  
- `paymentStatus: paid` + `status: confirmed` (local dev without Stripe).

Only Cloud Functions (Admin SDK) should transition orders to **paid** in production.

## Testing

- Use [Stripe test cards](https://docs.stripe.com/testing) (e.g. `4242 4242 4242 4242`).
- Confirm in Stripe Dashboard → Payments that intents succeed.

## Production checklist

- [ ] Use live keys (`pk_live_` / `sk_live_`) via secure config / secrets.  
- [ ] Add **Stripe webhook** for `payment_intent.succeeded` as a backup to `confirmOrderPayment`.  
- [ ] **Apple Pay** / **SCA** — PaymentSheet handles most cases; enable Apple Pay in Stripe Dashboard if needed.  
- [ ] **Refunds** and **Connect** (paying providers) are out of scope for this phase.
