class Service {
  const Service({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      // Laravel serialises decimals as strings ("1200.00").
      price: double.parse(json['price'].toString()),
      durationMinutes: json['duration_minutes'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'duration_minutes': durationMinutes,
  };
}
