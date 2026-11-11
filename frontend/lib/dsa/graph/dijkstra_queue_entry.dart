/// Represents a priority queue entry for Dijkstra's shortest path relaxation.
///
/// Implements [Comparable] to prioritize the smallest tentative distance in
/// [CustomMinHeap]. Ties are broken deterministically by [vertexId].
///
/// // ponytail: immutable entry; standard comparator for MinHeap integration
class DijkstraQueueEntry implements Comparable<DijkstraQueueEntry> {
  /// The vertex identifier.
  final String vertexId;

  /// Tentative distance from the source vertex in meters.
  final double tentativeDistance;

  /// Creates a [DijkstraQueueEntry].
  const DijkstraQueueEntry({
    required this.vertexId,
    required this.tentativeDistance,
  });

  @override
  int compareTo(DijkstraQueueEntry other) {
    final distanceComparison = tentativeDistance.compareTo(other.tentativeDistance);
    if (distanceComparison != 0) {
      return distanceComparison;
    }
    return vertexId.compareTo(other.vertexId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DijkstraQueueEntry &&
          runtimeType == other.runtimeType &&
          vertexId == other.vertexId &&
          tentativeDistance == other.tentativeDistance;

  @override
  int get hashCode => Object.hash(vertexId, tentativeDistance);

  @override
  String toString() => 'DijkstraQueueEntry($vertexId, tentative: ${tentativeDistance}m)';
}

