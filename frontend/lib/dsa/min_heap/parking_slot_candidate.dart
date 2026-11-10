import '../../models/parking_slot.dart';

/// Represents an eligible parking bay paired with a caller-supplied route
/// distance from the facility entrance.
///
/// Used by the SmartPark recommendation algorithm to rank bays via [CustomMinHeap].
///
/// // ponytail: immutable candidate wrapper; route distance supplied externally (Dijkstra)
class ParkingSlotCandidate implements Comparable<ParkingSlotCandidate> {
  /// The candidate parking bay.
  final ParkingSlot slot;

  /// Driving/walking route distance from entrance in meters.
  ///
  /// Must be supplied by caller or pathfinder. Never computed with Euclidean distance.
  final double distance;

  /// Creates a [ParkingSlotCandidate] for an eligible [slot] with supplied [distance].
  ParkingSlotCandidate({
    required this.slot,
    required this.distance,
  }) {
    if (distance < 0 || distance.isNaN) {
      throw ArgumentError.value(
        distance,
        'distance',
        'Route distance must be a non-negative finite number.',
      );
    }
  }

  /// Compares two candidates.
  ///
  /// Primary criterion: ascending [distance] (shorter route has higher priority).
  /// Secondary tie-breaker: ascending [slot.slotCode] (alphabetical order, e.g. P01 before P02).
  @override
  int compareTo(ParkingSlotCandidate other) {
    final distanceComparison = distance.compareTo(other.distance);
    if (distanceComparison != 0) {
      return distanceComparison;
    }
    return slot.slotCode.compareTo(other.slot.slotCode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSlotCandidate &&
          runtimeType == other.runtimeType &&
          slot == other.slot &&
          distance == other.distance;

  @override
  int get hashCode => Object.hash(slot, distance);

  @override
  String toString() =>
      'ParkingSlotCandidate(${slot.slotCode}, distance: ${distance}m)';
}

