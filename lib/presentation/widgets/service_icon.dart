import 'package:flutter/material.dart';

/// Picks an icon from the service name; falls back to a wrench.
IconData serviceIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('electric')) return Icons.bolt;
  if (lower.contains('plumb')) return Icons.water_drop_outlined;
  if (lower.contains('clean')) return Icons.cleaning_services_outlined;
  if (lower.contains('appliance')) return Icons.kitchen_outlined;
  if (lower.startsWith('ac ') || lower.contains('air con')) {
    return Icons.ac_unit;
  }
  return Icons.handyman_outlined;
}
