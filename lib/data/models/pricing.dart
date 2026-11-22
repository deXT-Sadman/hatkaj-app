/// Price breakdown for a booking, as calculated by the server.
class Pricing {
  const Pricing({
    required this.basePrice,
    required this.serviceFee,
    required this.totalAmount,
  });

  final double basePrice;
  final double serviceFee;
  final double totalAmount;

  factory Pricing.fromJson(Map<String, dynamic> json) {
    // Laravel serialises decimals as strings ("1200.00").
    return Pricing(
      basePrice: double.parse(json['base_price'].toString()),
      serviceFee: double.parse(json['service_fee'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
    );
  }
}
