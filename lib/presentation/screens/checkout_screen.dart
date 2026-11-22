import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/booking.dart';
import '../../data/models/booking_summary.dart';
import '../../data/models/new_booking.dart';
import '../../data/models/payment_method.dart';
import '../providers/bookings_provider.dart';
import '../providers/view_state.dart';
import '../widgets/error_banner.dart';

/// Shows the server's booking summary, lets the customer pick a payment method,
/// and confirms. Pops with `true` once a booking was created.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.booking,
    required this.summary,
  });

  final NewBooking booking;
  final BookingSummary summary;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late PaymentMethod _paymentMethod = widget.summary.paymentMethod;

  bool _isSubmitting = false;
  String? _error;
  Booking? _confirmed;

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final created = await context.read<BookingsProvider>().createBooking(
        widget.booking.withPaymentMethod(_paymentMethod),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _confirmed = created;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = describeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _confirmed;

    return PopScope(
      canPop: confirmed == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(confirmed == null ? 'Review & confirm' : 'Confirmed'),
          automaticallyImplyLeading: confirmed == null,
        ),
        body: confirmed == null
            ? _buildSummary(context)
            : _buildConfirmation(context, confirmed),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final summary = widget.summary;
    final localizations = MaterialLocalizations.of(context);
    final pricing = summary.pricing;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Service',
          children: [
            _Row(summary.service.name, _money(pricing.basePrice), bold: true),
            _Row('Duration', '${summary.service.durationMinutes} min'),
          ],
        ),
        _Section(
          title: 'When & where',
          children: [
            _Row('Date', localizations.formatMediumDate(summary.scheduledAt)),
            _Row(
              'Time',
              localizations.formatTimeOfDay(
                TimeOfDay.fromDateTime(summary.scheduledAt),
              ),
            ),
            _Row('Address', summary.address),
            _Row(
              'Contact',
              '${summary.customerName}\n${summary.customerPhone}',
            ),
            if (summary.notes != null && summary.notes!.isNotEmpty)
              _Row('Notes', summary.notes!),
          ],
        ),
        _Section(
          title: 'Price',
          children: [
            _Row('Service price', _money(pricing.basePrice)),
            _Row('Service fee', _money(pricing.serviceFee)),
            const Divider(),
            _Row('Total', _money(pricing.totalAmount), bold: true),
          ],
        ),
        _Section(
          title: 'Payment method',
          children: [
            SegmentedButton<PaymentMethod>(
              showSelectedIcon: false,
              segments: [
                for (final method in PaymentMethod.values)
                  ButtonSegment(value: method, label: Text(method.label)),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: _isSubmitting
                  ? null
                  : (selected) =>
                        setState(() => _paymentMethod = selected.first),
            ),
            const SizedBox(height: 8),
            Text(
              'No payment is taken in this demo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          ErrorBanner(_error!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isSubmitting ? null : _confirm,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Confirm booking · ${_money(pricing.totalAmount)}'),
        ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context, Booking booking) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final total =
        booking.pricing?.totalAmount ?? widget.summary.pricing.totalAmount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Booking #${booking.id} placed',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${booking.service?.name ?? widget.summary.service.name} on '
            '${localizations.formatMediumDate(booking.scheduledAt)} at '
            '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt))}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_money(total)} · ${booking.paymentMethod.label}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static String _money(double amount) => '৳${amount.toStringAsFixed(2)}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w600) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
