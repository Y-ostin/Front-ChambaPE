class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String role;
  final bool isActive;
  final String? photoURL;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    required this.role,
    this.isActive = true,
    this.photoURL,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      phone: json['phone'] ?? json['phoneNumber'],
      address: json['address'],
      role: json['role'] is Map 
        ? json['role']['name'] ?? 'USER'
        : json['role'] ?? 'USER',
      isActive: json['isActive'] ?? true,
      photoURL: json['photoURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
      'isActive': isActive,
      'photoURL': photoURL,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? address,
    String? role,
    bool? isActive,
    String? photoURL,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoURL: photoURL ?? this.photoURL,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, name: $name, role: $role)';
  }
}
