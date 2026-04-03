/**
 * SwifterX — Stripe PaymentIntent + Firestore order updates
 * 1st Gen Cloud Functions with Secret Manager (firebase-functions v5+)
 *
 * Setup (one time):
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   (paste your sk_live_... key when prompted)
 *
 * Deploy:
 *   firebase deploy --project swifterx-e7f15 --only functions,firestore:rules
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Stripe = require("stripe");

if (!admin.apps.length) {
  admin.initializeApp();
}

// ─── Push notification helper ────────────────────────────────────────────────
async function sendOrderNotification(customerUID, title, body) {
  try {
    const userSnap = await admin.firestore().collection("users").doc(customerUID).get();
    const fcmToken = userSnap.data()?.fcmToken;
    if (!fcmToken) return;
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    });
  } catch (err) {
    console.warn("[FCM] Failed to send notification:", err.message);
  }
}

function toAmountCents(priceValue) {
  const numeric = Number(priceValue);
  if (!Number.isFinite(numeric) || numeric <= 0) return null;
  return Math.max(50, Math.round(numeric * 100));
}

// ─── createStripePaymentIntent ───────────────────────────────────────────────
exports.createStripePaymentIntent = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    }

    const orderId = data.orderId;
    if (!orderId || typeof orderId !== "string") {
      throw new functions.https.HttpsError("invalid-argument", "orderId required");
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const ref = admin.firestore().collection("orders").doc(orderId);
    const snap = await ref.get();

    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Order not found");
    }

    const order = snap.data();
    if (order.customerUID !== context.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your order");
    }
    if (order.paymentStatus !== "unpaid") {
      throw new functions.https.HttpsError("failed-precondition", "Order is not awaiting payment");
    }

    const amountCents = toAmountCents(order.price);
    if (!amountCents) {
      throw new functions.https.HttpsError("failed-precondition", "Order price is missing or invalid");
    }

    // Reuse existing PaymentIntent if already created (retry safety)
    if (typeof order.stripePaymentIntentId === "string" && order.stripePaymentIntentId.trim() !== "") {
      const existing = await stripe.paymentIntents.retrieve(order.stripePaymentIntentId);
      if (["requires_payment_method", "requires_confirmation", "requires_action", "processing", "succeeded"].includes(existing.status)) {
        return { clientSecret: existing.client_secret };
      }
    }

    const intent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: "usd",
      metadata: { orderId, firebaseUID: context.auth.uid },
      automatic_payment_methods: { enabled: true },
    });

    await ref.update({
      stripePaymentIntentId: intent.id,
      paymentStatus: "processing",
    });

    return { clientSecret: intent.client_secret };
  });

// ─── refundOrder (called when customer or provider cancels a paid order) ──────
exports.refundOrder = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    }

    const orderId = data.orderId;
    if (!orderId) throw new functions.https.HttpsError("invalid-argument", "orderId required");

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const ref = admin.firestore().collection("orders").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) throw new functions.https.HttpsError("not-found", "Order not found");

    const order = snap.data();
    const uid = context.auth.uid;
    if (order.customerUID !== uid && order.providerUID !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your order");
    }

    if (order.stripePaymentIntentId && order.paymentStatus === "paid") {
      try {
        await stripe.refunds.create({ payment_intent: order.stripePaymentIntentId });
        await ref.update({ status: "cancelled", paymentStatus: "refunded" });
      } catch (err) {
        console.error("[Stripe] Refund failed:", err.message);
        throw new functions.https.HttpsError("internal", `Refund failed: ${err.message}`);
      }
    } else {
      await ref.update({ status: "cancelled" });
    }

    return { ok: true };
  });

// ─── onReviewCreated — server-side aggregate rating so it can't be spoofed ───
exports.onReviewCreated = functions.firestore
  .document("providers/{providerID}/reviews/{reviewID}")
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const providerID = context.params.providerID;
    const providerRef = admin.firestore().collection("providers").doc(providerID);

    try {
      await admin.firestore().runTransaction(async (transaction) => {
        const providerDoc = await transaction.get(providerRef);
        if (!providerDoc.exists) return;

        const data = providerDoc.data();
        const currentCount  = data.reviewCount || 0;
        const currentRating = data.rating      || 0;
        const newCount  = currentCount + 1;
        const newRating = ((currentRating * currentCount) + review.rating) / newCount;

        transaction.update(providerRef, {
          reviewCount: newCount,
          rating: Math.round(newRating * 10) / 10,
        });
      });
    } catch (err) {
      console.error("[onReviewCreated] Failed to update aggregate:", err.message);
    }
    return null;
  });

// ─── onOrderStatusChange — notify customer when provider updates the job ──────
exports.onOrderStatusChange = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after  = change.after.data();

    const statusChanged    = before.status    !== after.status;
    const providerClaimed  = before.providerUID === "" && after.providerUID !== "";

    if (!statusChanged && !providerClaimed) return null;

    const customerUID  = after.customerUID;
    const providerName = after.providerName || "Your provider";

    if (providerClaimed && after.status === "confirmed") {
      await sendOrderNotification(customerUID,
        "Provider Assigned! 🚗",
        `${providerName} has accepted your booking and will be there soon.`);
    } else if (after.status === "inProgress" && before.status !== "inProgress") {
      await sendOrderNotification(customerUID,
        "Service Started 🔧",
        `${providerName} has started your service. Sit tight!`);
    } else if (after.status === "completed" && before.status !== "completed") {
      await sendOrderNotification(customerUID,
        "Service Complete ✅",
        `Your service with ${providerName} is complete. Don't forget to leave a review!`);
    } else if (after.status === "cancelled" && before.status !== "cancelled") {
      await sendOrderNotification(customerUID,
        "Order Cancelled",
        `Your booking with ${providerName} was cancelled.`);
    }

    return null;
  });

// ─── confirmOrderPayment ─────────────────────────────────────────────────────
exports.confirmOrderPayment = functions
  .runWith({ secrets: ["STRIPE_SECRET_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    }

    const orderId = data.orderId;
    if (!orderId || typeof orderId !== "string") {
      throw new functions.https.HttpsError("invalid-argument", "orderId required");
    }

    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const ref = admin.firestore().collection("orders").doc(orderId);
    const snap = await ref.get();

    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Order not found");
    }

    const order = snap.data();
    if (order.customerUID !== context.auth.uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your order");
    }

    const piId = order.stripePaymentIntentId;
    if (!piId) {
      throw new functions.https.HttpsError("failed-precondition", "No payment intent on order");
    }

    const intent = await stripe.paymentIntents.retrieve(piId);
    if (intent.status !== "succeeded") {
      return { ok: false, error: `Payment not complete (${intent.status})` };
    }

  await ref.update({
    paymentStatus: "paid",
    status: "confirmed",
  });

  // Notify customer that booking is confirmed
  await sendOrderNotification(
    order.customerUID,
    "Booking Confirmed! 🎉",
    `Your booking with ${order.providerName} has been confirmed.`
  );

  return { ok: true };
  });
