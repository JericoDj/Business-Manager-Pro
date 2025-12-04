import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
      body: Center(
        child: SizedBox(
          width: 380,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "Register Business",
                      style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    // BUSINESS FIELDS -----------------------------
                    TextField(
                      controller: companyName,
                      decoration:
                      const InputDecoration(labelText: "Company Name"),
                    ),

                    TextField(
                      controller: businessEmail,
                      decoration:
                      const InputDecoration(labelText: "Business Email"),
                    ),

                    TextField(
                      controller: companyCode,
                      decoration: const InputDecoration(
                        labelText: "Company Code (unique)",
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Admin Information",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: adminName,
                      decoration:
                      const InputDecoration(labelText: "Full Name"),
                    ),

                    TextField(
                      controller: adminPhone,
                      decoration:
                      const InputDecoration(labelText: "Phone Number"),
                    ),

                    TextField(
                      controller: adminAddress,
                      decoration:
                      const InputDecoration(labelText: "Home Address"),
                    ),

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

                    // PASSWORDS ----------------------------
                    TextField(
                      controller: password,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                                  () => passwordVisible = !passwordVisible),
                        ),
                      ),
                    ),

                    TextField(
                      controller: confirmPassword,
                      obscureText: !confirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                          confirmPasswordVisible = !confirmPasswordVisible),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BUTTON ----------------------------
                    GestureDetector(
                      onTap: loading
                          ? null
                          : () async {
                        if (password.text.trim() !=
                            confirmPassword.text.trim()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text("Passwords do not match")),
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

                        // SAFETY CHECK: screen may already be gone
                        if (!mounted) return;

                        setState(() => loading = false);

                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }

                        await Future.delayed(const Duration(milliseconds: 150));

                        if (!mounted) return;
                        print("Navigating to admin screen");
                        context.go("/admin");
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text(
                          "Register Business",
                          style: TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () => context.go("/login"),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Back to Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
