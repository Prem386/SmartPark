import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/graph/graph.dart';
import 'package:smartpark_app/dsa/min_heap/min_heap.dart';
import 'package:smartpark_app/models/parking_slot.dart';

void main() {
  group('ParkingGraphFactory - Facility Specification Verification', () {
    late WeightedGraph graph;

    setUp(() {
      graph = ParkingGraphFactory.createFacilityGraph();
    });

    test('facility graph contains exactly 31 vertices and 30 undirected edges', () {
      expect(graph.vertexCount, equals(31));
      expect(graph.undirectedEdgeCount, equals(30));
      expect(graph.edgeCount, equals(30));
      expect(graph.directedEdgeCount, equals(60));
      expect(graph.validateConsistency(), isTrue);
    });

    test('facility graph contains all documented vertex IDs and types', () {
      // 1. Entrance node
      expect(graph.containsVertex(ParkingGraphFactory.entranceNodeId), isTrue);
      final entrance = graph.getVertex(ParkingGraphFactory.entranceNodeId)!;
      expect(entrance.type, equals(GraphNodeType.entrance));
      expect(entrance.label, equals('Main Entrance'));
      expect(entrance.x, equals(2.0));
      expect(entrance.y, equals(8.0));
      expect(entrance.floor, equals(1));

      // 2. 10 Central aisle waypoints
      for (int i = 1; i <= 10; i++) {
        final wpId = ParkingGraphFactory.waypointNodeId(i);
        expect(graph.containsVertex(wpId), isTrue);
        final wp = graph.getVertex(wpId)!;
        expect(wp.type, equals(GraphNodeType.aisleWaypoint));
        expect(wp.x, equals(6.0 + 3.0 * (i - 1)));
        expect(wp.y, equals(8.0));
        expect(wp.floor, equals(1));
      }

      // 3. 20 Parking slot nodes
      // Row A: P01 - P10
      for (int i = 1; i <= 10; i++) {
        final slotId = ParkingGraphFactory.slotNodeId(i);
        expect(graph.containsVertex(slotId), isTrue);
        final slot = graph.getVertex(slotId)!;
        expect(slot.type, equals(GraphNodeType.parkingSlot));
        expect(slot.x, equals(6.0 + 3.0 * (i - 1)));
        expect(slot.y, equals(13.5));
        expect(slot.floor, equals(1));
      }

      // Row B: P11 - P20
      for (int i = 1; i <= 10; i++) {
        final slotId = ParkingGraphFactory.slotNodeId(i + 10);
        expect(graph.containsVertex(slotId), isTrue);
        final slot = graph.getVertex(slotId)!;
        expect(slot.type, equals(GraphNodeType.parkingSlot));
        expect(slot.x, equals(6.0 + 3.0 * (i - 1)));
        expect(slot.y, equals(2.5));
        expect(slot.floor, equals(1));
      }
    });

    test('aisle backbone is connected with 3.0m intervals', () {
      // Entrance -> W01 is 4.0m
      expect(graph.hasEdge('NODE_ENTRANCE', 'NODE_W01'), isTrue);
      expect(graph.hasEdge('NODE_W01', 'NODE_ENTRANCE'), isTrue);
      final entEdges = graph.getAdjacentEdges('NODE_ENTRANCE');
      expect(entEdges.length, equals(1));
      expect(entEdges.first.weight, equals(4.0));

      // W_i <-> W_{i+1} is 3.0m
      for (int i = 1; i <= 9; i++) {
        final current = ParkingGraphFactory.waypointNodeId(i);
        final next = ParkingGraphFactory.waypointNodeId(i + 1);
        expect(graph.hasEdge(current, next), isTrue);
        expect(graph.hasEdge(next, current), isTrue);
      }
    });

    test('each waypoint connects to its opposing Row A and Row B slots with 5.5m weight', () {
      for (int i = 1; i <= 10; i++) {
        final wp = ParkingGraphFactory.waypointNodeId(i);
        final slotA = ParkingGraphFactory.slotNodeId(i);
        final slotB = ParkingGraphFactory.slotNodeId(i + 10);

        expect(graph.hasEdge(wp, slotA), isTrue);
        expect(graph.hasEdge(slotA, wp), isTrue);
        expect(graph.hasEdge(wp, slotB), isTrue);
        expect(graph.hasEdge(slotB, wp), isTrue);

        final edgeA = graph.getAdjacentEdges(wp).firstWhere((e) => e.targetNodeId == slotA);
        expect(edgeA.weight, equals(5.5));

        final edgeB = graph.getAdjacentEdges(wp).firstWhere((e) => e.targetNodeId == slotB);
        expect(edgeB.weight, equals(5.5));
      }
    });
  });

  group('ParkingGraphFactory - Shortest-Path Route Verifications', () {
    late WeightedGraph graph;

    setUp(() {
      graph = ParkingGraphFactory.createFacilityGraph();
    });

    test('every parking slot is reachable from entrance', () {
      final allShortest = Dijkstra.computeAllShortestPaths(
        graph,
        ParkingGraphFactory.entranceNodeId,
      );

      for (int i = 1; i <= 20; i++) {
        final slotId = ParkingGraphFactory.slotNodeId(i);
        expect(
          allShortest.allDistances.containsKey(slotId),
          isTrue,
          reason: '$slotId must be reachable from entrance',
        );
        expect(allShortest.getDistanceTo(slotId), isNotNull);
        final path = allShortest.getPathTo(slotId);
        expect(path.first, equals('NODE_ENTRANCE'));
        expect(path.last, equals(slotId));
      }
    });

    test('satisfies closed-form distance formula for all 20 bays: d = 9.5 + 3.0 * (i - 1)', () {
      for (int i = 1; i <= 10; i++) {
        final expectedDistance = 9.5 + 3.0 * (i - 1);

        // Row A: P01 to P10
        final slotA = ParkingGraphFactory.slotNodeId(i);
        final resultA = Dijkstra.findShortestPath(
          graph,
          ParkingGraphFactory.entranceNodeId,
          slotA,
        );
        expect(resultA.hasPath, isTrue);
        expect(resultA.distance, equals(expectedDistance));

        // Row B: P11 to P20
        final slotB = ParkingGraphFactory.slotNodeId(i + 10);
        final resultB = Dijkstra.findShortestPath(
          graph,
          ParkingGraphFactory.entranceNodeId,
          slotB,
        );
        expect(resultB.hasPath, isTrue);
        expect(resultB.distance, equals(expectedDistance));
      }
    });

    test('verifies specific route to Slot P04 per PARKING_FACILITY_DESIGN.md Verification 1', () {
      final result = Dijkstra.findShortestPath(
        graph,
        ParkingGraphFactory.entranceNodeId,
        'NODE_P04',
      );

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(18.5));
      expect(result.path, equals([
        'NODE_ENTRANCE',
        'NODE_W01',
        'NODE_W02',
        'NODE_W03',
        'NODE_W04',
        'NODE_P04',
      ]));
    });

    test('verifies specific route to Slot P08 per PARKING_FACILITY_DESIGN.md Verification 2', () {
      final result = Dijkstra.findShortestPath(
        graph,
        ParkingGraphFactory.entranceNodeId,
        'NODE_P08',
      );

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(30.5));
      expect(result.path, equals([
        'NODE_ENTRANCE',
        'NODE_W01',
        'NODE_W02',
        'NODE_W03',
        'NODE_W04',
        'NODE_W05',
        'NODE_W06',
        'NODE_W07',
        'NODE_W08',
        'NODE_P08',
      ]));
    });

    test('verifies specific route to Slot P11 (Row B South closest bay)', () {
      final result = Dijkstra.findShortestPath(
        graph,
        ParkingGraphFactory.entranceNodeId,
        'NODE_P11',
      );

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(9.5));
      expect(result.path, equals([
        'NODE_ENTRANCE',
        'NODE_W01',
        'NODE_P11',
      ]));
    });

    test('verifies specific route to Slot P20 (Row B South furthest bay)', () {
      final result = Dijkstra.findShortestPath(
        graph,
        ParkingGraphFactory.entranceNodeId,
        'NODE_P20',
      );

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(36.5));
      expect(result.path, equals([
        'NODE_ENTRANCE',
        'NODE_W01',
        'NODE_W02',
        'NODE_W03',
        'NODE_W04',
        'NODE_W05',
        'NODE_W06',
        'NODE_W07',
        'NODE_W08',
        'NODE_W09',
        'NODE_W10',
        'NODE_P20',
      ]));
    });
  });

  group('ParkingGraphFactory - Node ID Mapping & Candidate Heap Integration', () {
    late WeightedGraph graph;

    setUp(() {
      graph = ParkingGraphFactory.createFacilityGraph();
    });

    test('slotCodeToNodeId and nodeIdToSlotCode bidirectional conversion', () {
      expect(ParkingGraphFactory.slotCodeToNodeId('P01'), equals('NODE_P01'));
      expect(ParkingGraphFactory.slotCodeToNodeId('p05'), equals('NODE_P05'));
      expect(ParkingGraphFactory.slotCodeToNodeId('NODE_P12'), equals('NODE_P12'));

      expect(ParkingGraphFactory.nodeIdToSlotCode('NODE_P01'), equals('P01'));
      expect(ParkingGraphFactory.nodeIdToSlotCode('NODE_P15'), equals('P15'));
      expect(ParkingGraphFactory.nodeIdToSlotCode('P20'), equals('P20'));
    });

    test('buildCandidates calculates Dijkstra route distances and feeds CustomMinHeap', () {
      final slots = [
        ParkingSlot(id: 'P05', row: SlotRow.a, navigationNodeId: 'NODE_P05'),
        ParkingSlot(id: 'P01', row: SlotRow.a, navigationNodeId: 'NODE_P01'),
        ParkingSlot(id: 'P11', row: SlotRow.b, navigationNodeId: 'NODE_P11'),
        ParkingSlot(id: 'P02', row: SlotRow.a, navigationNodeId: 'NODE_P02'),
      ];

      final candidates = ParkingGraphFactory.buildCandidates(
        graph: graph,
        slots: slots,
      );

      expect(candidates.length, equals(4));

      // Build min-heap for recommendations
      final heap = CustomMinHeap<ParkingSlotCandidate>();
      for (final candidate in candidates) {
        heap.insert(candidate);
      }

      // 1. First extracted: P01 (distance 9.5m, tie-break before P11)
      final first = heap.extractMin()!;
      expect(first.slot.slotCode, equals('P01'));
      expect(first.distance, equals(9.5));

      // 2. Second extracted: P11 (distance 9.5m)
      final second = heap.extractMin()!;
      expect(second.slot.slotCode, equals('P11'));
      expect(second.distance, equals(9.5));

      // 3. Third extracted: P02 (distance 12.5m)
      final third = heap.extractMin()!;
      expect(third.slot.slotCode, equals('P02'));
      expect(third.distance, equals(12.5));

      // 4. Fourth extracted: P05 (distance 21.5m)
      final fourth = heap.extractMin()!;
      expect(fourth.slot.slotCode, equals('P05'));
      expect(fourth.distance, equals(21.5));

      expect(heap.isEmpty, isTrue);
    });
  });
}
