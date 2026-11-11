import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/parking_slot.dart';
import '../../services/smartpark_controller.dart';
import '../../widgets/smartpark_scope.dart';
import 'widgets/parking_facility_layout.dart';
import 'widgets/parking_filter_bar.dart';
import 'widgets/parking_slot_details_sheet.dart';
import 'widgets/parking_status_legend.dart';

/// Interactive parking facility overview screen.
///
/// Features:
/// - Real-time facility metrics derived from [SmartParkController]
/// - Canonical 20-bay layout (Row A North, Row B South, Central Aisle)
/// - CustomHashMap-backed slot lookup
/// - Case-insensitive bay code search and status filtering
/// - Interactive slot inspection bottom sheet
///
/// // ponytail: standard StatefulWidget managing local search/filter state; reads controller via SmartParkScope
class ParkingSlotsScreen extends StatefulWidget {
  const ParkingSlotsScreen({super.key});

  @override
  State<ParkingSlotsScreen> createState() => _ParkingSlotsScreenState();
}

class _ParkingSlotsScreenState extends State<ParkingSlotsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SlotStatus? _selectedStatus;
  String? _selectedSlotCode;

  // Canonical slot code sequences defined in PARKING_FACILITY_DESIGN.md
  static final List<String> _rowACodes = List.generate(
    10,
    (i) => 'P${(i + 1).toString().padLeft(2, '0')}',
  );

  static final List<String> _rowBCodes = List.generate(
    10,
    (i) => 'P${(i + 11).toString().padLeft(2, '0')}',
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toUpperCase();
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _onStatusFilterChanged(SlotStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _onSlotTapped(ParkingSlot slot, SmartParkController controller) {
    setState(() {
      _selectedSlotCode = slot.slotCode;
    });

    // Authoritative lookup via CustomHashMap service
    final authoritativeSlot =
        controller.slotService.getSlot(slot.slotCode) ?? slot;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ParkingSlotDetailsSheet(slot: authoritativeSlot),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedSlotCode = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = SmartParkScope.of(context);

    // Retrieve slots via CustomHashMap-backed service
    final rowASlots = <ParkingSlot>[];
    for (final code in _rowACodes) {
      final slot = controller.slotService.getSlot(code);
      if (slot != null) {
        rowASlots.add(slot);
      }
    }

    final rowBSlots = <ParkingSlot>[];
    for (final code in _rowBCodes) {
      final slot = controller.slotService.getSlot(code);
      if (slot != null) {
        rowBSlots.add(slot);
      }
    }

    final allSlots = [...rowASlots, ...rowBSlots];

    // Evaluate matching slots based on combined search & filter criteria
    final matchingCodes = <String>{};
    for (final slot in allSlots) {
      final matchesSearch =
          _searchQuery.isEmpty || slot.slotCode.contains(_searchQuery);
      final matchesStatus =
          _selectedStatus == null || slot.status == _selectedStatus;

      if (matchesSearch && matchesStatus) {
        matchingCodes.add(slot.slotCode);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Data to Defaults',
            onPressed: () {
              controller.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Facility data reset to defaults.'),
                ),
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
              // Screen Header
              _buildHeader(context),
              const SizedBox(height: 14),

              // Live Parking Statistics
              _buildLiveMetrics(context, controller),
              const SizedBox(height: 14),

              // Search & Status Filter Controls
              ParkingFilterBar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onClearSearch: _onClearSearch,
                selectedStatus: _selectedStatus,
                onStatusChanged: _onStatusFilterChanged,
                matchingCount: matchingCodes.length,
                totalCount: allSlots.length,
              ),
              const SizedBox(height: 14),

              // Status Visual Legend
              const ParkingStatusLegend(),
              const SizedBox(height: 14),

              // Interactive Facility Layout or Empty State
              if (matchingCodes.isEmpty)
                _buildEmptyState()
              else
                ParkingFacilityLayout(
                  rowASlots: rowASlots,
                  rowBSlots: rowBSlots,
                  selectedSlotCode: _selectedSlotCode,
                  matchingSlotCodes: matchingCodes,
                  onSlotTapped: (slot) => _onSlotTapped(slot, controller),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'SmartPark Facility (Floor 1)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '20 standard bays • Two parallel rows • Central driving aisle',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetrics(BuildContext context, SmartParkController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 650 ? 5 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: constraints.maxWidth > 650 ? 2.2 : 1.9,
          children: [
            _MiniMetricCard(
              label: 'Total',
              value: '${controller.totalSlots}',
              color: AppTheme.primaryBlue,
              icon: Icons.local_parking,
            ),
            _MiniMetricCard(
              label: 'Available',
              value: '${controller.availableSlots}',
              color: AppTheme.statusAvailable,
              icon: Icons.check_circle_outline,
            ),
            _MiniMetricCard(
              label: 'Occupied',
              value: '${controller.occupiedSlots}',
              color: AppTheme.statusOccupied,
              icon: Icons.directions_car,
            ),
            _MiniMetricCard(
              label: 'Reserved',
              value: '${controller.reservedSlots}',
              color: AppTheme.statusReserved,
              icon: Icons.bookmark_border,
            ),
            _MiniMetricCard(
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
                Icons.search_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No matching parking slots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No slots match the current search "$_searchQuery" or selected status filter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _onClearSearch();
                  _onStatusFilterChanged(null);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Filters'),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

