import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/features/parking/parking_slots_screen.dart';
import 'package:smartpark_app/features/parking/widgets/parking_slot_details_sheet.dart';
import 'package:smartpark_app/features/parking/widgets/parking_slot_tile.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildTestableScreen(SmartParkController controller) {
    return SmartParkScope(
      controller: controller,
      child: const MaterialApp(
        home: ParkingSlotsScreen(),
      ),
    );
  }

  group('ParkingSlotsScreen - Facility Layout & Rendering', () {
    testWidgets('displays header, facility info, and live metrics',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Header checks
      expect(find.text('Parking Slots'), findsOneWidget);
      expect(find.text('SmartPark Facility (Floor 1)'), findsOneWidget);
      expect(
        find.text('20 standard bays • Two parallel rows • Central driving aisle'),
        findsOneWidget,
      );

      // Live metrics check (12 available, 4 occupied, 2 reserved, 2 maintenance)
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Occupied'), findsWidgets);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Reserved'), findsWidgets);
      expect(find.text('Maintenance'), findsWidgets);
      expect(find.text('2'), findsNWidgets(2));
    });

    testWidgets('renders all 20 bays with Row A (P01-P10) and Row B (P11-P20)',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Verify row headers
      expect(find.text('ROW A (NORTH)'), findsOneWidget);
      expect(find.text('ROW B (SOUTH)'), findsOneWidget);
      expect(find.text('ENTRY'), findsOneWidget);
      expect(find.text('X=2.0m'), findsOneWidget);

      // Verify all 20 bay tiles are in the widget tree
      for (int i = 1; i <= 20; i++) {
        final code = 'P${i.toString().padLeft(2, '0')}';
        expect(find.text(code), findsOneWidget);
      }

      // Verify status of sample slots
      // P01 is available
      final p01Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P01'),
      );
      expect(p01Tile.slot.status, SlotStatus.available);

      // P02 is occupied
      final p02Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P02'),
      );
      expect(p02Tile.slot.status, SlotStatus.occupied);

      // P04 is reserved
      final p04Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P04'),
      );
      expect(p04Tile.slot.status, SlotStatus.reserved);

      // P10 is maintenance
      final p10Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P10'),
      );
      expect(p10Tile.slot.status, SlotStatus.maintenance);
    });

    testWidgets('renders aisle waypoints W01 through W10',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      for (int i = 1; i <= 10; i++) {
        final wp = 'W${i.toString().padLeft(2, '0')}';
        expect(find.text(wp), findsOneWidget);
      }
    });
  });

  group('ParkingSlotsScreen - Slot Selection & Details', () {
    testWidgets('tapping available slot opens bottom sheet with correct data',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap P01
      await tester.tap(find.text('P01'));
      await tester.pumpAndSettle();

      // Check sheet presence
      expect(find.byType(ParkingSlotDetailsSheet), findsOneWidget);
      expect(find.text('Parking Bay P01'), findsOneWidget);
      expect(find.text('Row A (North) • Floor 1'), findsOneWidget);
      expect(find.text('Ready for immediate parking'), findsOneWidget);
      expect(find.text('STANDARD'), findsOneWidget);
      expect(find.text('6.0m, 13.5m'), findsOneWidget);
      expect(find.text('NODE_P01'), findsOneWidget);

      // Close sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Sheet should be gone
      expect(find.byType(ParkingSlotDetailsSheet), findsNothing);
    });

    testWidgets('tapping occupied slot displays unavailable banner and status',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap P02
      await tester.tap(find.text('P02'));
      await tester.pumpAndSettle();

      expect(find.byType(ParkingSlotDetailsSheet), findsOneWidget);
      expect(find.text('Parking Bay P02'), findsOneWidget);
      expect(find.text('Not available for parking (Occupied)'), findsOneWidget);
      expect(find.text('9.0m, 13.5m'), findsOneWidget);
      expect(find.text('NODE_P02'), findsOneWidget);

      // Close via close icon button
      await tester.tap(find.byTooltip('Close Details'));
      await tester.pumpAndSettle();

      expect(find.byType(ParkingSlotDetailsSheet), findsNothing);
    });

    testWidgets('tapping maintenance slot displays inactive state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Scroll to P10 at the far end of the horizontal facility layout
      await tester.ensureVisible(find.text('P10'));
      await tester.pumpAndSettle();

      // Tap P10
      await tester.tap(find.text('P10'));
      await tester.pumpAndSettle();

      expect(find.byType(ParkingSlotDetailsSheet), findsOneWidget);
      expect(find.text('Parking Bay P10'), findsOneWidget);
      expect(find.text('Inactive / Maintenance'), findsOneWidget);
      expect(find.text('Not available for parking (Maintenance)'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('ParkingSlotsScreen - Search & Filtering', () {
    testWidgets('searches slot by code case-insensitively with whitespace',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Search '  p03  '
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '  p03  ');
      await tester.pumpAndSettle();

      expect(find.text('Showing 1 of 20 bays'), findsOneWidget);

      // P03 should not be dimmed
      final p03Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P03'),
      );
      expect(p03Tile.isDimmed, isFalse);

      // P01 should be dimmed
      final p01Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P01'),
      );
      expect(p01Tile.isDimmed, isTrue);

      // Clear search via clear button
      await tester.tap(find.byTooltip('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 20 of 20 bays'), findsOneWidget);
    });

    testWidgets('shows empty state for unmatched search and resets cleanly',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Search nonexistent code
      await tester.enterText(find.byType(TextField), 'P99');
      await tester.pumpAndSettle();

      // Empty state visible
      expect(find.text('No matching parking slots'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Ensure button is visible before tapping
      await tester.ensureVisible(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      // Tap reset button
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 20 of 20 bays'), findsOneWidget);
      expect(find.text('No matching parking slots'), findsNothing);
    });

    testWidgets('filters by status chips correctly',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Tap 'Occupied' filter
      await tester.tap(find.widgetWithText(ChoiceChip, 'Occupied'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 4 of 20 bays'), findsOneWidget);

      // P02 (occupied) should NOT be dimmed
      final p02 = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P02'),
      );
      expect(p02.isDimmed, isFalse);

      // P01 (available) SHOULD be dimmed
      final p01 = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P01'),
      );
      expect(p01.isDimmed, isTrue);

      // Tap 'All' filter restores 20
      await tester.tap(find.widgetWithText(ChoiceChip, 'All (20)'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 20 of 20 bays'), findsOneWidget);
    });

    testWidgets('combines search and status filter',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Filter by Available (12 bays)
      await tester.tap(find.widgetWithText(ChoiceChip, 'Available'));
      await tester.pumpAndSettle();
      expect(find.text('Showing 12 of 20 bays'), findsOneWidget);

      // Add search 'P01' -> exactly 1 bay
      await tester.enterText(find.byType(TextField), 'P01');
      await tester.pumpAndSettle();
      expect(find.text('Showing 1 of 20 bays'), findsOneWidget);

      // Search 'P02' (which is occupied) with Available filter active -> 0 bays -> empty state
      await tester.enterText(find.byType(TextField), 'P02');
      await tester.pumpAndSettle();
      expect(find.text('No matching parking slots'), findsOneWidget);

      // Reset filters restores all
      await tester.ensureVisible(find.text('Reset All Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Showing 20 of 20 bays'), findsOneWidget);
    });

    testWidgets('filtering does not mutate underlying service slot data',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Apply search and filter
      await tester.enterText(find.byType(TextField), 'P01');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Available'));
      await tester.pumpAndSettle();

      // Original service data should still have all 20 slots untouched
      expect(controller.totalSlots, 20);
      expect(controller.availableSlots, 12);
      expect(controller.occupiedSlots, 4);
      expect(controller.slotService.slotCount, 20);
      expect(controller.slotService.getSlot('P02')?.status, SlotStatus.occupied);
    });
  });

  group('ParkingSlotsScreen - Reactivity & State Integration', () {
    testWidgets('rebuilds dynamically when controller state mutates',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      expect(find.text('12'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Mutate slot P01 from available to occupied
      controller.updateSlotStatus('P01', SlotStatus.occupied);
      await tester.pumpAndSettle();

      // Available is now 11, Occupied is now 5
      expect(find.text('11'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      final p01Tile = tester.widget<ParkingSlotTile>(
        find.byWidgetPredicate(
            (w) => w is ParkingSlotTile && w.slot.slotCode == 'P01'),
      );
      expect(p01Tile.slot.status, SlotStatus.occupied);
    });

    testWidgets('app bar reset restores default facility state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Mutate
      controller.updateSlotStatus('P01', SlotStatus.occupied);
      await tester.pumpAndSettle();
      expect(find.text('11'), findsOneWidget);

      // Tap AppBar reset button
      await tester.tap(find.byTooltip('Reset Data to Defaults'));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Facility data reset to defaults.'), findsOneWidget);
    });
  });
}
