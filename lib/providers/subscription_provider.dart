import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionController _controller = SubscriptionController();
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _currentSubscription = {
    'plan': 'free',
    'status': 'active',
  };

  // Optimistic UI state
  String? _provisionalPlan;
  bool _isProcessingUpgrade = false;

  bool _isLoading = false;
  String? _error;

  SubscriptionProvider() {
    _loadFromStorage();
  }

  // Allow provisional plan to override actual plan temporarily
  Map<String, dynamic> get currentSubscription {
    if (_provisionalPlan != null) {
      return {
        ..._currentSubscription,
        'plan': _provisionalPlan,
        'status': 'processing',
      };
    }
    return _currentSubscription;
  }

  bool get isLoading => _isLoading;
  bool get isProcessingUpgrade => _isProcessingUpgrade;
  String? get error => _error;

  Map<String, dynamic> get currentPlanDetails =>
      SubscriptionController.plans[currentSubscription['plan']] ??
      SubscriptionController.plans['free']!;

  void _loadFromStorage() {
    final stored = _storage.read<Map<String, dynamic>>('company_subscription');
    if (stored != null) {
      _currentSubscription = stored;
    }
  }

  Map<String, dynamic> _sanitizeForStorage(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    for (var key in sanitized.keys) {
      final value = sanitized[key];
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      }
    }
    return sanitized;
  }

  /// Listen to real-time updates from Firestore
  void initSubscriptionStream(String companyCode) {
    _firestore
        .collection('businesses')
        .where('companyCode', isEqualTo: companyCode)
        .limit(1)
        .snapshots()
        .listen((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final doc = querySnapshot.docs.first;
            final data = doc.data();

            if (data.containsKey('subscription')) {
              Map<String, dynamic> subData = Map<String, dynamic>.from(
                data['subscription'],
              );

              // Check for end date, if null => Lifetime
              if (subData['endDate'] == null) {
                subData['endDate'] = DateTime(2099, 12, 31).toIso8601String();
                subData['isLifetime'] = true;
              }

              // Fix for Timestamp serialization error
              subData = _sanitizeForStorage(subData);

              _currentSubscription = subData;
              _storage.write('company_subscription', _currentSubscription);

              // If we see the new plan coming from server, clear provisional
              if (_provisionalPlan != null &&
                  _currentSubscription['plan'] == _provisionalPlan &&
                  _currentSubscription['status'] == 'active') {
                _provisionalPlan = null;
                _isProcessingUpgrade = false;
              }

              notifyListeners();
            }
          }
        });
  }

  void setProvisionalUpgrade(String planId) {
    _provisionalPlan = planId;
    _isProcessingUpgrade = true;
    notifyListeners();
  }

  void clearProvisionalUpgrade() {
    _provisionalPlan = null;
    _isProcessingUpgrade = false;
    notifyListeners();
  }

  Future<void> loadSubscription(String companyCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Query by companyCode instead of doc ID
      final querySnapshot =
          await _firestore
              .collection('businesses')
              .where('companyCode', isEqualTo: companyCode)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (data.containsKey('subscription')) {
          Map<String, dynamic> subData = Map<String, dynamic>.from(
            data['subscription'],
          );

          if (subData['endDate'] == null) {
            subData['endDate'] = DateTime(2099, 12, 31).toIso8601String();
            subData['isLifetime'] = true;
          }

          // Fix for Timestamp serialization error
          subData = _sanitizeForStorage(subData);

          _currentSubscription = subData;
          _storage.write('company_subscription', _currentSubscription);

          // Start streaming for updates
          initSubscriptionStream(companyCode);
        }
      }
    } catch (e) {
      _error = e.toString();
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradePlan(String businessId, String newPlanId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _controller.updateSubscription(businessId, newPlanId);
      // We rely on the stream or manual reload, but for now update local
      // Stream will overwrite this eventually
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _controller.cancelSubscription(businessId);
      // Optionally reload subscription or let stream handle it
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
