import 'payment_method.dart';
import 'pricing.dart';
import 'service.dart';

/// The checkout preview returned by `POST /api/bookings/preview`. Nothing is saved yet.
class BookingSummary {
  const BookingSummary({
    required this.service,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    required this.paymentMethod,
    required this.pricing,
    this.notes,
  });

  final Service service;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final PaymentMethod paymentMethod;
  final Pricing pricing;
  final String? notes;

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      service: Service.fromJson(json['service'] as Map<String, dynamic>),
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      address: json['address'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      paymentMethod: PaymentMethod.fromApi(json['payment_method'] as String),
      pricing: Pricing.fromJson(json['pricing'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
    );
  }
}
