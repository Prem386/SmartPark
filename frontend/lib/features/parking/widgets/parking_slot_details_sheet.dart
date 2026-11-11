import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import '../../bookings/create_booking_screen.dart';
import 'parking_status_legend.dart';

/// Bottom modal sheet presenting the inspected parking slot's details.
///
/// Displays authoritative attributes retrieved directly from [ParkingSlot].
///
/// // ponytail: standard ModalBottomSheet content; cleanly structured key-value rows
class ParkingSlotDetailsSheet extends StatelessWidget {
  final ParkingSlot slot;

  const ParkingSlotDetailsSheet({
    super.key,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = slot.status.color;
    final statusIcon = slot.status.icon;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Slot title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parking Bay ${slot.slotCode}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          '${slot.row.displayName} • Floor ${slot.floorNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close Details',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: slot.isAvailable
                    ? AppTheme.statusAvailable.withValues(alpha: 0.1)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: slot.isAvailable
                      ? AppTheme.statusAvailable.withValues(alpha: 0.3)
                      : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    slot.isAvailable
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: slot.isAvailable
                        ? AppTheme.statusAvailable
                        : Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slot.isAvailable
                          ? 'Ready for immediate parking'
                          : 'Not available for parking (${slot.status.displayName})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: slot.isAvailable
                            ? AppTheme.statusAvailable
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Attributes Grid
            _buildDetailRow('Status', slot.status.displayName,
                badgeColor: statusColor),
            const Divider(height: 16),
            _buildDetailRow(
              'Operational State',
              slot.isActive ? 'Active' : 'Inactive / Maintenance',
              badgeColor: slot.isActive
                  ? AppTheme.statusAvailable
                  : AppTheme.statusMaintenance,
            ),
            const Divider(height: 16),
            _buildDetailRow('Slot Type', slot.slotType.name.toUpperCase()),
            const Divider(height: 16),
            _buildDetailRow(
              'Coordinates (X, Y)',
              slot.x != null && slot.y != null
                  ? '${slot.x!.toStringAsFixed(1)}m, ${slot.y!.toStringAsFixed(1)}m'
                  : 'N/A',
            ),
            const Divider(height: 16),
            _buildDetailRow(
              'Navigation Node',
              slot.navigationNodeId ?? 'N/A',
            ),
            const SizedBox(height: 20),

            // Reserve Bay Action (if available)
            if (slot.isAvailable) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CreateBookingScreen(
                          initialSlotCode: slot.slotCode,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Reserve This Bay'),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? badgeColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
      ],
    );
  }
}

