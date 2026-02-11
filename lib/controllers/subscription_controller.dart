import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SubscriptionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Plan Definitions
  static const Map<String, Map<String, dynamic>> plans = {
    'free': {
      'name': 'Free',
      'maxAdmins': 1,
      'maxEmployees': 5,
      'price': 0,
      'priceId': '1c8032ef-7bc2-49d0-83e8-a70175435281',
    },
    'plus': {
      'name': 'Plus',
      'maxAdmins': 5,
      'maxEmployees': 15,
      'price': 29.99,
      'priceId': 'a80f9756-04f8-499b-8b87-b4e873a0e684',
    },
    'pro': {
      'name': 'Pro',
      'maxAdmins': 10,
      'maxEmployees': 30,
      'price': 79.99,
      'priceId': '46b04f9e-0d98-45b2-a7eb-eb1a3521ba01',
    },
    'enterprise': {
      'name': 'Enterprise',
      'maxAdmins': 20,
      'maxEmployees': 100,
      'price': 199.99,
      'priceId': '4804c622-daa3-448c-b1a4-eb33f24f4d99',
    },
  };

  // --- START CHECKOUT (Call Firebase Function) ---
  // Checkout links per plan
  static const Map<String, String> _checkoutLinks = {
    'plus':
        'https://buy.polar.sh/polar_cl_S64js76VkogeB2yf77pcnCDFHRVVilimYNgxP4clSvx',
    'pro':
        'https://buy.polar.sh/polar_cl_ADaLteWftQr33gZKAKdZfUhdhYZRacs2YTy3E11ktta',
    'enterprise':
        'https://buy.polar.sh/polar_cl_DOijGZxgU0U6cz7RZpXfIYmX9yauv3g2ICg4k3lWcGP',
  };

  // --- START CHECKOUT (Call Firebase Function) ---
  Future<void> startCheckout({
    required String planId,
    required String businessId,
    required String transactionId,
  }) async {
    final checkoutBaseUrl = _checkoutLinks[planId];
    if (checkoutBaseUrl == null) {
      throw Exception('No checkout link for plan: $planId');
    }

    final checkoutUrl = Uri.parse(checkoutBaseUrl).replace(
      queryParameters: {
        "reference_id": transactionId,
        "plan": planId,
        "business_id": businessId,
      },
    );

    await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
  }

  /// Fetch business subscription details
  Future<Map<String, dynamic>?> getSubscription(String businessId) async {
    try {
      final doc =
          await _firestore.collection('businesses').doc(businessId).get();
      if (doc.exists && doc.data() != null) {
        // Assuming subscription info is stored in the business document
        // If not present, default to 'free'
        return doc.data()?['subscription'] ??
            {'plan': 'free', 'status': 'active'};
      }
      return null;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  /// Update subscription (For admin usage or after payment)
  Future<void> updateSubscription(String businessId, String planId) async {
    try {
      await _firestore.collection('businesses').doc(businessId).set({
        'subscription': {
          'plan': planId,
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active', // You might want different statuses
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating subscription: $e');
      throw e;
    }
  }

  /// Cancel subscription via Cloud Function
  Future<void> cancelSubscription(String businessId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final token = await user.getIdToken();
      print("token: $token");
      print(businessId);
      final projectId = Firebase.app().options.projectId;
      final region = "us-central1"; // hardcoded in index.js

      final url = Uri.parse(
        "https://$region-$projectId.cloudfunctions.net/api/cancel-subscription",
      );

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"businessId": businessId}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to cancel subscription: ${response.body}");
      }
    } catch (e) {
      print("Error cancelling subscription: $e");
      rethrow;
    }
  }
}
