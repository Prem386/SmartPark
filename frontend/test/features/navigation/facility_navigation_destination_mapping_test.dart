import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/data/local/smartpark_local_data.dart';
import 'package:smartpark_app/dsa/graph/parking_graph_factory.dart';
import 'package:smartpark_app/features/navigation/facility_navigation_screen.dart';
import 'package:smartpark_app/features/navigation/widgets/facility_route_painter.dart';
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

  group('Regression Test 1 — Randomized destination order', () {
    test('existing facility layout has randomized collection order where P01 is not first', () {
      final controller = SmartParkController();
      final allSlots = controller.slotService.getAllSlots();
      final rowASlots = allSlots.where((s) => s.row == SlotRow.a).toList();

      // P06 is first in Row A, not P01
      expect(rowASlots.first.slotCode, 'P06');
      expect(rowASlots[0].slotCode, 'P06');

      // P01 appears later in the collection (index 6)
      final p01Index = rowASlots.indexWhere((s) => s.slotCode == 'P01');
      expect(p01Index, isNot(0));
      expect(p01Index, 6);
    });

    test('FacilityRoutePainter resolves P01 to its actual visual position, not P06', () {
      final controller = SmartParkController();
      final allSlots = controller.slotService.getAllSlots();
      final rowASlots = allSlots.where((s) => s.row == SlotRow.a).toList();
      final rowBSlots = allSlots.where((s) => s.row == SlotRow.b).toList();

      final painter = FacilityRoutePainter(
        rowASlots: rowASlots,
        rowBSlots: rowBSlots,
      );

      // P01 is at index 6 in Row A -> visual coordinate is Offset(141.0 + 6 * 102.0, 52.0) = Offset(753.0, 52.0)
      final p01Offset = painter.resolveNodeOffset('NODE_P01');
      expect(p01Offset, const Offset(753.0, 52.0));

      // P06 is at index 0 in Row A -> visual coordinate is Offset(141.0 + 0 * 102.0, 52.0) = Offset(141.0, 52.0)
      final p06Offset = painter.resolveNodeOffset('NODE_P06');
      expect(p06Offset, const Offset(141.0, 52.0));

      // Verify that P01 and P06 do not share endpoints
      expect(p01Offset, isNot(p06Offset));
    });

    testWidgets('widget test: selecting P01 renders route terminating at P01 tile coordinate',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Select P01 via quick chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'P01'));
      await tester.pumpAndSettle();

      // Find the CustomPaint with FacilityRoutePainter
      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is FacilityRoutePainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaintWidget.painter as FacilityRoutePainter;

      expect(painter.route, isNotNull);
      expect(painter.route!.targetNodeId, 'NODE_P01');
      expect(painter.rowASlots, isNotNull);

      // Endpoint must resolve to P01's visual coordinate Offset(753.0, 52.0), not Offset(141.0, 52.0)
      final routeEndpoint = painter.resolveNodeOffset(painter.route!.targetNodeId);
      expect(routeEndpoint, const Offset(753.0, 52.0));
      expect(routeEndpoint, isNot(const Offset(141.0, 52.0)));
    });
  });

  group('Regression Test 2 — Multiple destinations', () {
    test('verifies correct route endpoints for P01, P06, P10, P17, and P20', () {
      final controller = SmartParkController();
      final allSlots = controller.slotService.getAllSlots();
      final rowASlots = allSlots.where((s) => s.row == SlotRow.a).toList();
      final rowBSlots = allSlots.where((s) => s.row == SlotRow.b).toList();

      final painter = FacilityRoutePainter(
        rowASlots: rowASlots,
        rowBSlots: rowBSlots,
      );

      // Verify collection indices do NOT equal IDs
      final idxP01 = rowASlots.indexWhere((s) => s.slotCode == 'P01');
      final idxP06 = rowASlots.indexWhere((s) => s.slotCode == 'P06');
      final idxP10 = rowASlots.indexWhere((s) => s.slotCode == 'P10');
      final idxP17 = rowBSlots.indexWhere((s) => s.slotCode == 'P17');
      final idxP20 = rowBSlots.indexWhere((s) => s.slotCode == 'P20');

      expect(idxP01, 6);
      expect(idxP06, 0);
      expect(idxP10, 4);
      expect(idxP17, 0);
      expect(idxP20, 1);

      // Verify route endpoints match actual layout coordinates
      expect(painter.resolveNodeOffset('NODE_P01'), Offset(141.0 + idxP01 * 102.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P06'), Offset(141.0 + idxP06 * 102.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P10'), Offset(141.0 + idxP10 * 102.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P17'), Offset(141.0 + idxP17 * 102.0, 248.0));
      expect(painter.resolveNodeOffset('NODE_P20'), Offset(141.0 + idxP20 * 102.0, 248.0));

      expect(painter.resolveNodeOffset('NODE_P01'), const Offset(753.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P06'), const Offset(141.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P10'), const Offset(549.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P17'), const Offset(141.0, 248.0));
      expect(painter.resolveNodeOffset('NODE_P20'), const Offset(243.0, 248.0));
    });
  });

  group('Regression Test 3 — Reordered collection', () {
    test('reversed collection preserves correct route endpoints for all destinations', () {
      final controller = SmartParkController();
      final allSlots = controller.slotService.getAllSlots();
      final reversedRowA = allSlots.where((s) => s.row == SlotRow.a).toList().reversed.toList();
      final reversedRowB = allSlots.where((s) => s.row == SlotRow.b).toList().reversed.toList();

      final painter = FacilityRoutePainter(
        rowASlots: reversedRowA,
        rowBSlots: reversedRowB,
      );

      for (final slot in [...reversedRowA, ...reversedRowB]) {
        final expectedY = slot.row == SlotRow.a ? 52.0 : 248.0;
        final list = slot.row == SlotRow.a ? reversedRowA : reversedRowB;
        final idx = list.indexOf(slot);
        final expectedOffset = Offset(141.0 + idx * 102.0, expectedY);

        expect(painter.resolveNodeOffset(slot.navigationNodeId!), expectedOffset);
      }
    });

    test('arbitrary shuffled permutations maintain 100% correct route endpoints', () {
      final slots = SmartParkLocalData.createInitialSlots();
      final rowA = slots.where((s) => s.row == SlotRow.a).toList();
      final rowB = slots.where((s) => s.row == SlotRow.b).toList();

      // Test 5 deterministic permutations of 0..9
      final permutations = [
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0], // Inverted
        [3, 1, 4, 2, 5, 9, 7, 6, 8, 0], // Mixed indices
        [5, 6, 7, 8, 9, 0, 1, 2, 3, 4], // Shifted by 5
        [2, 4, 6, 8, 0, 1, 3, 5, 7, 9], // Evens then odds
        [8, 3, 1, 7, 0, 9, 2, 5, 4, 6], // Scrambled
      ];

      for (final perm in permutations) {
        final permRowA = List.generate(10, (i) => rowA[perm[i]]);
        final permRowB = List.generate(10, (i) => rowB[perm[i]]);

        final painter = FacilityRoutePainter(
          rowASlots: permRowA,
          rowBSlots: permRowB,
        );

        for (final code in ['P01', 'P06', 'P10', 'P17', 'P20']) {
          final isRowA = int.parse(code.substring(1)) <= 10;
          final targetList = isRowA ? permRowA : permRowB;
          final targetIdx = targetList.indexWhere((s) => s.slotCode == code);
          final expectedY = isRowA ? 52.0 : 248.0;
          final expectedOffset = Offset(141.0 + targetIdx * 102.0, expectedY);

          final resolved = painter.resolveNodeOffset('NODE_$code');
          expect(resolved, expectedOffset);
        }
      }
    });
  });

  group('Regression Test 4 — Source and destination consistency', () {
    test('routes to all 20 bays start at entrance, end at destination, and contain valid edges', () {
      final navService = ParkingNavigationService();
      final graph = navService.graph;

      for (int i = 1; i <= 20; i++) {
        final slotCode = 'P${i.toString().padLeft(2, '0')}';
        final route = navService.getRouteToSlotCode(slotCode);

        expect(route, isNotNull);
        expect(route!.hasPath, isTrue);
        expect(route.sourceNodeId, ParkingGraphFactory.entranceNodeId);
        expect(route.targetNodeId, 'NODE_$slotCode');
        expect(route.path.first, ParkingGraphFactory.entranceNodeId);
        expect(route.path.last, 'NODE_$slotCode');

        // Verify every consecutive hop is a valid connected edge in the graph
        for (int hop = 0; hop < route.path.length - 1; hop++) {
          final u = route.path[hop];
          final v = route.path[hop + 1];
          final hasEdge = graph.hasEdge(u, v);
          expect(
            hasEdge,
            isTrue,
            reason: 'Hop from $u to $v in route to $slotCode must be a connected graph edge.',
          );
        }
      }
    });
  });

  group('Regression Test 5 — Existing functionality', () {
    testWidgets('quick chips, dropdown, route card distance, and clear button continue working',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // 1. Initial empty state
      expect(find.text('No Destination Selected'), findsOneWidget);

      // 2. Select P04 via quick chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'P04'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P04'), findsOneWidget);
      expect(find.text('18.5m'), findsOneWidget);
      expect(find.text('5 links'), findsOneWidget);

      // 3. Clear route
      final clearFinder = find.widgetWithText(OutlinedButton, 'Clear');
      await tester.ensureVisible(clearFinder);
      await tester.tap(clearFinder);
      await tester.pumpAndSettle();
      expect(find.text('No Destination Selected'), findsOneWidget);

      // 4. Select P08 via direct layout tile tap
      final p08Finder = find.widgetWithText(ParkingSlotTile, 'P08').first;
      await tester.ensureVisible(p08Finder);
      await tester.tap(p08Finder);
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P08'), findsOneWidget);
      expect(find.text('30.5m'), findsOneWidget);
      expect(find.text('9 links'), findsOneWidget);

      // 5. Select P12 via dropdown
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdownFinder);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bay P12').last);
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P12'), findsOneWidget);
      expect(find.text('12.5m'), findsOneWidget);
      expect(find.text('3 links'), findsOneWidget);
    });
  });
}
