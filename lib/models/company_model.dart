class CompanyModel {
  final String id;
  final String name;
  final String code;   // unique code users enter during registration
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'createdAt': createdAt,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      createdAt: map['createdAt'].toDate(),
    );
  }
}
