import 'booking_status.dart';
import 'service.dart';

class Booking {
  const Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    required this.status,
    this.notes,
    this.service,
  });

  final int id;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final BookingStatus status;
  final String? notes;
  final Service? service;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    return Booking(
      id: json['id'] as int,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      address: json['address'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      status: BookingStatus.fromApi(json['status'] as String),
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
    'notes': notes,
    'service': service?.toJson(),
  };
}
