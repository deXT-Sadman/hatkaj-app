import 'package:flutter/material.dart';

import '../../data/models/booking_status.dart';

Color statusColor(BookingStatus status) => switch (status) {
  BookingStatus.pending => Colors.orange,
  BookingStatus.confirmed => Colors.blue,
  BookingStatus.completed => Colors.green,
  BookingStatus.cancelled => Colors.red,
};

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final BookingStatus status;

  Color get _color => statusColor(status);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      labelStyle: TextStyle(color: _color, fontWeight: FontWeight.w600),
      backgroundColor: _color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
