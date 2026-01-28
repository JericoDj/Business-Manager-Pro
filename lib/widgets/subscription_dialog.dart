import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/subscription_controller.dart';
import '../providers/transaction_provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDialog extends StatelessWidget {
  final String currentPlanId;
  final String? businessId;
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
                                      return;
                                    }

                                    // FREE PLAN
                                    if (id == 'free') {
                                      onPlanSelected(id);
                                      Navigator.pop(context);
                                      return;
                                    }

                                    // PAID PLAN
                                    if (businessId == null) return;

                                    try {
                                      final transactionProvider =
                                          Provider.of<TransactionProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final subscriptionProvider =
                                          Provider.of<SubscriptionProvider>(
                                            context,
                                            listen: false,
                                          );

                                      // 1. Provisional access
                                      subscriptionProvider
                                          .setProvisionalUpgrade(id);

                                      // 2. Create transaction (pending)
                                      final transactionId =
                                          await transactionProvider
                                              .createTransaction(
                                                businessId: businessId!,
                                                planId: id,
                                                amount:
                                                    double.tryParse(
                                                      plan['price'].toString(),
                                                    ) ??
                                                    0.0,
                                              );

                                      // 3. Start checkout (redirect / external payment)
                                      await SubscriptionController()
                                          .startCheckout(
                                            planId: id,
                                            businessId: businessId!,
                                            transactionId: transactionId,
                                          );



                                      // 4. Show verifying dialog
                                      if (!context.mounted) return;

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Verifying Payment"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text(
                                                "We are confirming your payment.\nThis may 1-2 minutes after payment is successful take a moment.",
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                      // 5. Wait for backend confirmation
                                      transactionProvider
                                          .waitForCompletion(transactionId)
                                          .then((success) {
                                            if (!context.mounted) return;

                                            if (success) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (_) => AlertDialog(
                                                      title: const Text(
                                                        "Payment Confirmed",
                                                      ),
                                                      content: Text(
                                                        "Your subscription has been successfully upgraded to ${plan['name']}.",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>{
                                              Navigator.pop(
                                              context,
                                              ),
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                                Navigator.pop(
                                                                  context,
                                                                ),


                                                              },

                                                          child: const Text(
                                                            "Continue",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            } else {
                                              subscriptionProvider
                                                  .clearProvisionalUpgrade();

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Payment not confirmed yet. Please check your email or try again.",
                                                  ),
                                                ),
                                              );
                                            }
                                          });
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
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
