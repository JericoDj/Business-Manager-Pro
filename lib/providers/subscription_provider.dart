import 'package:flutter/material.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionController _controller = SubscriptionController();

  Map<String, dynamic> _currentSubscription = {
    'plan': 'free',
    'status': 'active',
  };

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic> get currentPlanDetails =>
      SubscriptionController.plans[_currentSubscription['plan']] ??
      SubscriptionController.plans['free']!;

  Future<void> loadSubscription(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sub = await _controller.getSubscription(businessId);
      if (sub != null) {
        _currentSubscription = sub;
      }
    } catch (e) {
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
      _currentSubscription = {
        'plan': newPlanId,
        'status': 'active',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
