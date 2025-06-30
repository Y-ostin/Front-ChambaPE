class User {
  final String name;
  final String email;
  final String role; // 'cliente' o 'trabajador'
  final String? phone;
  final String? address;
  final String? specialty;
  final String? experience;
  final double? rating;
  final int? jobsDone;
  final int? reviewsCount;
  final List<String>? certifications;
  final bool? isAvailable;

  User({
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.specialty,
    this.experience,
    this.rating,
    this.jobsDone,
    this.reviewsCount,
    this.certifications,
    this.isAvailable,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'cliente',
      phone: map['phone'],
      address: map['address'],
      specialty: map['specialty'],
      experience: map['experience'],
      rating: map['rating']?.toDouble(),
      jobsDone: map['jobsDone'],
      reviewsCount: map['reviewsCount'],
      certifications:
          map['certifications'] != null
              ? List<String>.from(map['certifications'])
              : null,
      isAvailable: map['isAvailable'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'specialty': specialty,
      'experience': experience,
      'rating': rating,
      'jobsDone': jobsDone,
      'reviewsCount': reviewsCount,
      'certifications': certifications,
      'isAvailable': isAvailable,
    };
  }
}
