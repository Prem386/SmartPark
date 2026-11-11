import '../../models/parking_slot.dart';
import '../min_heap/parking_slot_candidate.dart';
import 'dijkstra.dart';
import 'graph_node.dart';
import 'weighted_graph.dart';

/// Factory responsible for constructing the authoritative SmartPark prototype
/// facility navigation graph.
///
/// Follows the exact spatial layout and distances specified in:
/// `docs/PARKING_FACILITY_DESIGN.md` (Revision 2.1.0).
///
/// Total vertices: 31 (1 Entrance, 10 Aisle Waypoints, 20 Parking Bay Nodes).
/// Total edges: 30 undirected weighted links (60 directed adjacency list entries).
///
/// // ponytail: single factory for standard layout; deterministic node IDs and weights
class ParkingGraphFactory {
  const ParkingGraphFactory._();

  /// Canonical identifier for the single facility entrance.
  static const String entranceNodeId = 'NODE_ENTRANCE';

  /// Generates the canonical waypoint node ID for index [index] in 1..10.
  static String waypointNodeId(int index) =>
      'NODE_W${index.toString().padLeft(2, '0')}';

  /// Generates the canonical parking slot node ID for index [index] in 1..20.
  static String slotNodeId(int index) =>
      'NODE_P${index.toString().padLeft(2, '0')}';

  /// Maps a physical parking slot code (e.g. 'P01') to its graph node ID ('NODE_P01').
  static String slotCodeToNodeId(String slotCode) {
    final clean = slotCode.trim().toUpperCase();
    if (clean.startsWith('NODE_')) {
      return clean;
    }
    return 'NODE_$clean';
  }

  /// Maps a graph node ID (e.g. 'NODE_P01') back to physical slot code ('P01').
  static String nodeIdToSlotCode(String nodeId) {
    final clean = nodeId.trim().toUpperCase();
    if (clean.startsWith('NODE_')) {
      return clean.substring(5);
    }
    return clean;
  }

  /// Constructs, populates, and validates the authoritative SmartPark graph.
  static WeightedGraph createFacilityGraph() {
    final graph = WeightedGraph();

    // 1. Add entrance vertex at (2.0, 8.0)
    graph.addVertex(
      GraphNode(
        id: entranceNodeId,
        type: GraphNodeType.entrance,
        label: 'Main Entrance',
        x: 2.0,
        y: 8.0,
        floor: 1,
      ),
    );

    // 2. Add 10 central aisle waypoints at Y = 8.0m, X = 6.0 + 3.0 * (i - 1)
    for (int i = 1; i <= 10; i++) {
      final x = 6.0 + 3.0 * (i - 1);
      graph.addVertex(
        GraphNode(
          id: waypointNodeId(i),
          type: GraphNodeType.aisleWaypoint,
          label: 'Aisle Waypoint $i',
          x: x,
          y: 8.0,
          floor: 1,
        ),
      );
    }

    // 3. Add 20 parking bay nodes
    // Row A (North, P01-P10): Y = 13.5m
    for (int i = 1; i <= 10; i++) {
      final x = 6.0 + 3.0 * (i - 1);
      final code = 'P${i.toString().padLeft(2, '0')}';
      graph.addVertex(
        GraphNode(
          id: slotNodeId(i),
          type: GraphNodeType.parkingSlot,
          label: 'Slot $code (Row A)',
          x: x,
          y: 13.5,
          floor: 1,
        ),
      );
    }

    // Row B (South, P11-P20): Y = 2.5m
    for (int i = 1; i <= 10; i++) {
      final slotIndex = i + 10;
      final x = 6.0 + 3.0 * (i - 1);
      final code = 'P$slotIndex';
      graph.addVertex(
        GraphNode(
          id: slotNodeId(slotIndex),
          type: GraphNodeType.parkingSlot,
          label: 'Slot $code (Row B)',
          x: x,
          y: 2.5,
          floor: 1,
        ),
      );
    }

    // 4. Add Entrance to Waypoint 1 link (4.0m)
    graph.addUndirectedEdge(entranceNodeId, waypointNodeId(1), 4.0);

    // 5. Add 9 consecutive aisle backbone links (3.0m each)
    for (int i = 1; i <= 9; i++) {
      graph.addUndirectedEdge(waypointNodeId(i), waypointNodeId(i + 1), 3.0);
    }

    // 6. Add 10 Waypoint to Row A slot links (5.5m each)
    for (int i = 1; i <= 10; i++) {
      graph.addUndirectedEdge(waypointNodeId(i), slotNodeId(i), 5.5);
    }

    // 7. Add 10 Waypoint to Row B slot links (5.5m each)
    for (int i = 1; i <= 10; i++) {
      graph.addUndirectedEdge(waypointNodeId(i), slotNodeId(i + 10), 5.5);
    }

    // 8. Validate consistency
    graph.validateConsistency();

    return graph;
  }

  /// Calculates route distances from [entranceId] using [Dijkstra] and builds
  /// a list of [ParkingSlotCandidate] objects for recommendation ranking.
  ///
  /// Separates navigation distance calculation from heap-based recommendation ranking.
  static List<ParkingSlotCandidate> buildCandidates({
    required WeightedGraph graph,
    required Iterable<ParkingSlot> slots,
    String entranceId = entranceNodeId,
  }) {
    // 1. Compute all shortest distances from entrance in one Dijkstra pass
    final dijkstraResult = Dijkstra.computeAllShortestPaths(graph, entranceId);

    final candidates = <ParkingSlotCandidate>[];
    for (final slot in slots) {
      final targetNodeId = slot.navigationNodeId ?? slotCodeToNodeId(slot.slotCode);
      final distance = dijkstraResult.getDistanceTo(targetNodeId);

      if (distance != null) {
        candidates.add(
          ParkingSlotCandidate(
            slot: slot,
            distance: distance,
          ),
        );
      }
    }

    return candidates;
  }
}

