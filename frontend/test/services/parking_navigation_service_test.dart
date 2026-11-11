import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/graph/graph.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/parking_navigation_service.dart';

void main() {
  group('ParkingNavigationService (Graph + Dijkstra Integration)', () {
    late ParkingNavigationService service;

    setUp(() {
      service = ParkingNavigationService();
    });

    test('initializes with authoritative facility graph (31 vertices, 30 edges)', () {
      expect(service.graph.vertexCount, equals(31));
      expect(service.graph.undirectedEdgeCount, equals(30));
      expect(service.entranceNodeId, equals('NODE_ENTRANCE'));
    });

    test('calculates shortest path and exact distance from entrance to slot', () {
      final slotP04 = ParkingSlot(
        id: 'slot-004',
        slotCode: 'P04',
        row: SlotRow.a,
        navigationNodeId: 'NODE_P04',
      );

      final route = service.getRouteToSlot(slotP04);
      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);
      // d = 4.0 + 3.0 * 3 + 5.5 = 18.5m per PARKING_FACILITY_DESIGN.md Verification 1
      expect(route.distance, equals(18.5));
      expect(route.sourceNodeId, equals('NODE_ENTRANCE'));
      expect(route.targetNodeId, equals('NODE_P04'));
      expect(route.slotCode, equals('P04'));
      expect(
        route.path,
        equals([
          'NODE_ENTRANCE',
          'NODE_W01',
          'NODE_W02',
          'NODE_W03',
          'NODE_W04',
          'NODE_P04',
        ]),
      );
    });

    test('calculates shortest path to slot using slotCode lookup', () {
      final routeP08 = service.getRouteToSlotCode('P08');
      expect(routeP08, isNotNull);
      expect(routeP08!.hasPath, isTrue);
      // d = 4.0 + 3.0 * 7 + 5.5 = 30.5m per PARKING_FACILITY_DESIGN.md Verification 2
      expect(routeP08.distance, equals(30.5));
      expect(routeP08.targetNodeId, equals('NODE_P08'));
      expect(
        routeP08.path,
        equals([
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
        ]),
      );
    });

    test('verifies closed-form distance formula for Row A and Row B closest and furthest bays', () {
      // P01 (Row A closest): 9.5m
      final r01 = service.getRouteToSlotCode('P01')!;
      expect(r01.distance, equals(9.5));

      // P11 (Row B closest): 9.5m
      final r11 = service.getRouteToSlotCode('P11')!;
      expect(r11.distance, equals(9.5));

      // P10 (Row A furthest): 9.5 + 3.0 * 9 = 36.5m
      final r10 = service.getRouteToSlotCode('P10')!;
      expect(r10.distance, equals(36.5));

      // P20 (Row B furthest): 9.5 + 3.0 * 9 = 36.5m
      final r20 = service.getRouteToSlotCode('P20')!;
      expect(r20.distance, equals(36.5));
    });

    test('resolves navigation node using explicit navigationNodeId or falls back to slotCode', () {
      final slotWithExplicitNode = ParkingSlot(
        id: 'slot-custom-1',
        slotCode: 'CUSTOM_BAY',
        row: SlotRow.a,
        navigationNodeId: 'NODE_P01',
      );
      expect(service.resolveNodeId(slotWithExplicitNode), equals('NODE_P01'));

      final slotWithDefault = ParkingSlot(
        id: 'P02',
        row: SlotRow.a,
      );
      expect(service.resolveNodeId(slotWithDefault), equals('NODE_P02'));
    });

    test('handles unknown slot and non-existent graph nodes cleanly', () {
      expect(service.getRouteToSlotCode('P99'), isNull);
      expect(
        service.findRoute(fromNodeId: 'NODE_ENTRANCE', toNodeId: 'NODE_UNKNOWN'),
        isNull,
      );
      expect(
        service.findRoute(fromNodeId: 'NODE_UNKNOWN', toNodeId: 'NODE_P01'),
        isNull,
      );
    });

    test('handles unreachable navigation target in disconnected graph', () {
      final customGraph = ParkingGraphFactory.createFacilityGraph();
      // Add an isolated vertex
      customGraph.addVertex(
        GraphNode(
          id: 'NODE_ISOLATED',
          type: GraphNodeType.parkingSlot,
          label: 'Isolated Slot',
        ),
      );

      final customService = ParkingNavigationService(graph: customGraph);
      final route = customService.findRoute(
        fromNodeId: 'NODE_ENTRANCE',
        toNodeId: 'NODE_ISOLATED',
      );

      expect(route, isNotNull);
      expect(route!.hasPath, isFalse);
      expect(route.distance, equals(double.infinity));
      expect(route.path, isEmpty);
    });

    test('computes distances to all 20 facility parking slots', () {
      final distances = service.getDistancesToAllSlots();
      expect(distances.length, equals(20));

      for (int i = 1; i <= 10; i++) {
        final expectedDist = 9.5 + 3.0 * (i - 1);
        final codeA = 'P${i.toString().padLeft(2, '0')}';
        final codeB = 'P${i + 10}';

        expect(distances[codeA], equals(expectedDist));
        expect(distances[codeB], equals(expectedDist));
      }
    });

    test('findRoute supports arbitrary waypoint-to-waypoint navigation', () {
      final route = service.findRoute(
        fromNodeId: 'NODE_W01',
        toNodeId: 'NODE_W05',
      );
      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);
      // 4 links of 3.0m = 12.0m
      expect(route.distance, equals(12.0));
      expect(
        route.path,
        equals(['NODE_W01', 'NODE_W02', 'NODE_W03', 'NODE_W04', 'NODE_W05']),
      );
    });
  });
}

