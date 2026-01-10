class User {
  final String id;
  final String email;
  final String fullName;
  final String nim;
  final String phoneNumber;
  final String faculty;
  final String photoUrl;
  final DateTime createdAt;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.nim,
    required this.phoneNumber,
    required this.faculty,
    required this.photoUrl,
    required this.createdAt,
    this.isEmailVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? nim,
    String? phoneNumber,
    String? faculty,
    String? photoUrl,
    DateTime? createdAt,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      nim: nim ?? this.nim,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      faculty: faculty ?? this.faculty,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      nim: json['nim'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      faculty: json['faculty'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'nim': nim,
      'phoneNumber': phoneNumber,
      'faculty': faculty,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }
}