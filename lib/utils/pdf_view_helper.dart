import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File> _downloadPDF(String url) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File("${tempDir.path}/temp_doc.pdf");

  final response = await http.get(Uri.parse(url));
  await tempFile.writeAsBytes(response.bodyBytes);

  return tempFile;
}