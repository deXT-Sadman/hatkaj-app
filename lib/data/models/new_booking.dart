import 'payment_method.dart';

/// The form payload for `POST /api/bookings` (a booking before the server assigns an id).
class NewBooking {
  const NewBooking({
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledAt,
    this.paymentMethod = PaymentMethod.cashOnService,
    this.notes,
  });

  final int serviceId;
  final String customerName;
  final String customerPhone;
  final String address;
  final DateTime scheduledAt;
  final PaymentMethod paymentMethod;
  final String? notes;

  NewBooking withPaymentMethod(PaymentMethod method) {
    return NewBooking(
      serviceId: serviceId,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      scheduledAt: scheduledAt,
      paymentMethod: method,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'address': address,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'payment_method': paymentMethod.apiValue,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
