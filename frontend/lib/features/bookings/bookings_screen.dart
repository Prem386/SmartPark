import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking.dart';
import '../../widgets/smartpark_scope.dart';
import 'create_booking_screen.dart';
import 'widgets/booking_card.dart';

/// Screen displaying all active and historical bookings, with status filtering,
/// real-time updates, cancellation, and creation triggers.
///
/// // ponytail: standard StatefulWidget managing presentation-only filter state; reads controller via SmartParkScope
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  BookingStatus? _selectedStatusFilter;

  void _onFilterChanged(BookingStatus? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
  }

  void _navigateToCreateBooking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<Booking?>(
        builder: (_) => const CreateBookingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = SmartParkScope.of(context);
    final allBookings = controller.allBookings;

    // Presentation-only filtering
    final filteredBookings = _selectedStatusFilter == null
        ? allBookings
        : allBookings.where((b) => b.status == _selectedStatusFilter).toList();

    // Summary counts
    final confirmedCount =
        allBookings.where((b) => b.status == BookingStatus.confirmed).length;
    final activeCount =
        allBookings.where((b) => b.status == BookingStatus.active).length;
    final completedCount =
        allBookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelledCount =
        allBookings.where((b) => b.status == BookingStatus.cancelled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings & Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Data to Defaults',
            onPressed: () {
              controller.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Facility data reset to defaults.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header Banner
              _buildHeaderBanner(context),
              const SizedBox(height: 14),

              // Live Booking Metrics
              _buildMetricsGrid(
                total: allBookings.length,
                confirmed: confirmedCount,
                active: activeCount,
                completed: completedCount,
                cancelled: cancelledCount,
              ),
              const SizedBox(height: 14),

              // Filter Chips
              _buildFilterChips(allBookings.length),
              const SizedBox(height: 14),

              // Bookings List or Empty State
              if (filteredBookings.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return BookingCard(
                      key: ValueKey(booking.id),
                      booking: booking,
                      controller: controller,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateBooking(context),
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SmartPark Reservations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'In-memory temporal conflict detection backed by custom AVL Interval Tree',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int total,
    required int confirmed,
    required int active,
    required int completed,
    required int cancelled,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 650 ? 5 : 3;
        const targetHeight = 58.0;
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
        final childAspectRatio = itemWidth / targetHeight;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
          children: [
            _MiniMetricCard(
              label: 'Total',
              value: '$total',
              color: AppTheme.primaryBlue,
              icon: Icons.calendar_month,
            ),
            _MiniMetricCard(
              label: 'Confirmed',
              value: '$confirmed',
              color: AppTheme.primaryBlue,
              icon: Icons.bookmark_added_outlined,
            ),
            _MiniMetricCard(
              label: 'Active',
              value: '$active',
              color: AppTheme.statusAvailable,
              icon: Icons.play_circle_outline,
            ),
            _MiniMetricCard(
              label: 'Completed',
              value: '$completed',
              color: const Color(0xFF64748B),
              icon: Icons.check_circle_outline,
            ),
            _MiniMetricCard(
              label: 'Cancelled',
              value: '$cancelled',
              color: const Color(0xFFDC2626),
              icon: Icons.cancel_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text('All ($totalCount)'),
            selected: _selectedStatusFilter == null,
            onSelected: (_) => _onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Confirmed'),
            selected: _selectedStatusFilter == BookingStatus.confirmed,
            onSelected: (sel) =>
                _onFilterChanged(sel ? BookingStatus.confirmed : null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Active'),
            selected: _selectedStatusFilter == BookingStatus.active,
            onSelected: (sel) =>
                _onFilterChanged(sel ? BookingStatus.active : null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Completed'),
            selected: _selectedStatusFilter == BookingStatus.completed,
            onSelected: (sel) =>
                _onFilterChanged(sel ? BookingStatus.completed : null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Cancelled'),
            selected: _selectedStatusFilter == BookingStatus.cancelled,
            onSelected: (sel) =>
                _onFilterChanged(sel ? BookingStatus.cancelled : null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedStatusFilter != null
                    ? 'No ${_selectedStatusFilter!.name} bookings'
                    : 'No bookings found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedStatusFilter != null
                    ? 'There are currently no bookings with the selected filter.'
                    : 'No parking reservations are currently scheduled.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedStatusFilter != null)
                ElevatedButton.icon(
                  onPressed: () => _onFilterChanged(null),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Show All Bookings'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateBooking(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create New Booking'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
