import 'package:flutter/material.dart';

import '../../data/models/service.dart';
import 'booking_form_screen.dart';
import 'bookings_screen.dart';
import 'services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  Future<void> _openBookingForm({Service? service}) async {
    final messenger = ScaffoldMessenger.of(context);
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(initialServiceId: service?.id),
      ),
    );
    if (created == true && mounted) {
      setState(() => _tabIndex = 1);
      messenger.showSnackBar(const SnackBar(content: Text('Booking created')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HatKaj')),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          ServicesScreen(
            onBook: (service) => _openBookingForm(service: service),
          ),
          const BookingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBookingForm,
        icon: const Icon(Icons.add),
        label: const Text('New booking'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}
