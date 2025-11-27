class DocumentModel {
  final String type;
  final String fileUrl;
  final DateTime? expiration;
  final DateTime uploadedAt;

  DocumentModel({
    required this.type,
    required this.fileUrl,
    this.expiration,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fileUrl': fileUrl,
      'expiration': expiration?.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      type: json['type'],
      fileUrl: json['fileUrl'],
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'])
          : null,
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }
}
