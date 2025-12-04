import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final homeAddress = TextEditingController();
  final dateOfBirth = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final companyCode = TextEditingController();

  bool loading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  String selectedRole = "user";
  final roles = ["user", "admin", "super_admin"];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Create Your Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),

                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                    ),

                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: "Email Address"),
                    ),

                    TextField(
                      controller: homeAddress,
                      decoration: const InputDecoration(labelText: "Home Address (US Format)"),
                    ),

                    TextField(
                      controller: companyCode,
                      decoration: const InputDecoration(labelText: "Company Code"),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Role",
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedRole = val!);
                      },
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: dateOfBirth,
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
                          initialDate: DateTime(2000),
                        );
                        if (picked != null) {
                          dateOfBirth.text =
                          "${picked.month}/${picked.day}/${picked.year}";
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: password,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => passwordVisible = !passwordVisible),
                        ),
                      ),
                    ),

                    TextField(
                      controller: confirmPassword,
                      obscureText: !confirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: loading
                          ? null
                          : () async {
                        if (password.text.trim() != confirmPassword.text.trim()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                          return;
                        }

                        setState(() => loading = true);

                        final error = await auth.registerUser(
                          name: name.text.trim(),
                          phone: phone.text.trim(),
                          email: email.text.trim(),
                          homeAddress: homeAddress.text.trim(),
                          dateOfBirth: dateOfBirth.text.trim(),
                          password: password.text.trim(),
                          role: selectedRole,
                          companyCode: companyCode.text.trim(),
                        );

                        if (!mounted) return;
                        setState(() => loading = false);

                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }

                        context.go("/");
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Register",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => context.go("/login"),
                      child: const Text("Already have an account? Login"),
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
