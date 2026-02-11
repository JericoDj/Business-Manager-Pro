const { onRequest } = require("firebase-functions/v2/https");
// firebase-functions/params no longer needed — POLAR_ACCESS_TOKEN loaded from .env
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const { Polar } = require("@polar-sh/sdk");

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());
app.use(cors({ origin: true }));


// POLAR_ACCESS_TOKEN is loaded from .env via process.env

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
      accessToken: process.env.POLAR_ACCESS_TOKEN,
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




/* ---------------- CANCEL SUBSCRIPTION (API) ---------------- */

app.post("/cancel-subscription", async (req, res) => {
  try {
    /* -------------------------------------------------
       AUTH
    ------------------------------------------------- */
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const idToken = authHeader.split("Bearer ")[1];
    await admin.auth().verifyIdToken(idToken);

    /* -------------------------------------------------
       INPUT
    ------------------------------------------------- */
    const { businessId } = req.body;

    if (!businessId) {
      return res.status(400).json({ error: "Missing businessId" });
    }

    /* -------------------------------------------------
       GET BUSINESS BY companyCode
    ------------------------------------------------- */
    const qSnap = await db
      .collection("businesses")
      .where("companyCode", "==", businessId)
      .limit(1)
      .get();

    if (qSnap.empty) {
      return res.status(404).json({ error: "Business not found" });
    }

    const businessRef = qSnap.docs[0].ref;
    const businessData = qSnap.docs[0].data();

    const subscription = businessData.subscription;

    if (!subscription) {
      return res
        .status(400)
        .json({ error: "No active subscription found to cancel" });
    }

    const polarSubscriptionId = subscription.polarSubscriptionId;

    /* -------------------------------------------------
       CANCEL IN POLAR
    ------------------------------------------------- */

    if (polarSubscriptionId) {
      try {
        console.log(`Revoking subscription via Polar API. ID: "${polarSubscriptionId}"`);
        const polarRes = await fetch(
          `https://api.polar.sh/v1/subscriptions/${polarSubscriptionId}`,
          {
            method: "DELETE",
            headers: {
              "Authorization": `Bearer ${process.env.POLAR_ACCESS_TOKEN}`,
              "Content-Type": "application/json",
            },
          }
        );

        if (polarRes.ok) {
          console.log(`✅ Subscription ${polarSubscriptionId} revoked successfully.`);
        } else if (polarRes.status === 403) {
          // Already canceled
          console.warn(`⚠️ Subscription ${polarSubscriptionId} is already canceled. Proceeding with Firestore update.`);
        } else if (polarRes.status === 404) {
          // Not found
          console.warn(`⚠️ Subscription ${polarSubscriptionId} not found in Polar. Proceeding with Firestore update.`);
        } else {
          const errBody = await polarRes.text();
          console.error(`Polar API error (${polarRes.status}):`, errBody);
          return res.status(500).json({ error: `Cancellation failed: ${errBody}` });
        }
      } catch (polarErr) {
        console.error("Polar cancellation fetch error:", polarErr);
        return res.status(500).json({ error: `Cancellation failed: ${polarErr.message}` });
      }
    } else {
      console.warn(
        "⚠️ No polarSubscriptionId found. Updating Firestore only (forcing cancel)."
      );
    }

    /* -------------------------------------------------
       UPDATE FIRESTORE
    ------------------------------------------------- */
    await businessRef.update({
      "subscription.status": "canceled",
      "subscription.plan": "free",
      "subscription.canceledAt": admin.firestore.FieldValue.serverTimestamp(),
      "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({ message: "Subscription canceled and plan reset to free." });

  } catch (err) {
    console.error("❌ Cancel subscription error:", err);
    return res
      .status(500)
      .json({ error: "Failed to cancel subscription" });
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
            "subscription.transactionId": transactionId,
            "subscription.polarSubscriptionId": payload.subscription_id,
            "subscription.customerId": payload.customer_id, // Store customer_id from order
          });
          console.log(`✅ Business ${businessId} subscription updated to ${planId}`);
        }
      } catch (bizError) {
        console.error("❌ Failed to update business subscription:", bizError);
      }
    }

    /* ============================
       HANDLE SUBSCRIPTION EVENTS
       ============================ */
    if (event.type.startsWith("subscription.")) {
      await handleSubscriptionUpdate(payload);
      return res.status(200).send("Subscription handled");
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
  // Checkout sessions use 'reference_id' in metadata.
  const transactionId = metadata.transactionId || metadata.external_reference || metadata.reference_id;

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
  // If businessId is missing from metadata, try to find it via Transaction
  let targetBusinessId = businessId;
  if (!targetBusinessId && transactionId) {
    try {
      const txDoc = await db.collection('transactions').doc(transactionId).get();
      if (txDoc.exists) {
        targetBusinessId = txDoc.data().businessId;
        console.log(`Found businessId ${targetBusinessId} from transaction ${transactionId}`);
      }
    } catch (e) {
      console.error("Error looking up transaction for businessId:", e);
    }
  }

  if (targetBusinessId) {
    const snap = await db
      .collection("businesses")
      .where("companyCode", "==", targetBusinessId) // Assuming companyCode IS the businessId string
      .limit(1)
      .get();

    if (!snap.empty) {
      // Use dot notation to avoid overwriting the entire 'subscription' map (which contains 'plan')
      await snap.docs[0].ref.update({
        "subscription.status": subscription.status,
        "subscription.polarSubscriptionId": subscription.id,
        "subscription.customerId": subscription.customer_id || subscription.user_id, // Store customer_id
        "subscription.productId": subscription.product_id,
        "subscription.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Business ${targetBusinessId} updated.`);
    } else {
      console.warn(`Business ${targetBusinessId} not found.`);
    }
  }
}

/* ---------------- EXPORT ---------------- */

exports.api = onRequest(
  {
    region: "us-central1",
    cors: true,
    invoker: "public",
    // POLAR_ACCESS_TOKEN is loaded from .env, no secrets needed
  },
  app
);
