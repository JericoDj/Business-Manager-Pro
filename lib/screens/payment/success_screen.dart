import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/my_colors.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                "Payment Successful!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: MyColors.darkShade,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                "Thank you for your purchase. Your subscription has been updated.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: MyColors.darkShade.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),

              // Back Button
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: SizedBox(
                   width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.darkShade,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    // Navigate back to dashboard or home
                    // Removing all previous routes to prevent back navigation to success page
                    context.go('/admin');
                  },
                  child: const Text(
                    "Back to Application",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
