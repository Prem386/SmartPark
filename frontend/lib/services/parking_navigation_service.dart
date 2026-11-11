import '../dsa/graph/dijkstra.dart';
import '../dsa/graph/dijkstra_result.dart';
import '../dsa/graph/graph_node.dart';
import '../dsa/graph/parking_graph_factory.dart';
import '../dsa/graph/weighted_graph.dart';
import '../models/parking_slot.dart';

/// Represents a computed navigation route from an origin node to a destination node.
///
/// Encapsulates total travel distance in meters, ordered sequence of graph node IDs,
/// and reachability status.
///
/// // ponytail: immutable route value object; direct node ID sequence
class NavigationRoute {
  /// Origin graph vertex ID (e.g. 'NODE_ENTRANCE').
  final String sourceNodeId;

  /// Destination graph vertex ID (e.g. 'NODE_P04').
  final String targetNodeId;

  /// Optional physical slot code associated with the destination (e.g. 'P04').
  final String? slotCode;

  /// Total travel distance along the path in meters.
  final double distance;

  /// Ordered sequence of graph node IDs representing the turn-by-turn path.
  final List<String> path;

  /// Whether a valid traversable path exists to the destination.
  final bool hasPath;

  const NavigationRoute({
    required this.sourceNodeId,
    required this.targetNodeId,
    this.slotCode,
    required this.distance,
    required this.path,
    required this.hasPath,
  });

  /// Factory creating an unreachable route indication.
  factory NavigationRoute.unreachable({
    required String sourceNodeId,
    required String targetNodeId,
    String? slotCode,
  }) {
    return NavigationRoute(
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
      slotCode: slotCode,
      distance: double.infinity,
      path: const <String>[],
      hasPath: false,
    );
  }

  @override
  String toString() {
    if (!hasPath) {
      return 'NavigationRoute($sourceNodeId -> $targetNodeId: UNREACHABLE)';
    }
    return 'NavigationRoute($sourceNodeId -> $targetNodeId: ${distance}m, path: $path)';
  }
}

/// Application service providing facility navigation and shortest-path routing.
///
/// Integrates [WeightedGraph], [Dijkstra], and [ParkingGraphFactory].
///
/// Maps parking bays to graph vertices using [ParkingSlot.navigationNodeId] or canonical
/// naming rules ([ParkingGraphFactory.slotCodeToNodeId]).
///
/// // ponytail: delegates pathfinding to Dijkstra; deterministic facility graph by default
class ParkingNavigationService {
  final WeightedGraph _graph;

  /// Creates a [ParkingNavigationService] with the specified [graph] or the authoritative
  /// SmartPark facility graph by default.
  ParkingNavigationService({WeightedGraph? graph})
      : _graph = graph ?? ParkingGraphFactory.createFacilityGraph();

  /// The underlying facility navigation graph.
  WeightedGraph get graph => _graph;

  /// Canonical facility entrance node ID.
  String get entranceNodeId => ParkingGraphFactory.entranceNodeId;

  /// Resolves the canonical graph vertex ID for [slot].
  ///
  /// Uses [slot.navigationNodeId] if specified; otherwise converts [slot.slotCode]
  /// via [ParkingGraphFactory.slotCodeToNodeId].
  String resolveNodeId(ParkingSlot slot) {
    if (slot.navigationNodeId != null && slot.navigationNodeId!.trim().isNotEmpty) {
      return slot.navigationNodeId!.trim();
    }
    return slotCodeToNodeId(slot.slotCode);
  }

  /// Converts a physical slot code (e.g. 'P01') to a canonical graph node ID ('NODE_P01').
  String slotCodeToNodeId(String slotCode) =>
      ParkingGraphFactory.slotCodeToNodeId(slotCode);

  /// Converts a canonical graph node ID (e.g. 'NODE_P01') to physical slot code ('P01').
  String nodeIdToSlotCode(String nodeId) =>
      ParkingGraphFactory.nodeIdToSlotCode(nodeId);

  /// Computes the shortest driving/walking path from [fromNodeId] to the specified [slot].
  ///
  /// Returns `null` if the destination vertex does not exist in the graph.
  /// Returns a [NavigationRoute] with `hasPath = false` if the destination is unreachable.
  NavigationRoute? getRouteToSlot(
    ParkingSlot slot, {
    String fromNodeId = ParkingGraphFactory.entranceNodeId,
  }) {
    final targetNodeId = resolveNodeId(slot);
    return findRoute(
      fromNodeId: fromNodeId,
      toNodeId: targetNodeId,
      slotCode: slot.slotCode,
    );
  }

  /// Computes the shortest driving/walking path from [fromNodeId] to a slot identified by [slotCode].
  NavigationRoute? getRouteToSlotCode(
    String slotCode, {
    String fromNodeId = ParkingGraphFactory.entranceNodeId,
  }) {
    final targetNodeId = slotCodeToNodeId(slotCode);
    return findRoute(
      fromNodeId: fromNodeId,
      toNodeId: targetNodeId,
      slotCode: slotCode.trim().toUpperCase(),
    );
  }

  /// Computes the shortest route between any two arbitrary vertices in the graph.
  ///
  /// Returns `null` if either vertex does not exist in the graph.
  NavigationRoute? findRoute({
    required String fromNodeId,
    required String toNodeId,
    String? slotCode,
  }) {
    final cleanFrom = fromNodeId.trim();
    final cleanTo = toNodeId.trim();

    if (!_graph.containsVertex(cleanFrom) || !_graph.containsVertex(cleanTo)) {
      return null;
    }

    final dijkstraResult = Dijkstra.findShortestPath(_graph, cleanFrom, cleanTo);
    if (!dijkstraResult.hasPath || dijkstraResult.distance == null) {
      return NavigationRoute.unreachable(
        sourceNodeId: cleanFrom,
        targetNodeId: cleanTo,
        slotCode: slotCode,
      );
    }

    return NavigationRoute(
      sourceNodeId: cleanFrom,
      targetNodeId: cleanTo,
      slotCode: slotCode,
      distance: dijkstraResult.distance!,
      path: dijkstraResult.path,
      hasPath: true,
    );
  }

  /// Computes shortest route distances from [fromNodeId] to all parking slots in the facility.
  ///
  /// Returns a map associating each physical slot code with its route distance in meters.
  /// Unreachable slots are excluded from the result map.
  Map<String, double> getDistancesToAllSlots({
    String fromNodeId = ParkingGraphFactory.entranceNodeId,
  }) {
    final cleanFrom = fromNodeId.trim();
    if (!_graph.containsVertex(cleanFrom)) {
      return const {};
    }

    final dijkstraResult = Dijkstra.computeAllShortestPaths(_graph, cleanFrom);
    final slotDistances = <String, double>{};

    for (final entry in dijkstraResult.allDistances.entries) {
      final nodeId = entry.key;
      final distance = entry.value;

      final vertex = _graph.getVertex(nodeId);
      if (vertex != null && vertex.type == GraphNodeType.parkingSlot) {
        final slotCode = nodeIdToSlotCode(nodeId);
        slotDistances[slotCode] = distance;
      }
    }

    return slotDistances;
  }

  /// Executes Dijkstra once to compute all shortest paths and predecessors from [fromNodeId].
  DijkstraResult computeAllDistances({
    String fromNodeId = ParkingGraphFactory.entranceNodeId,
  }) {
    final cleanFrom = fromNodeId.trim();
    if (!_graph.containsVertex(cleanFrom)) {
      throw ArgumentError('Origin node "$cleanFrom" does not exist in navigation graph.');
    }
    return Dijkstra.computeAllShortestPaths(_graph, cleanFrom);
  }
}

