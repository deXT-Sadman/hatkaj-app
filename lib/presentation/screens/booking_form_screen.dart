import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/new_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/bookings_provider.dart';
import '../providers/services_provider.dart';
import '../providers/view_state.dart';
import '../widgets/error_banner.dart';
import 'checkout_screen.dart';

/// Pops with `true` when a booking was created.
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, this.initialServiceId});

  final int? initialServiceId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  static final _phonePattern = RegExp(r'^\+?[0-9\s\-]{7,20}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  int? _serviceId;
  DateTime? _date;
  TimeOfDay? _time;

  bool _isSubmitting = false;
  String? _formError;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void initState() {
    super.initState();
    _serviceId = widget.initialServiceId;

    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.defaultAddress ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String? _serverError(String field) => _serverErrors[field]?.first;

  DateTime? get _scheduledAt {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateController.text = MaterialLocalizations.of(context)
          .formatMediumDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _timeController.text = MaterialLocalizations.of(context)
          .formatTimeOfDay(picked);
    });
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _serverErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final booking = NewBooking(
      serviceId: _serviceId!,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      scheduledAt: _scheduledAt!,
      notes: _notesController.text.trim(),
    );
    try {
      final summary = await context.read<BookingsProvider>().previewBooking(
        booking,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final created = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(booking: booking, summary: summary),
        ),
      );
      if (!mounted) return;
      if (created == true) {
        navigator.pop(true);
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (error) {
      if (!mounted) return;
      final isValidation = error is ApiException && error.isValidationError;
      setState(() {
        _isSubmitting = false;
        _serverErrors = isValidation ? error.fieldErrors : const {};
        _formError = describeError(error);
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.watch<ServicesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New booking')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: servicesProvider.findById(_serviceId ?? -1)?.id,
              decoration: InputDecoration(
                labelText: 'Service',
                errorText: _serverError('service_id'),
              ),
              items: [
                for (final service in servicesProvider.services)
                  DropdownMenuItem(
                    value: service.id,
                    child: Text(service.name),
                  ),
              ],
              onChanged: (value) => setState(() => _serviceId = value),
              validator: (value) => value == null
                  ? 'Choose a service'
                  : _serverError('service_id'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : _serverError('customer_name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) => !_phonePattern.hasMatch(value?.trim() ?? '')
                  ? 'Enter a valid phone number'
                  : _serverError('customer_phone'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter the service address'
                  : _serverError('address'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Pick a date'
                        : _serverError('scheduled_at'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Pick a time';
                      final scheduledAt = _scheduledAt;
                      if (scheduledAt != null &&
                          !scheduledAt.isAfter(DateTime.now())) {
                        return 'Must be in the future';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(_formError!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Review booking'),
            ),
          ],
        ),
      ),
    );
  }
}
