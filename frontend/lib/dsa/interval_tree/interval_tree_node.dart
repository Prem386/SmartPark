import '../../models/booking.dart';

/// A node in the [CustomIntervalTree] representing a single parking [Booking] interval.
///
/// Stores AVL balancing metadata ([height]) and interval tree augmentation metadata ([maxEnd]).
///
/// // ponytail: wraps domain Booking directly; avoids redundant Interval DTO
class IntervalTreeNode {
  /// The underlying parking booking reservation.
  Booking booking;

  /// Subtree augmentation: the maximum [Booking.endTime] across all nodes
  /// in the subtree rooted at this node.
  DateTime maxEnd;

  /// Height of the subtree rooted at this node (1 for a leaf node).
  int height;

  /// Left subtree child (bookings with smaller start times under deterministic ordering).
  IntervalTreeNode? left;

  /// Right subtree child (bookings with larger start times under deterministic ordering).
  IntervalTreeNode? right;

  /// Creates an [IntervalTreeNode] wrapping the provided [booking].
  IntervalTreeNode({
    required this.booking,
    DateTime? maxEnd,
    this.height = 1,
    this.left,
    this.right,
  }) : maxEnd = maxEnd ?? booking.endTime;

  /// Unique identifier of the booking.
  String get id => booking.id;

  /// Allocated parking slot identifier (e.g. 'P01').
  String get slotId => booking.slotId;

  /// Interval start time (inclusive).
  DateTime get startTime => booking.startTime;

  /// Interval end time (exclusive).
  DateTime get endTime => booking.endTime;

  @override
  String toString() =>
      'IntervalTreeNode(id: $id, slotId: $slotId, '
      '${startTime.toIso8601String()} -> ${endTime.toIso8601String()}, '
      'maxEnd: ${maxEnd.toIso8601String()}, h: $height)';
}

