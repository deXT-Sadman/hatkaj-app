import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/view_state.dart';
import '../widgets/error_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final _phonePattern = RegExp(r'^\+?[0-9\s\-]{7,20}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _serverError(String field) => _serverErrors[field]?.first;

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _serverErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        defaultAddress: _addressController.text.trim(),
      );
      // The app rebuilds into the signed-in state, which replaces this screen.
    } catch (error) {
      if (!mounted) return;
      final isValidation = error is ApiException && error.isValidationError;
      setState(() {
        _isSubmitting = false;
        _serverErrors = isValidation ? error.fieldErrors : const {};
        _formError = isValidation ? null : describeError(error);
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : _serverError('name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Enter a valid email'
                  : _serverError('email'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters',
              ),
              validator: (value) => (value == null || value.length < 8)
                  ? 'Use at least 8 characters'
                  : _serverError('password'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isNotEmpty && !_phonePattern.hasMatch(phone)) {
                  return 'Enter a valid phone number';
                }
                return _serverError('phone');
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Default address (optional)',
              ),
              validator: (_) => _serverError('default_address'),
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
                  : const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
