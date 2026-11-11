import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';

/// Extension providing display helpers for [SlotStatus].
///
/// // ponytail: centralized enum presentation helpers; zero external packages
extension SlotStatusPresentation on SlotStatus {
  Color get color {
    switch (this) {
      case SlotStatus.available:
        return AppTheme.statusAvailable;
      case SlotStatus.occupied:
        return AppTheme.statusOccupied;
      case SlotStatus.reserved:
        return AppTheme.statusReserved;
      case SlotStatus.maintenance:
        return AppTheme.statusMaintenance;
    }
  }

  IconData get icon {
    switch (this) {
      case SlotStatus.available:
        return Icons.check_circle_outline;
      case SlotStatus.occupied:
        return Icons.directions_car;
      case SlotStatus.reserved:
        return Icons.bookmark_outline;
      case SlotStatus.maintenance:
        return Icons.build_outlined;
    }
  }

  String get displayName {
    switch (this) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.occupied:
        return 'Occupied';
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.maintenance:
        return 'Maintenance';
    }
  }
}

/// Visual legend explaining slot status colors and icons.
///
/// Ensures compliance with accessibility guidelines by pairing color
/// with explicit iconography and human-readable text labels.
///
/// // ponytail: simple stateless wrap displaying 4 canonical status badges
class ParkingStatusLegend extends StatelessWidget {
  const ParkingStatusLegend({super.key});

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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16.0,
          runSpacing: 8.0,
          children: SlotStatus.values.map((status) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, size: 16, color: status.color),
                const SizedBox(width: 6),
                Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

