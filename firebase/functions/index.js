/**
 * SwifterX — Cloud Functions
 * Stripe Webhooks, PaymentIntents, Connect payouts, and order lifecycle.
 *
 * Secrets (set once):
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 *
 * Deploy:
 *   firebase deploy --project swifterx-e7f15 --only functions,firestore:rules,storage
 */
// 1st gen API (runWith, .firestore.document, etc.) — v6+ exposes this under /v1
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const Stripe = require("stripe");

if (!admin.apps.length) admin.initializeApp();

// ─── Platform fee (20 % — SwifterX's cut) ────────────────────────────────────
const PLATFORM_FEE_PERCENT = 0.20;

// ─── Input sanitization ───────────────────────────────────────────────────────
function sanitizeStr(value, maxLen = 2000) {
  if (typeof value !== "string") return null;
  const cleaned = value.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "").trim();
  return cleaned.length > 0 ? cleaned.slice(0, maxLen) : null;
}

function sanitizeOrderId(value) {
  const s = sanitizeStr(value, 128);
  if (!s || !/^[A-Za-z0-9\-_]{8,128}$/.test(s)) return null;
  return s;
}

function sanitizeFirebaseUid(value) {
  const s = sanitizeStr(value, 128);
  if (!s || !/^[a-zA-Z0-9]{8,128}$/.test(s)) return null;
  return s;
}

function assertAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Admin only");
  }
}

// ─── Rate limiting ────────────────────────────────────────────────────────────
async function rateLimit(uid, fnName, maxCalls, windowMs) {
  const db = admin.firestore();
  const ref = db.collection("rateLimits").doc(uid)
                .collection("functions").doc(fnName);
  const now = Date.now();
  const windowStart = new Date(now - windowMs).toISOString();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : { calls: [] };
    const recent = (data.calls || []).filter((ts) => ts >= windowStart);
    if (recent.length >= maxCalls) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Rate limit exceeded. Try again in ${Math.ceil(windowMs / 60000)} minute(s).`
      );
    }
    recent.push(new Date(now).toISOString());
    tx.set(ref, { calls: recent }, { merge: true });
  });
}

// ─── In-app feed + push (FCM) ────────────────────────────────────────────────
// Every alert is persisted under users/{uid}/notifications for the Notification Center.
// meta: { category?: string, orderId?: string, promoCode?: string }
async function notifyUser(uid, title, body, meta = {}) {
  if (!uid) return;
  const db = admin.firestore();
  const category = sanitizeStr(meta.category, 24) || "order";
  const orderIdMeta = meta.orderId ? sanitizeOrderId(meta.orderId) : null;
  const promoCodeMeta = meta.promoCode ? sanitizeStr(meta.promoCode, 40) : null;

  const feedDoc = {
    title: sanitizeStr(title, 120) || "Notification",
    body: sanitizeStr(body, 500) || "",
    category,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (orderIdMeta) feedDoc.orderId = orderIdMeta;
  if (promoCodeMeta) feedDoc.promoCode = promoCodeMeta;

  try {
    await db.collection("users").doc(uid).collection("notifications").add(feedDoc);
  } catch (err) {
    console.warn("[notifyUser] Feed write failed:", err.message);
  }

  try {
    const userSnap = await db.collection("users").doc(uid).get();
    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return;
    const dataPayload = { category: String(category) };
    if (orderIdMeta) dataPayload.orderId = String(orderIdMeta);
    if (promoCodeMeta) dataPayload.promoCode = String(promoCodeMeta);
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: feedDoc.title, body: feedDoc.body },
      data: dataPayload,
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  } catch (err) {
    console.warn("[FCM] Failed:", err.message);
  }
}

/** @deprecated Use notifyUser — kept name for minimal diff at call sites */
async function sendOrderNotification(customerUID, title, body, orderId = null, category = "order") {
  await notifyUser(customerUID, title, body, { category, orderId: orderId || undefined });
}

function toAmountCents(priceValue) {
  const numeric = Number(priceValue);
  if (!Number.isFinite(numeric) || numeric <= 0) return null;
  return Math.max(50, Math.round(numeric * 100));
}

// ─────────────────────────────────────────────────────────────────────────────
// P0 — STRIPE WEBHOOK (server-authoritative payment confirmation)
// Register this URL in Stripe Dashboard → Developers → Webhooks:
//   https://<region>-swifterx-e7f15.cloudfunctions.net/stripeWebhook
// Events to enable: payment_intent.succeeded, payment_intent.payment_failed,
//                   charge.refunded, account.updated
// ─────────────────────────────────────────────────────────────────────────────
exports.stripeWebhook = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"] })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const sig     = req.headers["stripe-signature"];
    const secret  = process.env.STRIPE_WEBHOOK_SECRET;
    const stripe  = new Stripe(process.env.STRIPE_SECRET_KEY);

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, secret);
    } catch (err) {
      console.error("[Webhook] Signature verification failed:", err.message);
      return res.status(400).send("Webhook signature verification failed");
    }

    console.log("[Webhook] Event:", event.type, event.id);

    try {
      switch (event.type) {
        case "payment_intent.succeeded":
          await onPaymentIntentSucceeded(event.data.object, stripe);
          break;
        case "payment_intent.payment_failed":
          await onPaymentIntentFailed(event.data.object);
          break;
        case "charge.refunded":
          await onChargeRefunded(event.data.object);
          break;
        case "account.updated":
          await onConnectAccountUpdated(event.data.object);
          break;
        default:
          console.log("[Webhook] Unhandled event type:", event.type);
      }
    } catch (err) {
      console.error("[Webhook] Handler error:", err.message);
      // Return 200 to prevent Stripe retrying — log the error for investigation
      // Do not return internal error strings to Stripe — log server-side only
      return res.status(200).json({ received: true });
    }

    return res.status(200).json({ received: true });
  });

// payment_intent.succeeded → mark order paid + confirmed (server-authoritative)
async function onPaymentIntentSucceeded(paymentIntent, stripe) {
  const orderId = paymentIntent.metadata?.orderId;
  if (!orderId) return console.warn("[Webhook] No orderId in metadata for", paymentIntent.id);

  const db  = admin.firestore();
  const ref = db.collection("orders").doc(orderId);
  const snap = await ref.get();
  if (!snap.exists) return console.warn("[Webhook] Order not found:", orderId);

  const order = snap.data();
  // Idempotency: skip if already confirmed
  if (order.paymentStatus === "paid") {
    return console.log("[Webhook] Order already paid, skipping:", orderId);
  }

  await ref.update({ paymentStatus: "paid", status: "confirmed" });
  console.log("[Webhook] Order confirmed via webhook:", orderId);

  await sendOrderNotification(
    order.customerUID,
    "Booking Confirmed! 🎉",
    `Your booking with ${sanitizeStr(order.providerName, 120) || "your provider"} has been confirmed.`,
    orderId
  );

  // If the provider has a Stripe Connect account, trigger transfer now
  if (order.stripeConnectAccountId) {
    const providerAmountCents = Math.floor(
      toAmountCents(order.price) * (1 - PLATFORM_FEE_PERCENT)
    );
    try {
      await stripe.transfers.create({
        amount: providerAmountCents,
        currency: "usd",
        destination: order.stripeConnectAccountId,
        transfer_group: orderId,
        metadata: { orderId },
      });
      console.log("[Webhook] Transfer created for provider, amount:", providerAmountCents);
    } catch (err) {
      console.error("[Webhook] Transfer failed:", err.message);
    }
  }
}

// payment_intent.payment_failed → mark order failed
async function onPaymentIntentFailed(paymentIntent) {
  const orderId = paymentIntent.metadata?.orderId;
  if (!orderId) return;

  const ref = admin.firestore().collection("orders").doc(orderId);
  const snap = await ref.get();
  if (!snap.exists) return;

  if (snap.data().paymentStatus === "paid") return; // idempotency

  await ref.update({ paymentStatus: "failed", status: "cancelled" });
  const cust = snap.data().customerUID;
  if (cust) {
    await notifyUser(cust, "Payment Failed", "We couldn't charge your card for this booking. Please try again with a different payment method.", { category: "order", orderId });
  }
  console.log("[Webhook] Payment failed, order cancelled:", orderId);
}

// charge.refunded → mark order refunded
async function onChargeRefunded(charge) {
  const piId = charge.payment_intent;
  if (!piId) return;

  const db   = admin.firestore();
  const snap = await db.collection("orders")
    .where("stripePaymentIntentId", "==", piId)
    .limit(1)
    .get();

  if (snap.empty) return;

  const docRef = snap.docs[0].ref;
  const order  = snap.docs[0].data();
  if (order.paymentStatus === "refunded") return; // idempotency

  await docRef.update({ paymentStatus: "refunded", status: "cancelled" });
  const oid = snap.docs[0].id;
  const cust = order.customerUID;
  if (cust) {
    await notifyUser(cust, "Refund Processed", "A refund has been issued for your order. It may take 5–10 business days to appear on your statement.", { category: "order", orderId: oid });
  }
  console.log("[Webhook] Charge refunded, order updated:", oid);
}

// account.updated → record when provider finishes Stripe Connect onboarding
async function onConnectAccountUpdated(account) {
  if (!account.details_submitted) return;

  const db = admin.firestore();
  const snap = await db.collection("providerProfiles")
    .where("stripeConnectAccountId", "==", account.id)
    .limit(1)
    .get();

  if (snap.empty) return;

  await snap.docs[0].ref.update({ connectOnboardingComplete: true });
  console.log("[Webhook] Connect onboarding complete for account:", account.id);
}

// ─────────────────────────────────────────────────────────────────────────────
// P1 — STRIPE CONNECT: Provider account creation & onboarding
// ─────────────────────────────────────────────────────────────────────────────

// createConnectAccount — called once when provider taps "Set up payouts"
// Creates a Stripe Express account, stores ID on providerProfile
exports.createConnectAccount = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "createConnectAccount", 3, 60 * 60 * 1000); // 3/hr

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const db     = admin.firestore();
    const uid    = context.auth.uid;

    // Retrieve existing account if already created
    const profileRef  = db.collection("providerProfiles").doc(uid);
    const profileSnap = await profileRef.get();
    const existing    = profileSnap.data()?.stripeConnectAccountId;

    if (existing) {
      return { accountId: existing };
    }

    // Fetch user email for pre-fill
    const userRecord = await admin.auth().getUser(uid);
    const account = await stripe.accounts.create({
      type: "express",
      country: "US",
      email: userRecord.email,
      capabilities: { card_payments: { requested: true }, transfers: { requested: true } },
      metadata: { firebaseUID: uid },
    });

    await profileRef.update({ stripeConnectAccountId: account.id, connectOnboardingComplete: false });
    console.log("[Connect] Created account", account.id, "for provider", uid);
    return { accountId: account.id };
  });

// getConnectOnboardingUrl — returns a single-use Stripe-hosted onboarding link
exports.getConnectOnboardingUrl = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "getConnectOnboardingUrl", 5, 60 * 60 * 1000);

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const db     = admin.firestore();
    const uid    = context.auth.uid;

    const profileSnap = await db.collection("providerProfiles").doc(uid).get();
    const accountId   = profileSnap.data()?.stripeConnectAccountId;
    if (!accountId) throw new functions.https.HttpsError("failed-precondition", "No Connect account. Call createConnectAccount first.");

    const link = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: "https://swifterx.app/provider/payouts/refresh",
      return_url:  "https://swifterx.app/provider/payouts/return",
      type: "account_onboarding",
    });

    return { url: link.url };
  });

// getConnectDashboardUrl — returns a Stripe Express dashboard login link
exports.getConnectDashboardUrl = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "getConnectDashboardUrl", 10, 60 * 60 * 1000);

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const db     = admin.firestore();
    const uid    = context.auth.uid;

    const profileSnap = await db.collection("providerProfiles").doc(uid).get();
    const accountId   = profileSnap.data()?.stripeConnectAccountId;
    if (!accountId) throw new functions.https.HttpsError("failed-precondition", "No Connect account.");

    const loginLink = await stripe.accounts.createLoginLink(accountId);
    return { url: loginLink.url };
  });

// getProviderEarnings — summarise completed jobs and total earnings for the provider
exports.getProviderEarnings = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");

  const db  = admin.firestore();
  const uid = context.auth.uid;

  const snap = await db.collection("orders")
    .where("providerUID", "==", uid)
    .where("status", "==", "completed")
    .where("paymentStatus", "==", "paid")
    .get();

  const gross = snap.docs.reduce((sum, doc) => sum + (doc.data().price || 0), 0);
  const platformFee = gross * PLATFORM_FEE_PERCENT;
  const net = gross - platformFee;

  return {
    completedJobs: snap.docs.length,
    grossEarnings: Math.round(gross * 100) / 100,
    platformFee:   Math.round(platformFee * 100) / 100,
    netEarnings:   Math.round(net * 100) / 100,
    feePercent:    PLATFORM_FEE_PERCENT * 100,
  };
});

/**
 * P2 — Operator approval API. Caller must have Auth custom claim `{ admin: true }`
 * (set once via Admin SDK: admin.auth().setCustomUserClaims(uid, { admin: true })).
 *
 * data: { providerUid: string, approved: boolean, rejectionReason?: string }
 */
exports.adminSetProviderApproval = functions.https.onCall(async (data, context) => {
  assertAdmin(context);
  await rateLimit(context.auth.uid, "adminSetProviderApproval", 60, 60 * 1000);

  const uid = sanitizeFirebaseUid(data.providerUid || data.uid);
  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "providerUid is required");
  }
  const approved = data.approved === true;
  const rejectionReason = approved ? null : sanitizeStr(data.rejectionReason, 500);

  const ref = admin.firestore().collection("providerProfiles").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "providerProfiles doc not found");
  }

  const patch = { approved };
  if (approved) {
    patch.approvedAt = admin.firestore.FieldValue.serverTimestamp();
    patch.rejectionReason = admin.firestore.FieldValue.delete();
  } else {
    patch.approvedAt = admin.firestore.FieldValue.delete();
    patch.rejectionReason = rejectionReason
      ? rejectionReason
      : admin.firestore.FieldValue.delete();
  }
  await ref.update(patch);
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT FUNCTIONS (updated to store Connect account on order)
// ─────────────────────────────────────────────────────────────────────────────

exports.createStripePaymentIntent = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "createStripePaymentIntent", 5, 10 * 60 * 1000);

    const orderId = sanitizeOrderId(data.orderId);
    if (!orderId) throw new functions.https.HttpsError("invalid-argument", "orderId is missing or invalid");

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const db     = admin.firestore();
    const ref    = db.collection("orders").doc(orderId);
    const snap   = await ref.get();

    if (!snap.exists)                   throw new functions.https.HttpsError("not-found",          "Order not found");
    const order = snap.data();
    if (order.customerUID !== context.auth.uid) throw new functions.https.HttpsError("permission-denied", "Not your order");
    if (order.paymentStatus !== "unpaid")       throw new functions.https.HttpsError("failed-precondition", "Order is not awaiting payment");

    const amountCents = toAmountCents(order.price);
    if (!amountCents) throw new functions.https.HttpsError("failed-precondition", "Order price invalid");

    // Reuse existing PI (retry safety)
    if (order.stripePaymentIntentId) {
      const existing = await stripe.paymentIntents.retrieve(order.stripePaymentIntentId);
      if (["requires_payment_method","requires_confirmation","requires_action","processing","succeeded"]
            .includes(existing.status)) {
        return { clientSecret: existing.client_secret };
      }
    }

    // Lookup provider's Connect account (if onboarded)
    const providerProfileSnap = await db.collection("providerProfiles").doc(order.providerID).get();
    const connectAccountId    = providerProfileSnap.data()?.stripeConnectAccountId;
    const connectComplete     = providerProfileSnap.data()?.connectOnboardingComplete === true;

    const intentParams = {
      amount:   amountCents,
      currency: "usd",
      metadata: { orderId, firebaseUID: context.auth.uid },
      automatic_payment_methods: { enabled: true },
    };

    // Route payment through provider's Connect account if available
    if (connectAccountId && connectComplete) {
      intentParams.application_fee_amount = Math.floor(amountCents * PLATFORM_FEE_PERCENT);
      intentParams.transfer_data = { destination: connectAccountId };
    }

    const intent = await stripe.paymentIntents.create(intentParams);

    // Store Connect account ID on order so webhook can transfer funds later
    const orderUpdate = {
      stripePaymentIntentId: intent.id,
      paymentStatus: "processing",
    };
    if (connectAccountId) orderUpdate.stripeConnectAccountId = connectAccountId;

    await ref.update(orderUpdate);
    return { clientSecret: intent.client_secret };
  });

exports.refundOrder = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "refundOrder", 3, 15 * 60 * 1000);

    const orderId = sanitizeOrderId(data.orderId);
    if (!orderId) throw new functions.https.HttpsError("invalid-argument", "orderId is missing or invalid");

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const ref    = admin.firestore().collection("orders").doc(orderId);
    const snap   = await ref.get();
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Order not found");

    const order = snap.data();
    const uid   = context.auth.uid;
    if (order.customerUID !== uid && order.providerUID !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your order");
    }

    if (order.stripePaymentIntentId && order.paymentStatus === "paid") {
      try {
        await stripe.refunds.create({ payment_intent: order.stripePaymentIntentId });
        await ref.update({ status: "cancelled", paymentStatus: "refunded" });
      } catch (err) {
        console.error("[refundOrder] Stripe refund failed:", err.message);
        throw new functions.https.HttpsError("internal", "Refund could not be completed.");
      }
    } else {
      await ref.update({ status: "cancelled" });
    }
    return { ok: true };
  });

exports.confirmOrderPayment = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    await rateLimit(context.auth.uid, "confirmOrderPayment", 10, 5 * 60 * 1000);

    const orderId = sanitizeOrderId(data.orderId);
    if (!orderId) throw new functions.https.HttpsError("invalid-argument", "orderId is missing or invalid");

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const ref    = admin.firestore().collection("orders").doc(orderId);
    const snap   = await ref.get();
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Order not found");

    const order = snap.data();
    if (order.customerUID !== context.auth.uid) throw new functions.https.HttpsError("permission-denied", "Not your order");
    if (!order.stripePaymentIntentId)            throw new functions.https.HttpsError("failed-precondition", "No payment intent on order");

    // Webhook is the authoritative source — this is a client fallback only.
    // If webhook already fired, order is already paid; just return ok.
    if (order.paymentStatus === "paid") return { ok: true };

    const intent = await stripe.paymentIntents.retrieve(order.stripePaymentIntentId);
    if (intent.status !== "succeeded") return { ok: false, error: `Payment not complete (${intent.status})` };

    await ref.update({ paymentStatus: "paid", status: "confirmed" });
    await sendOrderNotification(
      order.customerUID,
      "Booking Confirmed! 🎉",
      `Your booking with ${sanitizeStr(order.providerName, 120) || "your provider"} has been confirmed.`,
      orderId
    );
    return { ok: true };
  });

// ─────────────────────────────────────────────────────────────────────────────
// DISPUTE TRIGGER — fires when a customer creates a new dispute document
// Auto-approves clear no-shows; everything else goes to manual review.
// ─────────────────────────────────────────────────────────────────────────────
exports.onDisputeCreated = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .firestore.document("disputes/{disputeID}")
  .onCreate(async (snap, context) => {
    const dispute    = snap.data();
    const disputeRef = snap.ref;
    const db         = admin.firestore();
    const stripe     = new Stripe(process.env.STRIPE_SECRET_KEY);

    const orderId        = dispute.orderID;
    const customerUID    = dispute.customerUID;
    const reason         = dispute.reason;
    const refundRequested = dispute.refundRequested === true;

    // Guard: verify the order belongs to this customer
    const orderRef  = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists || orderSnap.data().customerUID !== customerUID) {
      await disputeRef.update({
        status:     "rejected",
        resolution: "Order not found or does not belong to this account.",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    const order = orderSnap.data();

    // ── Auto-approve no-shows ──────────────────────────────────────────────
    // Criteria: reason is no_show AND provider never started the job
    // (status was still "pending" or "confirmed" — never moved to inProgress).
    const isAutoApproveNoShow =
      reason === "no_show" &&
      (order.status === "confirmed" || order.status === "pending") &&
      refundRequested &&
      order.paymentStatus === "paid" &&
      order.stripePaymentIntentId;

    if (isAutoApproveNoShow) {
      try {
        await stripe.refunds.create({ payment_intent: order.stripePaymentIntentId });
        await orderRef.update({ paymentStatus: "refunded", status: "cancelled" });
        await disputeRef.update({
          status:     "refunded",
          resolution: "Provider did not start the job. Your payment has been automatically refunded.",
          resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await notifyUser(
          customerUID,
          "Refund Approved ✅",
          "Your dispute was approved. A full refund has been issued to your original payment method.",
          { category: "dispute", orderId }
        );
        console.log("[Dispute] Auto-approved no-show refund for order:", orderId);
        return null;
      } catch (err) {
        console.error("[Dispute] Auto-refund failed:", err.message);
        // Fall through to manual review if Stripe refund fails
      }
    }

    // ── Mark for manual review ─────────────────────────────────────────────
    await disputeRef.update({ status: "reviewing" });

    // Notify customer that we received their dispute
    await notifyUser(
      customerUID,
      "Dispute Received 📋",
      "We've received your dispute and will review it within 1–3 business days.",
      { category: "dispute", orderId }
    );

    // ── Notify admin via Firestore (admin reads from adminAlerts collection) ─
    // Operators can watch this collection in Firebase Console or via a webhook.
    const providerName = sanitizeStr(dispute.providerName, 120) || "Unknown provider";
    const reasonLabel  = reason.replace(/_/g, " ");
    await db.collection("adminAlerts").add({
      type:          "dispute",
      disputeID:     context.params.disputeID,
      orderID:       orderId,
      customerUID:   customerUID,
      providerID:    order.providerID,
      providerName,
      orderAmount:   order.price,
      reason,
      reasonLabel,
      refundRequested,
      createdAt:     admin.firestore.FieldValue.serverTimestamp(),
      resolved:      false,
      summary:       `${reasonLabel} — $${(order.price || 0).toFixed(2)} — ${providerName}`,
    });

    console.log("[Dispute] Queued for manual review:", context.params.disputeID);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// DISPUTE STATUS UPDATE — notify customer when admin resolves a dispute
// ─────────────────────────────────────────────────────────────────────────────
exports.onDisputeUpdated = functions.firestore
  .document("disputes/{disputeID}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Only fire when status changes to a closed state
    if (before.status === after.status) return null;
    if (!["resolved", "refunded", "rejected"].includes(after.status)) return null;

    const customerUID = after.customerUID;
    const resolution  = sanitizeStr(after.resolution, 300) || "No additional details.";

    let title, body;
    if (after.status === "refunded") {
      title = "Refund Approved ✅";
      body  = `Your dispute has been approved. Refund in progress. ${resolution}`;
    } else if (after.status === "resolved") {
      title = "Dispute Resolved";
      body  = `Your dispute has been closed. ${resolution}`;
    } else {
      title = "Dispute Closed";
      body  = `Your dispute was not upheld. ${resolution}`;
    }

    const oid = sanitizeOrderId(after.orderID || after.orderId);
    await notifyUser(customerUID, title, body, { category: "dispute", orderId: oid || undefined });
    return null;
  });

// ─── Chat → in-app notification for the other party ───────────────────────────
exports.onChatMessageCreated = functions.firestore
  .document("orders/{orderId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    const orderId = context.params.orderId;
    const orderSnap = await admin.firestore().collection("orders").doc(orderId).get();
    if (!orderSnap.exists) return null;

    const order = orderSnap.data();
    const isProviderSender = msg.isProvider === true;
    const recipientUID = isProviderSender ? order.customerUID : order.providerUID;
    if (!recipientUID) return null;

    const senderName = sanitizeStr(msg.senderName, 60) || (isProviderSender ? "Provider" : "Customer");
    const preview = sanitizeStr(msg.text, 120) || "New message";
    const title = `${senderName}`;
    const body = preview.length > 80 ? `${preview.slice(0, 77)}…` : preview;

    await notifyUser(recipientUID, title, body, { category: "chat", orderId });
    return null;
  });

// ─── Firestore triggers ───────────────────────────────────────────────────────

// P1 — Sync providerProfiles → public providers/{uid} + listingApproved for customer browse / rules
exports.onProviderProfileWrite = functions.firestore
  .document("providerProfiles/{uid}")
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    const db = admin.firestore();
    const ref = db.collection("providers").doc(uid);

    if (!change.after.exists) {
      await ref.set({ listingApproved: false }, { merge: true });
      return null;
    }

    const after = change.after.data();
    const approved = after.approved !== false;
    const listingApproved = approved === true;

    const categories = Array.isArray(after.serviceCategories) ? after.serviceCategories : [];
    const primaryCategory = sanitizeStr(categories[0], 80) || "Services";

    const payload = {
      id: uid,
      name: sanitizeStr(after.name, 120) || "Provider",
      category: primaryCategory,
      description: sanitizeStr(after.bio, 2000) || "",
      rating: typeof after.rating === "number" ? after.rating : 0,
      reviewCount: typeof after.reviewCount === "number" ? after.reviewCount : 0,
      imageURL: sanitizeStr(after.photoURL, 2000) || "",
      imageName: "",
      distanceMi: typeof after.distanceMi === "number" ? after.distanceMi : 0,
      listingApproved,
    };

    if (typeof after.providerLat === "number") payload.providerLat = after.providerLat;
    if (typeof after.providerLng === "number") payload.providerLng = after.providerLng;

    await ref.set(payload, { merge: true });
    return null;
  });

// P2 — Push + in-app feed when approval / rejection changes
exports.onProviderProfileApprovalNotify = functions.firestore
  .document("providerProfiles/{uid}")
  .onUpdate(async (change, context) => {
    const uid = context.params.uid;
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if (before.approved === false && after.approved === true) {
      await notifyUser(
        uid,
        "You are approved",
        "You can accept paid jobs and appear in customer search on SwifterX.",
        { category: "system" }
      );
    }

    const reason = sanitizeStr(after.rejectionReason, 500) || "";
    const prevReason = sanitizeStr(before.rejectionReason, 500) || "";
    if (after.approved === false && reason && (before.approved !== false || reason !== prevReason)) {
      const body = reason.length > 400 ? `${reason.slice(0, 397)}…` : reason;
      await notifyUser(
        uid,
        "Profile not approved",
        `SwifterX could not approve your provider profile yet. ${body}`,
        { category: "system" }
      );
    }
    return null;
  });

exports.onReviewCreated = functions.firestore
  .document("providers/{providerID}/reviews/{reviewID}")
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const rating = parseInt(review.rating, 10);
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) return null;

    const providerRef = admin.firestore().collection("providers").doc(context.params.providerID);
    try {
      await admin.firestore().runTransaction(async (tx) => {
        const doc = await tx.get(providerRef);
        if (!doc.exists) return;
        const d = doc.data();
        const newCount  = (d.reviewCount || 0) + 1;
        const newRating = (((d.rating || 0) * (d.reviewCount || 0)) + rating) / newCount;
        tx.update(providerRef, { reviewCount: newCount, rating: Math.round(newRating * 10) / 10 });
      });
    } catch (err) {
      console.error("[onReviewCreated]", err.message);
    }
    return null;
  });

exports.onOrderStatusChange = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    const orderId = context.params.orderId;

    const statusChanged   = before.status    !== after.status;
    const providerClaimed = before.providerUID === "" && after.providerUID !== "";
    if (!statusChanged && !providerClaimed) return null;

    const customerUID  = after.customerUID;
    const providerName = sanitizeStr(after.providerName, 120) || "Your provider";

    if (providerClaimed && after.status === "confirmed") {
      await sendOrderNotification(customerUID, "Provider Assigned! 🚗", `${providerName} has accepted your booking.`, orderId);
      const pid = after.providerUID;
      if (pid) {
        await notifyUser(pid, "New Job Assigned 📋", "You've accepted a booking. Open the app to view job details.", { category: "order", orderId });
      }
    } else if (after.status === "inProgress" && before.status !== "inProgress") {
      await sendOrderNotification(customerUID, "Service Started 🔧", `${providerName} has started your service.`, orderId);
    } else if (after.status === "completed" && before.status !== "completed") {
      await sendOrderNotification(customerUID, "Service Complete ✅", `Your service with ${providerName} is complete. Don't forget to leave a review!`, orderId);
    } else if (after.status === "cancelled" && before.status !== "cancelled") {
      await sendOrderNotification(customerUID, "Order Cancelled", `Your booking with ${providerName} was cancelled.`, orderId);
    }
    return null;
  });
