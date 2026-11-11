import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import 'parking_status_legend.dart';

/// Interactive UI tile representing a single physical parking bay.
///
/// Follows the facility specification: 90-degree bay orientation,
/// explicit slot code, status icon, and human-readable state label.
///
/// // ponytail: standard Container + InkWell; no complex canvas or layout packages
class ParkingSlotTile extends StatelessWidget {
  final ParkingSlot slot;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback? onTap;

  const ParkingSlotTile({
    super.key,
    required this.slot,
    this.isSelected = false,
    this.isDimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = slot.status.color;
    final statusIcon = slot.status.icon;
    final statusLabel = slot.status.displayName;

    final tile = Semantics(
      button: true,
      enabled: !isDimmed && onTap != null,
      label: 'Parking Bay ${slot.slotCode}, Status $statusLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDimmed ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 86,
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                  : statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : statusColor.withValues(alpha: 0.6),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ).boxShadow!.first,
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Slot code
                Text(
                  slot.slotCode,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryDark,
                  ),
                ),

                // Center icon
                Icon(
                  statusIcon,
                  size: 26,
                  color: statusColor,
                ),

                // Bottom label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDimmed) {
      return Opacity(
        opacity: 0.25,
        child: tile,
      );
    }

    return tile;
  }
}

