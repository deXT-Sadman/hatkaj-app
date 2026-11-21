import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/service.dart';
import '../providers/services_provider.dart';
import '../widgets/state_view.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.onBook});

  /// Called when the user taps a service to book it.
  final void Function(Service service) onBook;

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<ServicesProvider>().refresh();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicesProvider>();

    return StateView(
      state: provider.state,
      errorMessage: provider.errorMessage,
      emptyMessage: 'No services available right now.',
      onRefresh: () => _refresh(context),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: provider.services.length,
        itemBuilder: (context, index) {
          final service = provider.services[index];
          return Card(
            child: ListTile(
              title: Text(service.name),
              subtitle: Text(
                [
                  if (service.description != null) service.description!,
                  '${service.durationMinutes} min',
                ].join('\n'),
              ),
              isThreeLine: service.description != null,
              trailing: Text(
                '৳${service.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => onBook(service),
            ),
          );
        },
      ),
    );
  }
}
