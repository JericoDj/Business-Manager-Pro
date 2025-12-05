
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../../utils/my_colors.dart' show MyColors;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

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
                color: Colors.grey.withOpacity(0.4),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------ APP LOGO ------------------
                Hero(
                  tag: "app_logo",
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.16,
                    child: Image.asset(
                      "assets/icons/app_logo_nobackground-min.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------ APP NAME ------------------
                Text(
                  "My Business Manager",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 4),

                // ------------------ TAGLINE ------------------
                Text(
                  "Manage documents, employees, and business operations with ease",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: MyColors.darkShade.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------ SECTION TITLE ------------------
                Text(
                  "Login",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------ EMAIL ------------------
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------ PASSWORD ------------------
                TextField(
                  controller: password,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => passwordVisible = !passwordVisible);
                      },
                    ),
                  ),
                ),

                // ------------------ FORGOT PASSWORD ------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.go("/forgot-password"),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: MyColors.darkShade,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------ LOGIN BUTTON ------------------
                GestureDetector(
                  onTap: loading
                      ? null
                      : () async {
                    setState(() => loading = true);

                    final error = await auth.login(
                      email.text.trim(),
                      password.text.trim(),
                    );

                    if (!mounted) return;
                    setState(() => loading = false);

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    final profile = GetStorage().read("profile");
                    if (profile["role"] == "admin" ||
                        profile["role"] == "super_admin") {
                      context.go("/admin");
                    } else {
                      context.go("/");
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: MyColors.darkShade,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Login",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ------------------ CREATE USER ------------------
                GestureDetector(
                  onTap: () => context.go("/register"),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Create User Account",
                      style: TextStyle(
                        color: MyColors.darkShade,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------ REGISTER BUSINESS ------------------
                GestureDetector(
                  onTap: () => context.go("/register-business"),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: MyColors.lightShade,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Register as Business",
                      style: TextStyle(
                        color: MyColors.darkShade,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
