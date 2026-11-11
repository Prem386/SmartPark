import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import 'parking_slot_tile.dart';

/// Interactive visual layout representing the physical parking facility.
///
/// Models the 38.0m x 16.0m single-floor layout:
/// - Row A (North): bays P01 to P10
/// - Central Driving Aisle: 6.0m two-way aisle with West Entrance and waypoints W01-W10
/// - Row B (South): bays P11 to P20
///
/// Wrapped in a horizontal scroll view to preserve readability and eliminate
/// overflow across all mobile and tablet viewports.
///
/// // ponytail: direct 10-column layout; standard SingleChildScrollView; 0 layout packages
class ParkingFacilityLayout extends StatelessWidget {
  final List<ParkingSlot> rowASlots;
  final List<ParkingSlot> rowBSlots;
  final String? selectedSlotCode;
  final Set<String> matchingSlotCodes;
  final ValueChanged<ParkingSlot> onSlotTapped;

  const ParkingFacilityLayout({
    super.key,
    required this.rowASlots,
    required this.rowBSlots,
    required this.selectedSlotCode,
    required this.matchingSlotCodes,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row A Header
            _buildRowHeader(
              context,
              title: 'ROW A (NORTH)',
              subtitle: 'Bays P01 – P10 • Y = 13.5m',
              icon: Icons.north,
            ),
            const SizedBox(height: 8),

            // Horizontally Scrollable Parking Diagram
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // West Entrance Column
                    _buildWestEntranceColumn(),
                    const SizedBox(width: 8),

                    // 10 Opposing Bay Columns (P01-P10 North, W01-W10 Aisle, P11-P20 South)
                    for (int i = 0; i < 10; i++) ...[
                      _buildBayPairColumn(i),
                      if (i < 9) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Row B Header
            _buildRowHeader(
              context,
              title: 'ROW B (SOUTH)',
              subtitle: 'Bays P11 – P20 • Y = 2.5m',
              icon: Icons.south,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWestEntranceColumn() {
    return Column(
      children: [
        // Upper wall buffer (aligned with Row A)
        Container(
          width: 82,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              'FACILITY\nWALL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Central Aisle Entrance Gate
        Container(
          width: 82,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.login, size: 14, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'ENTRY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'X=2.0m',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Lower wall buffer (aligned with Row B)
        Container(
          width: 82,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              'FACILITY\nWALL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBayPairColumn(int index) {
    final slotA = index < rowASlots.length ? rowASlots[index] : null;
    final slotB = index < rowBSlots.length ? rowBSlots[index] : null;

    final waypointNum = (index + 1).toString().padLeft(2, '0');
    final waypointX = (6.0 + (index * 3.0)).toStringAsFixed(1);

    return Column(
      children: [
        // Row A Bay (North)
        if (slotA != null)
          ParkingSlotTile(
            slot: slotA,
            isSelected: selectedSlotCode == slotA.slotCode,
            isDimmed: !matchingSlotCodes.contains(slotA.slotCode),
            onTap: () => onSlotTapped(slotA),
          )
        else
          const SizedBox(width: 86, height: 104),
        const SizedBox(height: 8),

        // Central Driving Aisle Waypoint Section
        Container(
          width: 86,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Colors.amber.shade300,
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 9, color: Colors.grey.shade600),
                  const SizedBox(width: 2),
                  Text(
                    'W$waypointNum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 9, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'X=${waypointX}m',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Row B Bay (South)
        if (slotB != null)
          ParkingSlotTile(
            slot: slotB,
            isSelected: selectedSlotCode == slotB.slotCode,
            isDimmed: !matchingSlotCodes.contains(slotB.slotCode),
            onTap: () => onSlotTapped(slotB),
          )
        else
          const SizedBox(width: 86, height: 104),
      ],
    );
  }
}
