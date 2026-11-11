import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../services/smartpark_controller.dart';
import 'booking_details_sheet.dart';
import 'booking_status_badge.dart';

/// Card widget displaying booking summary in the bookings list.
///
/// // ponytail: standard Card layout matching existing dashboard cards
class BookingCard extends StatelessWidget {
  final Booking booking;
  final SmartParkController controller;

  const BookingCard({
    super.key,
    required this.booking,
    required this.controller,
  });

  bool get _isCancellable =>
      booking.status == BookingStatus.confirmed ||
      booking.status == BookingStatus.active;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingDetailsSheet(
        booking: booking,
        controller: controller,
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Cancel Booking ${booking.id}?'),
        content: Text(
          'Are you sure you want to cancel the reservation for Parking Bay ${booking.slotId} '
          'on ${_formatDate(booking.startTime)} from ${_formatTime(booking.startTime)} to ${_formatTime(booking.endTime)}?\n\n'
          'This will release the bay for other reservations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        try {
          controller.cancelBooking(booking.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking ${booking.id} cancelled successfully.'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel booking: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Bay code, Booking ID, and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking.slotId,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            booking.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 10),

              // Time & Date details
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${_formatTime(booking.startTime)} – ${_formatTime(booking.endTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          '(${_formatDuration(booking.duration)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(booking.startTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Optional User / Vehicle metadata
              if (booking.userId != null || booking.vehicleNumber != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    if (booking.userId != null)
                      Text(
                        'User: ${booking.userId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (booking.vehicleNumber != null)
                      Text(
                        'Vehicle: ${booking.vehicleNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],

              // Actions Footer
              if (_isCancellable) ...[
                const Divider(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDetails(context),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmCancel(context),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Booking'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

