import '../min_heap/min_heap.dart';
import 'dijkstra_queue_entry.dart';
import 'dijkstra_result.dart';
import 'weighted_graph.dart';

/// Implementation of Dijkstra's algorithm from first principles.
///
/// Built for the SmartPark academic parking management prototype (Phase 2.6).
///
/// Uses the custom [CustomMinHeap] priority queue from Phase 2.4 with the standard
/// lazy duplicate-entry relaxation approach.
///
/// // ponytail: lazy relaxation via CustomMinHeap, early exit on target extraction, clean null-safe paths
class Dijkstra {
  const Dijkstra();

  /// Finds the shortest path and distance from [source] to [destination] in [graph].
  ///
  /// Throws [ArgumentError] if [source] or [destination] does not exist in [graph].
  /// Returns [DijkstraResult] with [DijkstraResult.hasPath] = false and `distance = null`
  /// if [destination] is unreachable.
  static DijkstraResult findShortestPath(
    WeightedGraph graph,
    String source,
    String destination,
  ) {
    _validateVertexExists(graph, source, 'source');
    _validateVertexExists(graph, destination, 'destination');

    // Trivial path: source equals destination
    if (source == destination) {
      return DijkstraResult.found(
        source: source,
        destination: destination,
        distance: 0.0,
        path: [source],
        allDistances: {source: 0.0},
        predecessors: {source: null},
      );
    }

    final distances = <String, double>{};
    final predecessors = <String, String?>{};
    final minHeap = CustomMinHeap<DijkstraQueueEntry>();

    // 1. Initialize source
    distances[source] = 0.0;
    predecessors[source] = null;
    minHeap.insert(
      DijkstraQueueEntry(vertexId: source, tentativeDistance: 0.0),
    );

    // 2. Process priority queue
    while (minHeap.isNotEmpty) {
      final current = minHeap.extractMin()!;

      // 3. Skip stale entries
      final currentBest = distances[current.vertexId];
      if (currentBest != null && current.tentativeDistance > currentBest) {
        continue;
      }

      // Early exit optimization: when target is extracted, its distance is finalized
      if (current.vertexId == destination) {
        break;
      }

      // 4. Relax outgoing edges
      final edges = graph.getAdjacentEdges(current.vertexId);
      for (final edge in edges) {
        final neighbor = edge.targetNodeId;
        final alternateDistance = current.tentativeDistance + edge.weight;
        final previousBest = distances[neighbor] ?? double.infinity;

        if (alternateDistance < previousBest) {
          distances[neighbor] = alternateDistance;
          predecessors[neighbor] = current.vertexId;
          minHeap.insert(
            DijkstraQueueEntry(
              vertexId: neighbor,
              tentativeDistance: alternateDistance,
            ),
          );
        }
      }
    }

    // 5. Check reachability
    final destDistance = distances[destination];
    if (destDistance == null) {
      return DijkstraResult.unreachable(
        source: source,
        destination: destination,
        allDistances: distances,
        predecessors: predecessors,
      );
    }

    // 6. Reconstruct path
    final path = _reconstructPath(source, destination, predecessors);
    return DijkstraResult.found(
      source: source,
      destination: destination,
      distance: destDistance,
      path: path,
      allDistances: distances,
      predecessors: predecessors,
    );
  }

  /// Computes shortest distances from [source] to all reachable vertices in [graph].
  ///
  /// Throws [ArgumentError] if [source] does not exist in [graph].
  static DijkstraResult computeAllShortestPaths(
    WeightedGraph graph,
    String source,
  ) {
    _validateVertexExists(graph, source, 'source');

    final distances = <String, double>{};
    final predecessors = <String, String?>{};
    final minHeap = CustomMinHeap<DijkstraQueueEntry>();

    distances[source] = 0.0;
    predecessors[source] = null;
    minHeap.insert(
      DijkstraQueueEntry(vertexId: source, tentativeDistance: 0.0),
    );

    while (minHeap.isNotEmpty) {
      final current = minHeap.extractMin()!;

      // Skip stale queue entries
      final currentBest = distances[current.vertexId];
      if (currentBest != null && current.tentativeDistance > currentBest) {
        continue;
      }

      final edges = graph.getAdjacentEdges(current.vertexId);
      for (final edge in edges) {
        final neighbor = edge.targetNodeId;
        final alternateDistance = current.tentativeDistance + edge.weight;
        final previousBest = distances[neighbor] ?? double.infinity;

        if (alternateDistance < previousBest) {
          distances[neighbor] = alternateDistance;
          predecessors[neighbor] = current.vertexId;
          minHeap.insert(
            DijkstraQueueEntry(
              vertexId: neighbor,
              tentativeDistance: alternateDistance,
            ),
          );
        }
      }
    }

    return DijkstraResult.allDestinations(
      source: source,
      allDistances: distances,
      predecessors: predecessors,
    );
  }

  static void _validateVertexExists(
    WeightedGraph graph,
    String vertexId,
    String paramName,
  ) {
    if (!graph.containsVertex(vertexId)) {
      throw ArgumentError.value(
        vertexId,
        paramName,
        'Vertex "$vertexId" does not exist in the graph.',
      );
    }
  }

  static List<String> _reconstructPath(
    String source,
    String destination,
    Map<String, String?> predecessors,
  ) {
    final reversedPath = <String>[];
    String? current = destination;
    final visited = <String>{};

    while (current != null) {
      if (!visited.add(current)) {
        // Cycle safety guard
        return const <String>[];
      }
      reversedPath.add(current);
      if (current == source) {
        break;
      }
      current = predecessors[current];
    }

    if (reversedPath.isEmpty || reversedPath.last != source) {
      return const <String>[];
    }

    return List.unmodifiable(reversedPath.reversed);
  }
}
