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




/* ---------------- PAYMENT STATUS PAGE (GET) ---------------- */
app.get("/payment-success", async (req, res) => {
  const { checkout_id } = req.query;

  console.log("✅ Payment success redirect");
  console.log("checkout_id:", checkout_id);

  let transactionId = null;

  if (checkout_id) {
    // Find transaction by checkoutId
    const snap = await db
      .collection("transactions")
      .where("checkoutId", "==", checkout_id)
      .limit(1)
      .get();

    if (!snap.empty) {
      transactionId = snap.docs[0].id;
    }
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
  <title>Payment Processing</title>
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
    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #ddd;
      border-top-color: #4f46e5;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 24px auto;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    .success {
      color: #16a34a;
      font-weight: 600;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1 id="title" class="success">✅ Payment Successful</h1>
    <div style="font-size: 64px; margin: 20px;">🎉</div>
    <p id="message">Thank you! Your subscription has been processed.</p>
    <a href="#" onclick="window.close()" style="display:inline-block; margin-top:20px; text-decoration:none; color: #4f46e5; font-weight:bold;">Close Window</a>
  </div>

<script>
  const transactionId = ${transactionId ? `"${transactionId}"` : "null"};

  // Optional: Still poll to ensure DB sync, but UI shows success immediately
  async function checkStatus() {
    if (!transactionId) return;
    try {
      await fetch("/transaction-status?tx=" + transactionId);
      // We don't really need to update UI since we already show success
    } catch (e) {
      console.error("Status check failed", e);
    }
  }
  
  // Trigger one check just to warm up/verify
  checkStatus();
</script>
</body>
</html>
`);
});


/* ---------------- TRANSACTION STATUS (GET) ---------------- */
app.get("/transaction-status", async (req, res) => {
  const { tx } = req.query;

  if (!tx) {
    return res.status(400).json({ error: "Missing transaction id" });
  }

  const snap = await db.collection("transactions").doc(tx).get();

  if (!snap.exists) {
    return res.status(404).json({ error: "Transaction not found" });
  }

  return res.json({
    status: snap.data().status,
  });
});


/* ---------------- WEBHOOK ---------------- */
app.post("/webhook", async (req, res) => {
  try {
    console.log("🔔 POLAR WEBHOOK RECEIVED");

    const event = req.body;

    if (!event || !event.type || !event.data) {
      console.warn("⚠️ Invalid webhook payload");
      return res.status(400).send("Invalid payload");
    }

    /* ============================
       RAW EVENT LOGGING (IMPORTANT)
       ============================ */
    console.log("📌 Event type:", event.type);
    console.log(
      "📦 Full event body:",
      JSON.stringify(event, null, 2)
    );

    const payload = event.data;

    console.log(
      "📦 Event data:",
      JSON.stringify(payload, null, 2)
    );

    console.log(
      "🧩 Metadata:",
      JSON.stringify(payload.metadata ?? {}, null, 2)
    );

    /* ============================
       EXTRACT reference_id (Checkout Links)
       ============================ */
    const transactionId =
      payload.metadata?.reference_id ??
      payload.metadata?.referenceId ??
      null;

    console.log("🔑 Extracted transactionId:", transactionId);

    if (!transactionId) {
      console.warn("❌ Missing metadata.reference_id");
      return res.status(200).send("No reference_id");
    }

    /* ============================
       HANDLE ORDER EVENTS (SOURCE OF TRUTH)
       ============================ */
    if (event.type === "order.paid") {
      const txRef = db.collection("transactions").doc(transactionId);
      const txSnap = await txRef.get();

      if (!txSnap.exists) {
        console.warn("❌ Transaction not found:", transactionId);
        return res.status(200).send("Transaction not found");
      }

      await txRef.update({
        status: "completed",
        orderId: payload.id,
        verifiedVia: "polar_order",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Transaction completed:", transactionId);

      // --- NEW: Update Business Subscription ---
      try {
        const txData = txSnap.data();
        const businessId = txData.businessId;
        const planId = txData.planId;

        if (businessId && planId) {
          // Calculate End Date (1 month from now)
          const endDate = new Date();
          endDate.setMonth(endDate.getMonth() + 1);

          // Find business by ID (or companyCode if used interchangeably)
          // Assumption: businessId stored in transaction IS the document ID for businesses. 
          // If businessId refers to 'companyCode', we need a query. 
          // Based on user prompt "transaction businessId same with company code", 
          // and existing code "db.collection('businesses').doc(businessId)", 
          // we will try ID first, or query if needed. 
          // Let's stick to the prompt's implied logic: businessId matches companyCode.

          let businessRef = db.collection("businesses").doc(businessId);
          let businessSnap = await businessRef.get();

          if (!businessSnap.exists) {
            // Try querying by companyCode
            const qSnap = await db.collection("businesses").where("companyCode", "==", businessId).limit(1).get();
            if (!qSnap.empty) {
              businessRef = qSnap.docs[0].ref;
            } else {
              console.error(`Business not found for ID/Code: ${businessId}`);
              return res.status(200).send("OK - Business not found");
            }
          }

          await businessRef.update({
            "subscription.plan": planId,
            "subscription.status": "active",
            "subscription.startDate": admin.firestore.FieldValue.serverTimestamp(),
            "subscription.endDate": admin.firestore.Timestamp.fromDate(endDate),
            "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
            "subscription.transactionId": transactionId
          });
          console.log(`✅ Business ${businessId} subscription updated to ${planId}`);
        }
      } catch (bizError) {
        console.error("❌ Failed to update business subscription:", bizError);
      }
    }

    /* ============================
       IGNORE EVERYTHING ELSE
       ============================ */
    console.log("ℹ️ Event ignored:", event.type);
    return res.status(200).send("Ignored");
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
