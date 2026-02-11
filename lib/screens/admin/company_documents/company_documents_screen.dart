import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/company_document_model.dart';
import '../../../services/company_document_service.dart';
import '../../../utils/my_colors.dart';
import 'add_company_document_dialog.dart';
import 'view_company_document_dialog.dart';

class CompanyDocumentsScreen extends StatelessWidget {
  const CompanyDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CompanyDocumentService _service = CompanyDocumentService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Company Documents',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: MyColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<CompanyDocumentModel>>(
        stream: _service.getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No documents found.'));
          }

          final documents = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.description,
                    color: MyColors.primary,
                    size: 36,
                  ),
                  title: Text(
                    doc.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${doc.status}'),
                      if (doc.expiryDate != null)
                        Text(
                          'Expires: ${doc.expiryDate.toString().split(' ')[0]}',
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => ViewCompanyDocumentDialog(document: doc),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddCompanyDocumentDialog(),
          );
        },
        backgroundColor: MyColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
