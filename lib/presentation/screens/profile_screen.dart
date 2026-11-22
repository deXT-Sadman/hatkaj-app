import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/view_state.dart';
import '../widgets/error_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final _phonePattern = RegExp(r'^\+?[0-9\s\-]{7,20}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;
  String? _formError;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
    _addressController = TextEditingController(text: user?.defaultAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _serverError(String field) => _serverErrors[field]?.first;

  Future<void> _save() async {
    setState(() {
      _formError = null;
      _serverErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        defaultAddress: _addressController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (error) {
      if (!mounted) return;
      final isValidation = error is ApiException && error.isValidationError;
      setState(() {
        _isSaving = false;
        _serverErrors = isValidation ? error.fieldErrors : const {};
        _formError = isValidation ? null : describeError(error);
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.email ?? ''),
            subtitle: const Text('Signed in'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter your name'
                : _serverError('name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
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
              labelText: 'Default address',
              helperText: 'Pre-filled when you book a service',
            ),
            validator: (_) => _serverError('default_address'),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 16),
            ErrorBanner(_formError!),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
