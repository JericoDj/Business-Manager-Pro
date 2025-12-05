
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/client_provider.dart';
import '../../../utils/my_colors.dart' show MyColors;

class CreateClientScreen extends StatefulWidget {
  const CreateClientScreen({super.key});

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final address = TextEditingController();
  final contact = TextEditingController();
  final email = TextEditingController();
  final age = TextEditingController();
  final notes = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    final width = MediaQuery.of(context).size.width * (kIsWeb ? 0.60 : 0.90);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Client"),
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MyColors.darkShade),
            borderRadius: BorderRadius.circular(16),
          ),

          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _requiredInput("Full Name", name),

                  _input("Address (Optional)", address),
                  _input("Contact Number (Optional)", contact),
                  _input("Email (Optional)", email),
                  _input("Age (Optional)", age, keyboard: TextInputType.number),
                  _input("Notes (Optional)", notes, maxLines: 3),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.darkShade,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final error = await provider.addClient(
                        name: name.text,
                        address: address.text,
                        contact: contact.text,
                        email: email.text,
                        age: age.text.isEmpty ? 0 : int.parse(age.text),
                        notes: notes.text.isEmpty ? null : notes.text,
                      );

                      if (error == null) Navigator.pop(context);
                    },
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.white),
                        "Save Client"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _requiredInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.trim().isEmpty ? "$label is required" : null,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
