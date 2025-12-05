
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/my_colors.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final companyName = TextEditingController();
  final businessEmail = TextEditingController();
  final companyCode = TextEditingController();

  final adminName = TextEditingController();
  final adminPhone = TextEditingController();
  final adminAddress = TextEditingController();
  final adminBirthDate = TextEditingController();

  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool loading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white54,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MyColors.darkShade),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // ------------------ HERO LOGO ------------------
                  GestureDetector(
                    onTap: () => context.go("/login"),
                    child: Hero(
                      tag: "app_logo",
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.16,
                        child: Image.asset(
                          "assets/icons/app_logo_nobackground-min.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ------------------ APP NAME ------------------
                  Text(
                    "My Business Manager",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MyColors.darkShade,
                    ),
                  ),

                  // ------------------ TAGLINE ------------------
                  Text(
                    "Smart tools for your organization",
                    style: TextStyle(
                      fontSize: 14,
                      color: MyColors.darkShade.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ------------------ TITLE ------------------
                  const Text(
                    "Register Business",
                    style: TextStyle(
                      color: MyColors.darkShade,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------ BUSINESS FIELDS ------------------
                  TextField(
                    controller: companyName,
                    decoration: const InputDecoration(labelText: "Company Name"),
                  ),

                  const SizedBox(height: 10),


                  TextField(
                    controller: businessEmail,
                    decoration: const InputDecoration(labelText: "Business Email"),
                  ),

                  const SizedBox(height: 10),


                  TextField(
                    controller: companyCode,
                    decoration:
                    const InputDecoration(labelText: "Company Code (unique)"),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Admin Information",
                    style: TextStyle(
                      color: MyColors.darkShade,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: adminName,
                    decoration: const InputDecoration(labelText: "Full Name"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: adminPhone,
                    decoration: const InputDecoration(labelText: "Phone Number"),
                  ),
                  const SizedBox(height: 10),


                  TextField(
                    controller: adminAddress,
                    decoration: const InputDecoration(labelText: "Home Address"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: adminBirthDate,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Date of Birth",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        initialDate: DateTime(1990),
                      );
                      if (picked != null) {
                        adminBirthDate.text =
                        "${picked.month}/${picked.day}/${picked.year}";
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // ------------------ PASSWORD FIELDS ------------------
                  TextField(
                    controller: password,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => passwordVisible = !passwordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),


                  TextField(
                    controller: confirmPassword,
                    obscureText: !confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                              () => confirmPasswordVisible = !confirmPasswordVisible,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------ REGISTER BUTTON ------------------
                  GestureDetector(
                    onTap: loading
                        ? null
                        : () async {
                      if (password.text.trim() !=
                          confirmPassword.text.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Passwords do not match")),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      final error =
                      await auth.createBusinessAndAdmin(
                        companyName: companyName.text.trim(),
                        businessEmail: businessEmail.text.trim(),
                        companyCode: companyCode.text.trim(),
                        adminName: adminName.text.trim(),
                        adminPhone: adminPhone.text.trim(),
                        adminAddress: adminAddress.text.trim(),
                        adminBirthDate: adminBirthDate.text.trim(),
                        password: password.text.trim(),
                      );

                      if (!mounted) return;

                      setState(() => loading = false);

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }

                      await Future.delayed(
                          const Duration(milliseconds: 150));

                      if (!mounted) return;
                      context.go("/admin");
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
                          : const Text(
                        "Register Business",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () => context.go("/login"),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        "Back to Login",
                        style: TextStyle(
                          color: MyColors.darkShade,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
