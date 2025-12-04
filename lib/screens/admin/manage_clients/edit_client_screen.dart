import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/client_provider.dart';

class EditClientScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController name;
  late TextEditingController address;
  late TextEditingController contact;
  late TextEditingController email;
  late TextEditingController age;
  late TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final c = widget.client;

    name = TextEditingController(text: c["name"]);
    address = TextEditingController(text: c["address"]);
    contact = TextEditingController(text: c["contact"]);
    email = TextEditingController(text: c["email"]);
    age = TextEditingController(text: c["age"].toString());
    notes = TextEditingController(text: c["notes"] ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Client")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input("Full Name", name),
              _input("Address", address),
              _input("Contact Number", contact),
              _input("Email", email),
              _input("Age", age, keyboard: TextInputType.number),
              _input("Notes (Optional)", notes, maxLines: 3),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final error = await provider.updateClient(
                    widget.client["id"],
                    name: name.text,
                    address: address.text,
                    contact: contact.text,
                    email: email.text,
                    age: int.parse(age.text),
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
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
              ),
            ],
          ),
        ),
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
        validator: (v) => v!.isEmpty ? "$label required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
