import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/booking.dart';
import '../../data/models/booking_status.dart';
import '../providers/bookings_provider.dart';
import '../widgets/service_icon.dart';
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

    final filter = provider.statusFilter;

    return Column(
      children: [
        _FilterBar(
          selected: filter,
          onSelected: (status) =>
              _showErrorIfAny(context, provider.setStatusFilter(status)),
        ),
        Expanded(
          child: StateView(
            state: provider.state,
            errorMessage: provider.errorMessage,
            emptyMessage: filter == null
                ? 'No bookings yet.\nTap "New booking" to make one.'
                : 'No ${filter.label.toLowerCase()} bookings.',
            onRefresh: () => _showErrorIfAny(context, provider.refresh()),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
              itemCount: provider.bookings.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.bookings.length) {
                  return _LoadMore(
                    isLoading: provider.isLoadingMore,
                    onPressed: () =>
                        _showErrorIfAny(context, provider.loadMore()),
                  );
                }
                return _BookingCard(provider.bookings[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final BookingStatus? selected;
  final ValueChanged<BookingStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final status in BookingStatus.values)
            ChoiceChip(
              label: Text(status.label),
              selected: selected == status,
              onSelected: (_) => onSelected(status),
            ),
        ],
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

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: statusColor(booking.status)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            serviceIcon(booking.service?.name ?? ''),
                            size: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            booking.service?.name ?? 'Service',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusMenu(booking),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.schedule, text: when),
                    _InfoRow(
                      icon: Icons.person_outline,
                      text: booking.customerName,
                    ),
                    _InfoRow(icon: Icons.place_outlined, text: booking.address),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip that doubles as a menu of the transitions the API allows.
class _StatusMenu extends StatelessWidget {
  const _StatusMenu(this.booking);

  final Booking booking;

  Future<void> _change(BuildContext context, BookingStatus status) async {
    final provider = context.read<BookingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(booking, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Booking marked ${status.label.toLowerCase()}.'),
        ),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = booking.status.allowedTransitions;
    if (options.isEmpty) return StatusChip(booking.status);

    return PopupMenuButton<BookingStatus>(
      tooltip: 'Change status',
      onSelected: (status) => _change(context, status),
      itemBuilder: (_) => [
        for (final status in options)
          PopupMenuItem(
            value: status,
            child: Text('Mark ${status.label.toLowerCase()}'),
          ),
      ],
      child: StatusChip(booking.status),
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
