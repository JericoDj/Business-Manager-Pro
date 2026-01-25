const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const { Polar } = require("@polar-sh/sdk");

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());
app.use(cors({ origin: true }));


const POLAR_ACCESS_TOKEN = defineSecret("POLAR_ACCESS_TOKEN");

/* ---------------- REDIRECT (Optional) ---------------- */
// User is effectively using direct links, but keeping a simple GET redirect 
// if they want to hide the ugly Polar URL behind a nice domain.
/* ---------------- CREATE CHECKOUT (API) ---------------- */
app.post("/create-checkout", async (req, res) => {
  try {
    /* -------------------------------------------------
       AUTH (RECOMMENDED)
    ------------------------------------------------- */
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decoded = await admin.auth().verifyIdToken(idToken);

    /* -------------------------------------------------
       INPUT
    ------------------------------------------------- */
    const { planId, businessId, transactionId, customerEmail } = req.body;

    if (!planId || !businessId || !transactionId) {
      return res.status(400).json({ error: "Missing parameters" });
    }

    /* -------------------------------------------------
       VERIFY TRANSACTION
    ------------------------------------------------- */
    const txRef = db.collection("transactions").doc(transactionId);
    const txSnap = await txRef.get();

    if (!txSnap.exists) {
      return res.status(404).json({ error: "Transaction not found" });
    }

    if (txSnap.data().status !== "pending") {
      return res.status(400).json({ error: "Transaction not pending" });
    }

    /* -------------------------------------------------
       PLAN → POLAR PRODUCT MAPPING
    ------------------------------------------------- */
    const PLAN_TO_PRODUCT = {
      plus: "46b04f9e-0d98-45b2-a7eb-eb1a3521ba01",
      // add more here
    };

    const productId = PLAN_TO_PRODUCT[planId.toLowerCase()];
    if (!productId) {
      return res.status(400).json({ error: "Invalid planId" });
    }

    /* -------------------------------------------------
       CREATE CHECKOUT
    ------------------------------------------------- */
    const polar = new Polar({
      accessToken: POLAR_ACCESS_TOKEN.value(),
    });

    const checkout = await polar.checkouts.create({
      product_id: productId,
      success_url: "https://api-75l7ugvwya-uc.a.run.app/payment-success",
      metadata: {
        transactionId,
        businessId,
        planId,
        firebaseUid: decoded.uid,
      },
      customer_email: customerEmail ?? decoded.email ?? undefined,
    });

    /* -------------------------------------------------
       STORE CHECKOUT EARLY (IMPORTANT)
    ------------------------------------------------- */
    await txRef.update({
      checkoutId: checkout.id,
      checkoutUrl: checkout.url,
      checkoutCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({
      checkoutUrl: checkout.url,
    });
  } catch (err) {
    console.error("❌ Create checkout error", err);
    return res.status(500).json({ error: "Failed to create checkout" });
  }
});





/* ---------------- PAYMENT VERIFICATION (GET) ---------------- */
app.get("/payment-success", async (req, res) => {
  const { checkout_id } = req.query;

  console.log("✅ Payment success redirect");
  console.log("checkout_id:", checkout_id);

  // Optional audit logging ONLY
  if (checkout_id) {
    await db.collection("checkout_redirects").add({
      checkoutId: checkout_id,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return res
    .status(200)
    .set("Content-Type", "text/html")
    .send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Payment Successful</title>
  <style>
    body {
      margin: 0;
      font-family: system-ui, -apple-system, BlinkMacSystemFont;
      background: #f6f7f9;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
    }
    .card {
      background: #fff;
      padding: 32px;
      border-radius: 16px;
      max-width: 420px;
      width: 90%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.08);
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>✅ Payment Successful</h1>
    <p>Your subscription is being activated.</p>
    <p>You may now return to the app.</p>
  </div>
</body>
</html>
`);
});



/* ---------------- WEBHOOK ---------------- */
app.post("/webhook", async (req, res) => {
  try {
    console.log("🔔 POLAR WEBHOOK RECEIVED");

    const event = req.body;

    if (!event || !event.type) {
      console.warn("⚠️ Invalid webhook payload");
      return res.status(400).send("Invalid payload");
    }

    console.log("📌 Event type:", event.type);

    const allowedEvents = [
      "checkout.created",
      "checkout.updated",
      "subscription.created",
      "subscription.updated",
      "subscription.active",
    ];

    if (!allowedEvents.includes(event.type)) {
      return res.status(200).send("Ignored");
    }

    const payload = event.data || {};

    /* =================================================
       SAVE EVENT (CHECKOUT + SUBSCRIPTION ONLY)
       ================================================= */
    await db
      .collection("webhooks")
      .doc("polar")
      .collection("events")
      .add({
        type: event.type,
        referenceId: payload.reference_id || payload.metadata?.reference_id || null,
        checkoutId: payload.checkout_id ?? payload.id ?? null,
        subscriptionId: payload.id ?? null,
        customerEmail:
          payload.customer?.email ||
          payload.customer_email ||
          null,
        payload,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    /* =================================================
       CHECKOUT EVENTS → BIND CHECKOUT TO TRANSACTION
       ================================================= */
    if (
      event.type === "checkout.created" ||
      event.type === "checkout.updated"
    ) {
      const checkout = payload;

      const transactionId = checkout.reference_id || checkout.metadata?.reference_id; // ✅ FIX
      const checkoutId = checkout.id;

      if (!transactionId) {
        console.warn("⚠️ Checkout missing reference_id");
        return res.status(200).send("No reference_id");
      }

      const txRef = db.collection("transactions").doc(transactionId);
      const txSnap = await txRef.get();

      if (!txSnap.exists) {
        console.warn("❌ Transaction not found:", transactionId);
        return res.status(200).send("Transaction not found");
      }

      await txRef.update({
        checkoutId,
        checkoutStatus: checkout.status,
        checkoutUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("🔗 Checkout linked via reference_id:", {
        transactionId,
        checkoutId,
      });

      return res.status(200).send("Checkout handled");
    }

    /* =================================================
       SUBSCRIPTION EVENTS → COMPLETE TRANSACTION
       ================================================= */
    const sub = payload;

    const transactionId = sub.reference_id || sub.metadata?.reference_id; // ✅ FIX

    if (!transactionId) {
      console.warn("❌ Subscription missing reference_id");
      return res.status(200).send("No reference_id");
    }

    const txRef = db.collection("transactions").doc(transactionId);
    const txSnap = await txRef.get();

    if (!txSnap.exists) {
      console.warn("❌ Transaction not found:", transactionId);
      return res.status(200).send("Transaction not found");
    }

    const txData = txSnap.data();

    if (txData.status === "completed") {
      console.log("ℹ️ Transaction already completed");
      return res.status(200).send("Already processed");
    }

    if (sub.status !== "active" && sub.status !== "trialing") {
      console.log("⏳ Subscription not active:", sub.status);
      return res.status(200).send("Not active");
    }

    await txRef.update({
      status: "completed",
      polarSubscriptionId: sub.id,
      productId: sub.product_id,
      customerEmail:
        sub.customer?.email ||
        sub.customer_email ||
        null,
      checkoutId: sub.checkout_id ?? null,
      subscriptionStatus: sub.status,
      currentPeriodStart: sub.current_period_start ?? null,
      currentPeriodEnd: sub.current_period_end ?? null,
      verifiedVia: "polar_webhook",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Transaction completed via reference_id:", {
      transactionId,
      subscriptionId: sub.id,
    });

    return res.status(200).send("OK");
  } catch (err) {
    console.error("❌ Webhook error", err);
    return res.status(500).send("Webhook failed");
  }
});








/* ---------------- FIRESTORE UPDATE ---------------- */

async function handleSubscriptionUpdate(subscription) {
  // Polar usually passes custom query params from checkout link into metadata
  // IF configured. However, they definitely pass 'external_reference' if provided.
  // We check both locations.
  const metadata = subscription.metadata || {};
  const businessId = metadata.businessId || metadata.business_id;
  // 'transactionId' might come from metadata OR from external_reference (if mapped by Polar)
  const transactionId = metadata.transactionId || metadata.external_reference;

  console.log(`Processing ${subscription.status} for Business: ${businessId}, Tx: ${transactionId}`);

  // 1. Update Transaction (if exists)
  if (transactionId) {
    const transactionRef = db.collection('transactions').doc(transactionId);
    try {
      await transactionRef.update({
        status: subscription.status === 'active' ? 'completed' : subscription.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        polarSubscriptionId: subscription.id,
        polarProductId: subscription.product_id
      });
      console.log(`Transaction ${transactionId} updated.`);
    } catch (e) {
      console.log(`Transaction ${transactionId} update skipped (not found or error): ${e.message}`);
    }
  }

  // 2. Update Business Document
  if (businessId) {
    const snap = await db
      .collection("businesses")
      .where("companyCode", "==", businessId) // Assuming companyCode IS the businessId string
      .limit(1)
      .get();

    if (!snap.empty) {
      await snap.docs[0].ref.update({
        subscription: {
          status: subscription.status,
          polarSubscriptionId: subscription.id,
          productId: subscription.product_id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      console.log(`Business ${businessId} updated.`);
    } else {
      console.warn(`Business ${businessId} not found.`);
    }
  }
}

/* ---------------- EXPORT ---------------- */

exports.api = onRequest(
  {
    region: "us-central1",
    cors: true,
    invoker: "public",
    secrets: [POLAR_ACCESS_TOKEN],
    // secrets: [POLAR_ACCESS_TOKEN], // Not needed if we don't call API
  },
  app
);
