import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> startCheckout({
    required String planId,
    required String businessId,
    required String transactionId,
  }) async {
    final checkoutBaseUrl =
        "https://buy.polar.sh/polar_cl_S64js76VkogeB2yf77pcnCDFHRVVilimYNgxP4clSvx";

    final checkoutUrl = Uri.parse(checkoutBaseUrl).replace(
      queryParameters: {
        // These are NOT trusted for logic
        // but can be echoed in webhooks via metadata / checkout object
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
}
