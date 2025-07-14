class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final bool hasTerahiveEss;
  final bool isEmailVerified;
  final bool isActive;
  final String? phone;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> terahiveEss;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.hasTerahiveEss,
    required this.isEmailVerified,
    required this.isActive,
    this.phone,
    required this.preferences,
    required this.statistics,
    required this.terahiveEss,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userType: json['userType'] ?? 'regular',
      hasTerahiveEss: json['hasTerahiveEss'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      phone: json['phone'],
      preferences: json['preferences'] ?? {},
      statistics: json['statistics'] ?? {},
      terahiveEss: json['terahiveEss'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'userType': userType,
      'hasTerahiveEss': hasTerahiveEss,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'phone': phone,
      'preferences': preferences,
      'statistics': statistics,
      'terahiveEss': terahiveEss,
    };
  }

  String get fullName => '$firstName $lastName';
} 