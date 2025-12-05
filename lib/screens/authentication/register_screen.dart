
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../../utils/my_colors.dart';

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
      backgroundColor: MyColors.lightShade.withOpacity(0.3),
      body: Center(
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MyColors.darkShade, width: 1.4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                /// HERO LOGO
                GestureDetector(
                  onTap: () => context.go("/login"),
                  child: Hero(
                    tag: "app_logo",
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.18,
                      child: Image.asset(
                        "assets/icons/app_logo_nobackground-min.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// APP NAME
                Text(
                  "My Business Manager",
                  style: GoogleFonts.roboto(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 4),

                /// TAGLINE
                Text(
                  "Smart tools for document and employee management",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: MyColors.darkShade.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 25),

                /// TITLE
                Text(
                  "Create Your Account",
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------ TEXT FIELDS ------------------
                _inputField("Full Name", name),
                _inputField("Phone Number", phone),
                _inputField("Email Address", email),
                _inputField("Home Address (US Format)", homeAddress),
                _inputField("Company Code", companyCode),

                const SizedBox(height: 10),

                DropdownButtonFormField(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: "Role",
                    labelStyle: GoogleFonts.roboto(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.roboto(),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: dateOfBirth,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    labelStyle: GoogleFonts.roboto(),
                    suffixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

                _passwordField(
                  label: "Password",
                  controller: password,
                  visible: passwordVisible,
                  toggle: () =>
                      setState(() => passwordVisible = !passwordVisible),
                ),

                _passwordField(
                  label: "Confirm Password",
                  controller: confirmPassword,
                  visible: confirmPasswordVisible,
                  toggle: () =>
                      setState(() => confirmPasswordVisible = !confirmPasswordVisible),
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
                      color: MyColors.darkShade,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Register",
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () => context.go("/login"),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Already have an account? Login",
                      style: GoogleFonts.roboto(
                        color: MyColors.darkShade,
                        fontWeight: FontWeight.bold,
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

  // ------------------ REUSABLE INPUT FIELD ------------------
  Widget _inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ------------------ PASSWORD FIELD ------------------
  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: MyColors.darkShade,
            ),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
