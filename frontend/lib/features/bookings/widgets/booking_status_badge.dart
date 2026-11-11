import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';

/// Extension providing visual presentation properties for [BookingStatus].
extension BookingStatusVisuals on BookingStatus {
  /// Human-friendly display label.
  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Primary theme color for the status.
  Color get color {
    switch (this) {
      case BookingStatus.confirmed:
        return AppTheme.primaryBlue;
      case BookingStatus.active:
        return AppTheme.statusAvailable;
      case BookingStatus.completed:
        return const Color(0xFF64748B);
      case BookingStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  /// Icon associated with the status.
  IconData get icon {
    switch (this) {
      case BookingStatus.confirmed:
        return Icons.bookmark_added_outlined;
      case BookingStatus.active:
        return Icons.play_circle_outline;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

/// A compact status pill/chip widget for [BookingStatus].
///
/// // ponytail: simple Container badge; zero extra deps
class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool showIcon;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

