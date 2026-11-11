/// Represents the immutable output of Dijkstra's algorithm.
///
/// Encapsulates the shortest path, calculated distance, predecessor chain,
/// and reachability status.
///
/// // ponytail: immutable results, defensive copies, null distance for unreachable nodes
class DijkstraResult {
  /// The origin vertex identifier.
  final String source;

  /// The queried destination vertex identifier, or `null` for all-pairs computations.
  final String? destination;

  /// Shortest route distance in meters, or `null` if [destination] is unreachable.
  final double? distance;

  /// Ordered sequence of vertex IDs from [source] to [destination].
  ///
  /// Empty if [destination] is unreachable or no path exists.
  final List<String> path;

  /// Whether a valid path exists from [source] to [destination].
  final bool hasPath;

  /// Unmodifiable map of shortest distances from [source] to all reachable vertices.
  final Map<String, double> allDistances;

  /// Unmodifiable map of predecessor vertex IDs used for path reconstruction.
  final Map<String, String?> predecessors;

  /// Creates an immutable [DijkstraResult].
  DijkstraResult({
    required this.source,
    this.destination,
    this.distance,
    required List<String> path,
    required this.hasPath,
    required Map<String, double> allDistances,
    required Map<String, String?> predecessors,
  })  : path = List.unmodifiable(path),
        allDistances = Map.unmodifiable(allDistances),
        predecessors = Map.unmodifiable(predecessors);

  /// Factory creating a successful single-destination result.
  factory DijkstraResult.found({
    required String source,
    required String destination,
    required double distance,
    required List<String> path,
    required Map<String, double> allDistances,
    required Map<String, String?> predecessors,
  }) {
    return DijkstraResult(
      source: source,
      destination: destination,
      distance: distance,
      path: path,
      hasPath: true,
      allDistances: allDistances,
      predecessors: predecessors,
    );
  }

  /// Factory creating an unreachable destination result.
  factory DijkstraResult.unreachable({
    required String source,
    required String destination,
    required Map<String, double> allDistances,
    required Map<String, String?> predecessors,
  }) {
    return DijkstraResult(
      source: source,
      destination: destination,
      distance: null,
      path: const <String>[],
      hasPath: false,
      allDistances: allDistances,
      predecessors: predecessors,
    );
  }

  /// Factory creating an all-destinations computation result.
  factory DijkstraResult.allDestinations({
    required String source,
    required Map<String, double> allDistances,
    required Map<String, String?> predecessors,
  }) {
    return DijkstraResult(
      source: source,
      destination: null,
      distance: null,
      path: const <String>[],
      hasPath: true,
      allDistances: allDistances,
      predecessors: predecessors,
    );
  }

  /// Reconstructs the shortest path from [source] to any [target] using [predecessors].
  ///
  /// Returns empty list if [target] is unreachable or not found.
  List<String> getPathTo(String target) {
    if (!allDistances.containsKey(target)) {
      return const <String>[];
    }
    if (target == source) {
      return List.unmodifiable([source]);
    }

    final reversedPath = <String>[];
    String? current = target;
    final visited = <String>{};

    while (current != null) {
      if (!visited.add(current)) {
        // Cycle guard
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

  /// Retrieves the shortest distance to [target], or `null` if unreachable.
  double? getDistanceTo(String target) => allDistances[target];

  @override
  String toString() {
    if (destination == null) {
      return 'DijkstraResult(source: $source, reachableCount: ${allDistances.length})';
    }
    if (!hasPath) {
      return 'DijkstraResult(source: $source, destination: $destination, UNREACHABLE)';
    }
    return 'DijkstraResult(source: $source -> $destination, distance: ${distance}m, path: $path)';
  }
}

