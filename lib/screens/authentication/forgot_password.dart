
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_business_manager/utils/my_colors.dart' show MyColors;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool loading = false;

  // RESEND TIMER SYSTEM
  int secondsRemaining = 0;
  Timer? timer;

  void startTimer() {
    secondsRemaining = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MyColors.darkShade),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO
                Hero(
                  tag: "app_logo",
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.15,
                    child: Image.asset("assets/icons/app_logo_nobackground-min.png"),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter your email and we will send you a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "Email"),
                ),

                const SizedBox(height: 25),

                // SEND RESET LINK BUTTON
                GestureDetector(
                  onTap: loading || secondsRemaining > 0
                      ? null
                      : () async {
                    if (email.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter your email."),
                        ),
                      );
                      return;
                    }

                    setState(() => loading = true);

                    /// 🔥 CALLS PROVIDER METHOD
                    final error = await context
                        .read<AuthProvider>()
                        .forgotPassword(email.text.trim());

                    if (!mounted) return;
                    setState(() => loading = false);

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reset link sent to your email!"),
                      ),
                    );

                    startTimer(); // 🔥 Start cooldown timer
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: secondsRemaining > 0 ? Colors.grey : MyColors.darkShade,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      secondsRemaining > 0
                          ? "Resend in $secondsRemaining s"
                          : "Send Reset Link",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
,

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => context.go("/login"),
                  child: Text(
                    "Back to Login",
                    style: TextStyle(
                      color: MyColors.darkShade,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
