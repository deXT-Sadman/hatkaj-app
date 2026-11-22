class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.defaultAddress,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? defaultAddress;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      defaultAddress: json['default_address'] as String?,
    );
  }
}
