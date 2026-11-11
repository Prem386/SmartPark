import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/data/local/smartpark_local_data.dart';
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

  group('Physical Layout Invariants — Row and Waypoint Alignment', () {
    const painter = FacilityRoutePainter();

    test('1. All Row A bays P01–P10 align vertically with W01–W10', () {
      for (int i = 1; i <= 10; i++) {
        final slotCode = 'P${i.toString().padLeft(2, '0')}';
        final waypointCode = 'W${i.toString().padLeft(2, '0')}';

        final slotOffset = painter.resolveNodeOffset('NODE_$slotCode');
        final waypointOffset = painter.resolveNodeOffset('NODE_$waypointCode');

        expect(slotOffset.dx, equals(waypointOffset.dx),
            reason: '$slotCode must align horizontally with $waypointCode');
        expect(slotOffset.dy, equals(52.0),
            reason: '$slotCode must be positioned on Row A (North) at Y=52.0');
        expect(waypointOffset.dy, equals(150.0),
            reason: '$waypointCode must be positioned on Central Aisle at Y=150.0');
      }
    });

    test('2. All Row B bays P11–P20 align vertically with W01–W10', () {
      for (int i = 1; i <= 10; i++) {
        final slotCode = 'P${(i + 10).toString().padLeft(2, '0')}';
        final waypointCode = 'W${i.toString().padLeft(2, '0')}';

        final slotOffset = painter.resolveNodeOffset('NODE_$slotCode');
        final waypointOffset = painter.resolveNodeOffset('NODE_$waypointCode');

        expect(slotOffset.dx, equals(waypointOffset.dx),
            reason: '$slotCode must align horizontally with $waypointCode');
        expect(slotOffset.dy, equals(248.0),
            reason: '$slotCode must be positioned on Row B (South) at Y=248.0');
        expect(waypointOffset.dy, equals(150.0),
            reason: '$waypointCode must be positioned on Central Aisle at Y=150.0');
      }
    });

    test('3. P20 resolves to (1059, 248) and W10 to (1059, 150)', () {
      final p20Offset = painter.resolveNodeOffset('NODE_P20');
      final w10Offset = painter.resolveNodeOffset('NODE_W10');

      expect(p20Offset, const Offset(1059.0, 248.0));
      expect(w10Offset, const Offset(1059.0, 150.0));
      expect(p20Offset.dx, equals(w10Offset.dx));
    });

    test('4. P19 resolves to (957, 248) and W09 to (957, 150)', () {
      final p19Offset = painter.resolveNodeOffset('NODE_P19');
      final w09Offset = painter.resolveNodeOffset('NODE_W09');

      expect(p19Offset, const Offset(957.0, 248.0));
      expect(w09Offset, const Offset(957.0, 150.0));
      expect(p19Offset.dx, equals(w09Offset.dx));
    });

    test('5. All 20 parking bays resolve to their canonical physical coordinates', () {
      for (int i = 1; i <= 20; i++) {
        final slotCode = 'P${i.toString().padLeft(2, '0')}';
        final resolved = painter.resolveNodeOffset('NODE_$slotCode');
        final canonical = FacilityRoutePainter.getNodeOffset('NODE_$slotCode');

        expect(resolved, equals(canonical));
        expect(resolved, isNot(equals(Offset.zero)));

        final col = (i <= 10) ? i - 1 : i - 11;
        final expectedX = 141.0 + col * 102.0;
        final expectedY = (i <= 10) ? 52.0 : 248.0;
        expect(resolved, Offset(expectedX, expectedY));
      }
    });

    test('9. P01, P10, P11 and P19 also have correct terminal route coordinates', () {
      expect(painter.resolveNodeOffset('NODE_P01'), const Offset(141.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P10'), const Offset(1059.0, 52.0));
      expect(painter.resolveNodeOffset('NODE_P11'), const Offset(141.0, 248.0));
      expect(painter.resolveNodeOffset('NODE_P19'), const Offset(957.0, 248.0));
    });
  });

  group('Permutation Invariance — HashMap Order Independence', () {
    test('6. The ordering remains correct when the original slot collection is supplied in different HashMap-like permutations', () {
      final slots = SmartParkLocalData.createInitialSlots();
      final rowA = slots.where((s) => s.row == SlotRow.a).toList();
      final rowB = slots.where((s) => s.row == SlotRow.b).toList();

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

        // Every slot must still resolve to its canonical physical coordinate
        for (int i = 1; i <= 20; i++) {
          final slotCode = 'P${i.toString().padLeft(2, '0')}';
          final col = (i <= 10) ? i - 1 : i - 11;
          final expectedOffset = Offset(
            141.0 + col * 102.0,
            (i <= 10) ? 52.0 : 248.0,
          );

          expect(
            painter.resolveNodeOffset('NODE_$slotCode'),
            expectedOffset,
            reason: 'Slot $slotCode must resolve to canonical coordinate regardless of collection permutation',
          );
        }
      }
    });
  });

  group('Dijkstra Route Geometry & Aisle Traversal Invariants', () {
    late ParkingNavigationService navService;

    setUp(() {
      navService = ParkingNavigationService();
    });

    test('7. P20 Dijkstra route contains no unrelated parking bay nodes', () {
      final routeP20 = navService.getRouteToSlotCode('P20');
      expect(routeP20, isNotNull);
      expect(routeP20!.hasPath, isTrue);

      final expectedPath = [
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
      ];
      expect(routeP20.path, equals(expectedPath));

      // Assert no other parking bay appears in the path
      for (final node in routeP20.path) {
        if (node.startsWith('NODE_P')) {
          expect(node, equals('NODE_P20'));
        }
      }
    });

    test('8. The final P20 route segment connects W10 directly to P20 without horizontal aisle backtracking', () {
      final routeP20 = navService.getRouteToSlotCode('P20')!;
      const painter = FacilityRoutePainter();

      final w10Offset = painter.resolveNodeOffset('NODE_W10');
      final p20Offset = painter.resolveNodeOffset('NODE_P20');

      expect(w10Offset, const Offset(1059.0, 150.0));
      expect(p20Offset, const Offset(1059.0, 248.0));

      // Direct collinear vertical segment: dx must be 0
      final dx = p20Offset.dx - w10Offset.dx;
      final dy = p20Offset.dy - w10Offset.dy;
      expect(dx, equals(0.0), reason: 'Final segment must be strictly vertical, no horizontal backtracking');
      expect(dy, equals(98.0), reason: 'Travels directly south from aisle to bay center');

      // Monotonic X invariant across all aisle segments
      double lastX = 0.0;
      for (final nodeId in routeP20.path) {
        final offset = painter.resolveNodeOffset(nodeId);
        expect(offset.dx, greaterThanOrEqualTo(lastX),
            reason: 'Route along aisle must never backtrack westward');
        lastX = offset.dx;
      }
    });
  });

  group('Destination Selection & Route Clearing Widgets', () {
    testWidgets('10. Existing destination selection mechanisms and route clearing continue working',
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

      // 6. Select P20 via quick chip and verify painter endpoint
      await tester.tap(find.widgetWithText(ChoiceChip, 'P20'));
      await tester.pumpAndSettle();

      expect(find.text('Destination: Bay P20'), findsOneWidget);
      expect(find.text('36.5m'), findsOneWidget);
      expect(find.text('11 links'), findsOneWidget);

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is FacilityRoutePainter,
      );
      expect(customPaintFinder, findsOneWidget);
      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaintWidget.painter as FacilityRoutePainter;

      final p20Endpoint = painter.resolveNodeOffset(painter.route!.targetNodeId);
      expect(p20Endpoint, const Offset(1059.0, 248.0));
      expect(p20Endpoint.dx, equals(painter.resolveNodeOffset('NODE_W10').dx));
    });

    testWidgets('selecting P01 renders route terminating at canonical P01 tile coordinate',
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

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is FacilityRoutePainter,
      );
      expect(customPaintFinder, findsOneWidget);

      final customPaintWidget = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaintWidget.painter as FacilityRoutePainter;

      expect(painter.route, isNotNull);
      expect(painter.route!.targetNodeId, 'NODE_P01');

      final routeEndpoint = painter.resolveNodeOffset(painter.route!.targetNodeId);
      expect(routeEndpoint, const Offset(141.0, 52.0));
      expect(routeEndpoint.dx, equals(painter.resolveNodeOffset('NODE_W01').dx));
    });
  });
}
