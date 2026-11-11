import 'dart:math' as math;

import '../dsa/min_heap/min_heap.dart';
import '../models/parking_slot.dart';
import 'parking_navigation_service.dart';
import 'parking_slot_service.dart';

/// Application service generating optimal parking slot recommendations.
///
/// Orchestrates:
/// 1. [ParkingSlotService]: In-memory slot registry via [CustomHashMap].
/// 2. [ParkingNavigationService]: Route distance calculation via [WeightedGraph] and [Dijkstra].
/// 3. [ParkingSlotCandidate]: Domain candidate pairing [ParkingSlot] with exact Dijkstra route distance.
/// 4. [CustomMinHeap]: Priority queue extracting candidate slots ordered by shortest distance,
///    with deterministic alphabetical tie-breaking on [ParkingSlot.slotCode].
///
/// Recommendation Invariants:
/// - Only slots with [ParkingSlot.isAvailable] (i.e. `isActive == true` and `status == SlotStatus.available`)
///   are eligible for recommendation.
/// - Unreachable slots (no path from entrance or infinite distance) are excluded.
/// - Top-$N$ extraction halts once $N$ candidates have been extracted from the heap,
///   avoiding full heap drain.
/// - Returns clean empty list when no eligible or reachable slots exist.
///
/// // ponytail: combines existing DSA services; no redundant heap or Dijkstra code
class ParkingRecommendationService {
  /// The underlying slot registry service.
  final ParkingSlotService slotService;

  /// The underlying navigation routing service.
  final ParkingNavigationService navigationService;

  /// Creates a [ParkingRecommendationService] coordinating [slotService] and [navigationService].
  ParkingRecommendationService({
    required this.slotService,
    required this.navigationService,
  });

  /// Returns recommended parking slots in priority order (shortest travel distance first).
  ///
  /// Parameters:
  /// - [limit]: Maximum number of recommendations to return (top-$N$). If `null` or $\le 0$,
  ///   all eligible and reachable candidates are returned.
  /// - [entranceNodeId]: Graph vertex ID to compute distances from (defaults to facility entrance).
  ///
  /// Workflow:
  /// 1. Gathers all registered slots from [ParkingSlotService].
  /// 2. Filters for availability via [ParkingSlot.isAvailable].
  /// 3. Computes Dijkstra shortest paths from [entranceNodeId] in a single pass.
  /// 4. Wraps reachable eligible slots into [ParkingSlotCandidate] instances.
  /// 5. Builds [CustomMinHeap] priority queue using $O(n) $ Floyd's algorithm.
  /// 6. Extracts up to [limit] candidates via [CustomMinHeap.extractMin].
  List<ParkingSlotCandidate> getRecommendations({
    int? limit,
    String? entranceNodeId,
  }) {
    final fromNode = entranceNodeId ?? navigationService.entranceNodeId;

    // 1. Check origin node existence in navigation graph
    if (!navigationService.graph.containsVertex(fromNode)) {
      return const <ParkingSlotCandidate>[];
    }

    // 2. Filter eligible slots (must be active and available)
    final eligibleSlots = slotService
        .getAllSlots()
        .where((slot) => slot.isAvailable)
        .toList();

    if (eligibleSlots.isEmpty) {
      return const <ParkingSlotCandidate>[];
    }

    // 3. Compute all shortest path distances from entrance in one Dijkstra pass
    final dijkstraResult = navigationService.computeAllDistances(fromNodeId: fromNode);

    // 4. Create candidates for eligible and reachable slots
    final candidates = <ParkingSlotCandidate>[];
    for (final slot in eligibleSlots) {
      final targetNodeId = navigationService.resolveNodeId(slot);
      final distance = dijkstraResult.getDistanceTo(targetNodeId);

      // Only recommend slots with a valid finite navigation distance
      if (distance != null && distance.isFinite) {
        candidates.add(
          ParkingSlotCandidate(
            slot: slot,
            distance: distance,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return const <ParkingSlotCandidate>[];
    }

    // 5. Build min-heap using Floyd's O(n) algorithm
    final heap = CustomMinHeap<ParkingSlotCandidate>.from(candidates);

    // 6. Extract top-N recommendations
    final totalAvailable = heap.size;
    final extractCount = (limit != null && limit > 0)
        ? math.min(limit, totalAvailable)
        : totalAvailable;

    final recommendations = <ParkingSlotCandidate>[];
    for (int i = 0; i < extractCount; i++) {
      final candidate = heap.extractMin();
      if (candidate != null) {
        recommendations.add(candidate);
      }
    }

    return recommendations;
  }

  /// Convenience method returning the single highest-priority recommended slot,
  /// or `null` if no eligible slots are reachable.
  ParkingSlotCandidate? getTopRecommendation({String? entranceNodeId}) {
    final results = getRecommendations(limit: 1, entranceNodeId: entranceNodeId);
    return results.isEmpty ? null : results.first;
  }
}
