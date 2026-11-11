/// Represents an immutable weighted directed connection between two vertices in a graph.
///
/// Weight represents physical travel distance in meters.
///
/// // ponytail: immutable connection; non-negative finite weight validation
class GraphEdge {
  /// Starting vertex identifier.
  final String sourceNodeId;

  /// Ending vertex identifier.
  final String targetNodeId;

  /// Traversable travel distance/cost in meters. Must be non-negative and finite.
  final double weight;

  /// Creates a [GraphEdge] from [sourceNodeId] to [targetNodeId] with [weight].
  GraphEdge({
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.weight,
  }) {
    if (sourceNodeId.trim().isEmpty) {
      throw ArgumentError.value(
        sourceNodeId,
        'sourceNodeId',
        'Source node ID cannot be empty.',
      );
    }
    if (targetNodeId.trim().isEmpty) {
      throw ArgumentError.value(
        targetNodeId,
        'targetNodeId',
        'Target node ID cannot be empty.',
      );
    }
    if (sourceNodeId == targetNodeId) {
      throw ArgumentError(
        'Self-loops are not permitted: $sourceNodeId -> $targetNodeId.',
      );
    }
    if (weight < 0 || !weight.isFinite) {
      throw ArgumentError.value(
        weight,
        'weight',
        'Edge weight must be a non-negative finite number.',
      );
    }
  }

  /// Alias for [targetNodeId] for destination-oriented APIs.
  String get destinationNodeId => targetNodeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          sourceNodeId == other.sourceNodeId &&
          targetNodeId == other.targetNodeId &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(sourceNodeId, targetNodeId, weight);

  @override
  String toString() => 'GraphEdge($sourceNodeId -> $targetNodeId, weight: ${weight}m)';
}

