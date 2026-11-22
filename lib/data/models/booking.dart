import 'booking_status.dart';
import 'payment_method.dart';
import 'pricing.dart';
import 'service.dart';

class Booking {
  const Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    required this.status,
    this.paymentMethod = PaymentMethod.cashOnService,
    this.pricing,
    this.notes,
    this.service,
  });

  final int id;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final Pricing? pricing;
  final String? notes;
  final Service? service;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final pricing = json['pricing'];
    return Booking(
      id: json['id'] as int,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      address: json['address'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      status: BookingStatus.fromApi(json['status'] as String),
      paymentMethod: PaymentMethod.fromApi(
        json['payment_method'] as String? ?? 'cash_on_service',
      ),
      pricing: pricing is Map<String, dynamic>
          ? Pricing.fromJson(pricing)
          : null,
      notes: json['notes'] as String?,
      service: service is Map<String, dynamic>
          ? Service.fromJson(service)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'address': address,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'status': status.apiValue,
    'payment_method': paymentMethod.apiValue,
    'notes': notes,
    'service': service?.toJson(),
  };
}
