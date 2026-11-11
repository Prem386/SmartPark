import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/dsa/graph/dijkstra.dart';
import 'package:smartpark_app/dsa/graph/parking_graph_factory.dart';
import 'package:smartpark_app/dsa/graph/weighted_graph.dart';
import 'package:smartpark_app/features/navigation/facility_navigation_screen.dart';
import 'package:smartpark_app/features/navigation/widgets/destination_selector_bar.dart';
import 'package:smartpark_app/features/navigation/widgets/facility_route_painter.dart';
import 'package:smartpark_app/features/navigation/widgets/navigation_facility_layout.dart';
import 'package:smartpark_app/features/navigation/widgets/navigation_route_card.dart';
import 'package:smartpark_app/features/parking/widgets/parking_slot_tile.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/parking_navigation_service.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildTestableScreen(
    SmartParkController controller, {
    String? initialSlotCode,
  }) {
    return SmartParkScope(
      controller: controller,
      child: MaterialApp(
        home: FacilityNavigationScreen(initialSlotCode: initialSlotCode),
      ),
    );
  }

  group('Phase 3.3 - Navigation Service & Dijkstra Integration Logic', () {
    late ParkingNavigationService navService;
    late WeightedGraph graph;

    setUp(() {
      graph = ParkingGraphFactory.createFacilityGraph();
      navService = ParkingNavigationService(graph: graph);
    });

    test('selecting a valid destination calculates a valid shortest path', () {
      final route = navService.getRouteToSlotCode('P01');

      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);
      expect(route.sourceNodeId, 'NODE_ENTRANCE');
      expect(route.targetNodeId, 'NODE_P01');
      expect(route.distance, closeTo(9.5, 0.001));
      expect(route.path, ['NODE_ENTRANCE', 'NODE_W01', 'NODE_P01']);
    });

    test('route begins at entrance and terminates at selected bay', () {
      final routeP04 = navService.getRouteToSlotCode('P04');

      expect(routeP04, isNotNull);
      expect(routeP04!.path.first, 'NODE_ENTRANCE');
      expect(routeP04.path.last, 'NODE_P04');

      final routeP18 = navService.getRouteToSlotCode('P18');
      expect(routeP18, isNotNull);
      expect(routeP18!.path.first, 'NODE_ENTRANCE');
      expect(routeP18.path.last, 'NODE_P18');
    });

    test('returned distance strictly matches authoritative Dijkstra result', () {
      for (int i = 1; i <= 10; i++) {
        final codeA = 'P${i.toString().padLeft(2, '0')}';
        final nodeA = 'NODE_$codeA';
        final dijkstraDirectA = Dijkstra.findShortestPath(graph, 'NODE_ENTRANCE', nodeA);
        final serviceRouteA = navService.getRouteToSlotCode(codeA);

        expect(serviceRouteA!.distance, dijkstraDirectA.distance);
        expect(serviceRouteA.path, dijkstraDirectA.path);

        final codeB = 'P${i + 10}';
        final nodeB = 'NODE_$codeB';
        final dijkstraDirectB = Dijkstra.findShortestPath(graph, 'NODE_ENTRANCE', nodeB);
        final serviceRouteB = navService.getRouteToSlotCode(codeB);

        expect(serviceRouteB!.distance, dijkstraDirectB.distance);
        expect(serviceRouteB.path, dijkstraDirectB.path);
      }
    });

    test('changing destinations updates route cleanly', () {
      final route1 = navService.getRouteToSlotCode('P01');
      expect(route1!.targetNodeId, 'NODE_P01');
      expect(route1.distance, 9.5);

      final route2 = navService.getRouteToSlotCode('P08');
      expect(route2!.targetNodeId, 'NODE_P08');
      expect(route2.distance, 30.5);
      expect(route2.path.length, 10);
    });

    test('invalid destinations return null safely', () {
      final invalidRoute = navService.getRouteToSlotCode('P99');
      expect(invalidRoute, isNull);

      final unknownNodeRoute = navService.findRoute(
        fromNodeId: 'NODE_ENTRANCE',
        toNodeId: 'NODE_UNKNOWN',
      );
      expect(unknownNodeRoute, isNull);
    });

    test('unreachable destination returns route with hasPath false and infinite distance', () {
      // Create disconnected graph with isolated node
      final isolatedGraph = ParkingGraphFactory.createFacilityGraph();
      // Remove all edges connected to W01
      isolatedGraph.removeEdge('NODE_ENTRANCE', 'NODE_W01');

      final disconnectedService = ParkingNavigationService(graph: isolatedGraph);
      final unreachableRoute = disconnectedService.getRouteToSlotCode('P04');

      expect(unreachableRoute, isNotNull);
      expect(unreachableRoute!.hasPath, isFalse);
      expect(unreachableRoute.distance, double.infinity);
      expect(unreachableRoute.path, isEmpty);
    });
  });

  group('Phase 3.3 - FacilityRoutePainter Geometry & Logic', () {
    test('getNodeOffset maps all 31 facility nodes correctly', () {
      expect(FacilityRoutePainter.getNodeOffset('NODE_ENTRANCE'), const Offset(41.0, 150.0));

      // Waypoints along aisle (Y = 150.0)
      expect(FacilityRoutePainter.getNodeOffset('NODE_W01'), const Offset(141.0, 150.0));
      expect(FacilityRoutePainter.getNodeOffset('NODE_W02'), const Offset(243.0, 150.0));
      expect(FacilityRoutePainter.getNodeOffset('NODE_W10'), const Offset(1059.0, 150.0));

      // Row A bays (Y = 52.0)
      expect(FacilityRoutePainter.getNodeOffset('NODE_P01'), const Offset(141.0, 52.0));
      expect(FacilityRoutePainter.getNodeOffset('NODE_P10'), const Offset(1059.0, 52.0));

      // Row B bays (Y = 248.0)
      expect(FacilityRoutePainter.getNodeOffset('NODE_P11'), const Offset(141.0, 248.0));
      expect(FacilityRoutePainter.getNodeOffset('NODE_P20'), const Offset(1059.0, 248.0));
    });

    test('facilityEdges contains exactly 30 authoritative edges', () {
      expect(FacilityRoutePainter.facilityEdges.length, 30);
      expect(FacilityRoutePainter.facilityEdges.first, ('NODE_ENTRANCE', 'NODE_W01'));
      expect(FacilityRoutePainter.facilityEdges.last, ('NODE_W10', 'NODE_P20'));
    });

    test('calculateArrowPosition positions vertical arrows in card gaps and horizontal arrows at midpoints', () {
      // Horizontal segment: Entrance -> W01 (Y = 150.0)
      final pEntrance = FacilityRoutePainter.getNodeOffset('NODE_ENTRANCE'); // (41.0, 150.0)
      final pW01 = FacilityRoutePainter.getNodeOffset('NODE_W01'); // (141.0, 150.0)
      final horizontalArrow = FacilityRoutePainter.calculateArrowPosition(pEntrance, pW01);
      expect(horizontalArrow, const Offset(91.0, 150.0));

      // Vertical segment: W04 -> P04 (Row A, North)
      final pW04 = FacilityRoutePainter.getNodeOffset('NODE_W04'); // (447.0, 150.0)
      final pP04 = FacilityRoutePainter.getNodeOffset('NODE_P04'); // (447.0, 52.0)
      final verticalArrowA = FacilityRoutePainter.calculateArrowPosition(pW04, pP04);
      expect(verticalArrowA, const Offset(447.0, FacilityRoutePainter.rowAGapCenterY));
      expect(verticalArrowA.dy, 114.0);

      // Vertical segment: W04 -> P14 (Row B, South)
      final pP14 = FacilityRoutePainter.getNodeOffset('NODE_P14'); // (447.0, 248.0)
      final verticalArrowB = FacilityRoutePainter.calculateArrowPosition(pW04, pP14);
      expect(verticalArrowB, const Offset(447.0, FacilityRoutePainter.rowBGapCenterY));
      expect(verticalArrowB.dy, 186.0);
    });
  });

  group('Phase 3.3 - FacilityNavigationScreen Widget Tests', () {
    testWidgets('renders screen shell, header, selector bar, layout, and empty state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Title & header checks
      expect(find.text('Facility Navigation'), findsOneWidget);
      expect(find.text('Facility Navigation (Floor 1)'), findsOneWidget);
      expect(
        find.text('Shortest-path routing via custom Weighted Graph & Dijkstra algorithm'),
        findsOneWidget,
      );

      // Destination selector
      expect(find.byType(DestinationSelectorBar), findsOneWidget);
      expect(find.text('Select Destination Bay'), findsOneWidget);
      expect(find.text('Choose a parking bay (P01 – P20)...'), findsOneWidget);

      // Facility map layout
      expect(find.byType(NavigationFacilityLayout), findsOneWidget);
      expect(find.text('ROW A (NORTH)'), findsOneWidget);
      expect(find.text('ROW B (SOUTH)'), findsOneWidget);
      expect(find.text('ENTRY'), findsOneWidget);
      expect(find.text('W01'), findsOneWidget);
      expect(find.text('W10'), findsOneWidget);

      // Empty state prompt
      expect(find.byType(NavigationRouteCard), findsOneWidget);
      expect(find.text('No Destination Selected'), findsOneWidget);
      expect(
        find.text(
          'Select a parking bay from the layout above or use the selector to calculate the shortest path from the entrance.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('initialSlotCode constructor parameter pre-calculates route',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P04'));
      await tester.pumpAndSettle();

      // Check destination and distance
      expect(find.text('Destination: Bay P04'), findsOneWidget);
      expect(find.text('18.5m'), findsOneWidget);
      expect(find.text('5 links'), findsOneWidget);
      expect(find.text('Entrance (2.0m)'), findsOneWidget);

      // Verify turn-by-turn waypoints
      expect(find.text('Start at Main Entrance'), findsOneWidget);
      expect(find.text('Aisle Waypoint 1'), findsOneWidget);
      expect(find.text('Aisle Waypoint 2'), findsOneWidget);
      expect(find.text('Aisle Waypoint 3'), findsOneWidget);
      expect(find.text('Aisle Waypoint 4'), findsOneWidget);
      expect(find.text('Arrive at Slot P04 (Row A)'), findsOneWidget);

      // Verify Entrance marked as START
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('selecting bay via quick chip calculates route and updates display',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Initially empty
      expect(find.text('No Destination Selected'), findsOneWidget);

      // Tap Quick Chip P01
      await tester.tap(find.widgetWithText(ChoiceChip, 'P01'));
      await tester.pumpAndSettle();

      // Verify calculated route to P01
      expect(find.text('Destination: Bay P01'), findsOneWidget);
      expect(find.text('9.5m'), findsOneWidget);
      expect(find.text('2 links'), findsOneWidget);
      expect(find.text('Start at Main Entrance'), findsOneWidget);
      expect(find.text('Aisle Waypoint 1'), findsOneWidget);
      expect(find.text('Arrive at Slot P01 (Row A)'), findsOneWidget);
    });

    testWidgets('tapping bay tile directly on facility layout calculates route',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap P11 on the facility layout
      await tester.ensureVisible(find.widgetWithText(ParkingSlotTile, 'P11'));
      await tester.tap(find.widgetWithText(ParkingSlotTile, 'P11'));
      await tester.pumpAndSettle();

      // Verify calculated route to P11 (Row B)
      expect(find.text('Destination: Bay P11'), findsOneWidget);
      expect(find.text('9.5m'), findsOneWidget);
      expect(find.text('Row B (South) • Floor 1'), findsOneWidget);
      expect(find.text('Arrive at Slot P11 (Row B)'), findsOneWidget);
    });

    testWidgets('changing destination updates route and clears previous route without reload',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap P01
      await tester.tap(find.widgetWithText(ChoiceChip, 'P01'));
      await tester.pumpAndSettle();
      expect(find.text('Destination: Bay P01'), findsOneWidget);
      expect(find.text('9.5m'), findsOneWidget);

      // Switch to P04
      await tester.tap(find.widgetWithText(ChoiceChip, 'P04'));
      await tester.pumpAndSettle();
      expect(find.text('Destination: Bay P04'), findsOneWidget);
      expect(find.text('18.5m'), findsOneWidget);
      expect(find.text('Destination: Bay P01'), findsNothing);

      // Switch to P10
      await tester.tap(find.widgetWithText(ChoiceChip, 'P10'));
      await tester.pumpAndSettle();
      expect(find.text('Destination: Bay P10'), findsOneWidget);
      expect(find.text('36.5m'), findsOneWidget);
      expect(find.text('Destination: Bay P04'), findsNothing);
    });

    testWidgets('clearing route resets screen cleanly to empty state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P04'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P04'), findsOneWidget);

      // Tap Clear button in route card
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Clear'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
      await tester.pumpAndSettle();

      // Verified reset to empty state
      expect(find.text('No Destination Selected'), findsOneWidget);
      expect(find.text('Destination: Bay P04'), findsNothing);

      // Entrance returned to ENTRY
      expect(find.text('ENTRY'), findsOneWidget);
    });

    testWidgets('app bar clear action also resets destination and route',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P01'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P01'), findsOneWidget);

      // Tap app bar refresh/clear button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('No Destination Selected'), findsOneWidget);
    });

    testWidgets('selector dropdown selection calculates route correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap dropdown to open menu
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Tap dropdown item P02
      await tester.tap(find.text('Bay P02').last);
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P02'), findsOneWidget);
      expect(find.text('12.5m'), findsOneWidget);
    });

    testWidgets('optimal recommendation chip calculates route to top candidate',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Optimal chip is P01
      expect(find.text('Optimal: P01'), findsOneWidget);

      await tester.tap(find.text('Optimal: P01'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P01'), findsOneWidget);
      expect(find.text('9.5m'), findsOneWidget);
    });

    testWidgets('rebuilds dynamically when slot status in controller mutates',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P01'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P01'), findsOneWidget);

      // Mutate P01 in controller to occupied
      controller.updateSlotStatus('P01', SlotStatus.occupied);
      await tester.pump();

      // Bay tile in layout displays updated status
      expect(find.widgetWithText(ParkingSlotTile, 'P01'), findsOneWidget);
    });
  });
}
