import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/subscription_controller.dart';
import '../providers/transaction_provider.dart';

class SubscriptionDialog extends StatelessWidget {
  final String currentPlanId;
  final String?
  businessId; // Optional: If provided, triggers checkout. If null, just selects plan.
  final Function(String) onPlanSelected;

  const SubscriptionDialog({
    Key? key,
    required this.currentPlanId,
    this.businessId,
    required this.onPlanSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            Text(
              "Choose Your Plan",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children:
                    SubscriptionController.plans.entries.map((entry) {
                      final id = entry.key;
                      final plan = entry.value;
                      final isCurrent = id == currentPlanId;

                      return Card(
                        color: isCurrent ? Colors.blue.shade50 : null,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side:
                              isCurrent
                                  ? const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  )
                                  : BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            plan['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              id == 'custom'
                                  ? const Text(
                                    "Contact us for tailored solutions",
                                  )
                                  : Text(
                                    "${plan['maxAdmins']} Admins • ${plan['maxEmployees']} Employees",
                                  ),
                          trailing:
                              isCurrent
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  )
                                  : Text(
                                    id == 'free'
                                        ? "Free"
                                        : "\$${plan['price']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          onTap:
                              isCurrent
                                  ? null
                                  : () async {
                                    if (id == 'custom') {
                                      // Handle custom contact
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please email us at support@example.com",
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Trigger Checkout
                                      if (id != 'free' && businessId != null) {
                                        // For paid plans, trigger checkout
                                        try {
                                          final provider =
                                              Provider.of<TransactionProvider>(
                                                context,
                                                listen: false,
                                              );

                                          // 1. Create Transaction
                                          final transactionId = await provider
                                              .createTransaction(
                                                businessId: businessId!,
                                                planId: id,
                                                amount:
                                                    double.tryParse(
                                                      plan['price'].toString(),
                                                    ) ??
                                                    0.0,
                                              );

                                          // 2. Start Checkout
                                          await SubscriptionController()
                                              .startCheckout(
                                                planId: id,
                                                businessId: businessId!,
                                                transactionId: transactionId,
                                              );

                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      } else {
                                        // Free plan update immediately
                                        onPlanSelected(id);
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
