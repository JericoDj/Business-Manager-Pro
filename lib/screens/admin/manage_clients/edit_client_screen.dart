
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/client_provider.dart';
import '../../../utils/my_colors.dart';

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

    final width = MediaQuery.of(context).size.width * (kIsWeb ? 0.60 : 0.90);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Client"),
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
                  _input("Full Name", name),
                  _input("Address", address),
                  _input("Contact Number", contact),
                  _input("Email", email),
                  _input("Age", age, keyboard: TextInputType.number),
                  _input("Notes (Optional)", notes, maxLines: 3),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.darkShade,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final error = await provider.updateClient(
                        widget.client["id"],
                        name: name.text,
                        address: address.text,
                        contact: contact.text,
                        email: email.text,
                        age: int.parse(age.text),
                        notes: notes.text,
                      );

                      if (error == null) Navigator.pop(context);
                    },
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                        style: TextStyle(color: Colors.white),
                        "Save Changes"),
                  ),
                ],
              ),
            ),
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
          labelStyle: GoogleFonts.roboto(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
