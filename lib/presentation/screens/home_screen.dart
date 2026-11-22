import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/booking_status.dart';
import '../../data/models/service.dart';
import '../providers/bookings_provider.dart';
import '../providers/dashboard_provider.dart';
import 'booking_form_screen.dart';
import 'bookings_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _dashboardTab = 0;
  static const _servicesTab = 1;
  static const _bookingsTab = 2;
  static const _profileTab = 3;

  int _tabIndex = _dashboardTab;

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (index == _dashboardTab) {
      context.read<DashboardProvider>().refresh();
    }
  }

  void _showBookings(BookingStatus? status) {
    final bookings = context.read<BookingsProvider>();
    if (bookings.statusFilter != status) {
      bookings.setStatusFilter(status);
    }
    setState(() => _tabIndex = _bookingsTab);
  }

  Future<void> _openBookingForm({Service? service}) async {
    final messenger = ScaffoldMessenger.of(context);
    final dashboard = context.read<DashboardProvider>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(initialServiceId: service?.id),
      ),
    );
    if (created == true && mounted) {
      dashboard.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('Booking created')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDashboard = _tabIndex == _dashboardTab;

    return Scaffold(
      appBar: isDashboard
          ? null
          : AppBar(
              title: Text(switch (_tabIndex) {
                _servicesTab => 'Services',
                _profileTab => 'Profile',
                _ => 'Bookings',
              }),
            ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          DashboardScreen(
            onBookService: (service) => _openBookingForm(service: service),
            onOpenBookings: _showBookings,
            onSeeAllServices: () => _selectTab(_servicesTab),
          ),
          ServicesScreen(
            onBook: (service) => _openBookingForm(service: service),
          ),
          const BookingsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _tabIndex == _profileTab
          ? null
          : FloatingActionButton.extended(
              onPressed: _openBookingForm,
              icon: const Icon(Icons.add),
              label: const Text('New booking'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
