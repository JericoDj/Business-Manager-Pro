import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/client_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text("Create Client")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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

                  if (error == null) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                },
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Client"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REQUIRED FIELD (Name Only)
  Widget _requiredInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.trim().isEmpty ? "$label is required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // OPTIONAL FIELDS
  Widget _input(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
