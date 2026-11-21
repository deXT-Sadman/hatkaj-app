import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/service.dart';
import '../providers/services_provider.dart';
import '../widgets/service_icon.dart';
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
          final scheme = Theme.of(context).colorScheme;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onBook(service),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        serviceIcon(service.name),
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (service.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              service.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${service.durationMinutes} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '৳${service.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
