import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/smartpark_scope.dart';
import '../parking/parking_slots_screen.dart';

/// Primary dashboard shell for SmartPark.
///
/// Obtains all slot metrics dynamically from [SmartParkScope], validating end-to-end
/// service integration.
///
/// // ponytail: pure stateless shell reading from SmartParkScope; minimal widgets
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SmartParkScope.of(context);
    final topCandidate =
        controller.recommendationService.getTopRecommendation();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartPark Dashboard'),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Facility Header
              _buildFacilityHeader(context),
              const SizedBox(height: 16),

              // Availability Summary Title
              Text(
                'Parking Availability Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Summary Metrics Grid
              _buildMetricsGrid(context, controller),
              const SizedBox(height: 20),

              // Algorithmic Recommendation Highlight
              if (topCandidate != null) ...[
                _buildRecommendationHighlight(context, topCandidate),
                const SizedBox(height: 20),
              ],

              // Navigation & Section Placeholders
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionCards(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SmartPark Facility (Floor 1)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Central Aisle Spine • 20 Total Bays (Rows A & B)',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 5 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth > 700 ? 1.5 : 1.8,
          children: [
            _MetricCard(
              label: 'Total Slots',
              value: '${controller.totalSlots}',
              color: AppTheme.primaryBlue,
              icon: Icons.local_parking,
            ),
            _MetricCard(
              label: 'Available',
              value: '${controller.availableSlots}',
              color: AppTheme.statusAvailable,
              icon: Icons.check_circle_outline,
            ),
            _MetricCard(
              label: 'Occupied',
              value: '${controller.occupiedSlots}',
              color: AppTheme.statusOccupied,
              icon: Icons.directions_car,
            ),
            _MetricCard(
              label: 'Reserved',
              value: '${controller.reservedSlots}',
              color: AppTheme.statusReserved,
              icon: Icons.bookmark_border,
            ),
            _MetricCard(
              label: 'Maintenance',
              value: '${controller.maintenanceSlots}',
              color: AppTheme.statusMaintenance,
              icon: Icons.build_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationHighlight(BuildContext context, dynamic candidate) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.stars, color: AppTheme.primaryBlue, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Optimal Slot Recommendation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bay ${candidate.slot.slotCode} (${candidate.slot.row.displayName})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${candidate.distance.toStringAsFixed(1)}m from entrance via Dijkstra path',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
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

  Widget _buildQuickActionCards(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.grid_view_rounded,
          title: 'Parking Slots',
          subtitle: 'View all 20 bays across Row A and Row B',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ParkingSlotsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.calendar_month_outlined,
          title: 'Bookings & Reservations',
          subtitle: 'Check reservation intervals and conflict validation',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking management available in Phase 3.2.'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.navigation_outlined,
          title: 'Facility Navigation',
          subtitle: 'Find turn-by-turn route from entrance to any slot',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Turn-by-turn navigation available in Phase 3.3.'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
