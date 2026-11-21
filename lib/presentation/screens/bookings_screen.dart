import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/booking.dart';
import '../providers/bookings_provider.dart';
import '../widgets/state_view.dart';
import '../widgets/status_chip.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  Future<void> _showErrorIfAny(
    BuildContext context,
    Future<String?> request,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await request;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingsProvider>();

    return StateView(
      state: provider.state,
      errorMessage: provider.errorMessage,
      emptyMessage: 'No bookings yet.\nTap "New booking" to make one.',
      onRefresh: () => _showErrorIfAny(context, provider.refresh()),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: provider.bookings.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.bookings.length) {
            return _LoadMore(
              isLoading: provider.isLoadingMore,
              onPressed: () => _showErrorIfAny(context, provider.loadMore()),
            );
          }
          return _BookingCard(provider.bookings[index]);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard(this.booking);

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final when =
        '${localizations.formatMediumDate(booking.scheduledAt)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt))}';

    return Card(
      child: ListTile(
        title: Text(booking.service?.name ?? 'Service'),
        subtitle: Text('$when\n${booking.customerName}\n${booking.address}'),
        isThreeLine: true,
        trailing: StatusChip(booking.status),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : TextButton(onPressed: onPressed, child: const Text('Load more')),
      ),
    );
  }
}
