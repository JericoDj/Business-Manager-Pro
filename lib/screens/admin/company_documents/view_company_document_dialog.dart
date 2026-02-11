import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/company_document_model.dart';
import '../../../services/company_document_service.dart';

class ViewCompanyDocumentDialog extends StatelessWidget {
  final CompanyDocumentModel document;

  const ViewCompanyDocumentDialog({Key? key, required this.document})
    : super(key: key);

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(document.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Status:', document.status),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Uploaded:',
            DateFormat('yyyy-MM-dd').format(document.createdAt),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Expiry:',
            document.expiryDate != null
                ? DateFormat('yyyy-MM-dd').format(document.expiryDate!)
                : 'N/A',
          ),
          const SizedBox(height: 8),
          _buildDetailRow('File Name:', document.fileName),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => _launchUrl(document.fileUrl),
          child: const Text('View/Download'),
        ),
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Delete Document'),
                    content: const Text(
                      'Are you sure you want to delete this document?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );

            if (confirm == true) {
              try {
                await CompanyDocumentService().deleteDocument(
                  document.id,
                  document.fileUrl,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close view dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting document: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
