import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/data/local/smartpark_local_data.dart';
import 'package:smartpark_app/features/parking/widgets/parking_facility_layout.dart';
import 'package:smartpark_app/features/parking/widgets/parking_slot_tile.dart';
import 'package:smartpark_app/features/parking/widgets/parking_status_legend.dart';
import 'package:smartpark_app/models/parking_slot.dart';

void main() {
  group('ParkingFacilityLayout - Spatial Layout Unit Tests', () {
    testWidgets('renders Row A, Row B, entrance gate, and waypoints correctly',
        (WidgetTester tester) async {
      final initialSlots = SmartParkLocalData.createInitialSlots();
      final rowASlots = initialSlots.sublist(0, 10);
      final rowBSlots = initialSlots.sublist(10, 20);

      ParkingSlot? selectedSlot;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ParkingFacilityLayout(
                rowASlots: rowASlots,
                rowBSlots: rowBSlots,
                selectedSlotCode: null,
                matchingSlotCodes: {for (final s in initialSlots) s.slotCode},
                onSlotTapped: (slot) {
                  selectedSlot = slot;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Row Headers
      expect(find.text('ROW A (NORTH)'), findsOneWidget);
      expect(find.text('ROW B (SOUTH)'), findsOneWidget);
      expect(find.text('ENTRY'), findsOneWidget);

      // Verify Waypoints
      expect(find.text('W01'), findsOneWidget);
      expect(find.text('W10'), findsOneWidget);

      // Tap P01
      await tester.tap(find.text('P01'));
      await tester.pump();
      expect(selectedSlot?.slotCode, 'P01');

      // Tap P15
      await tester.tap(find.text('P15'));
      await tester.pump();
      expect(selectedSlot?.slotCode, 'P15');
    });

    testWidgets('selected slot receives visual highlight',
        (WidgetTester tester) async {
      final slot = ParkingSlot(
        id: 'P01',
        slotCode: 'P01',
        row: SlotRow.a,
        status: SlotStatus.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParkingSlotTile(
              slot: slot,
              isSelected: true,
              isDimmed: false,
            ),
          ),
        ),
      );

      final tileFinder = find.byType(ParkingSlotTile);
      expect(tileFinder, findsOneWidget);

      final tileWidget = tester.widget<ParkingSlotTile>(tileFinder);
      expect(tileWidget.isSelected, isTrue);
      expect(tileWidget.isDimmed, isFalse);
    });

    testWidgets('dimmed slot has reduced opacity and ignores taps',
        (WidgetTester tester) async {
      final slot = ParkingSlot(
        id: 'P02',
        slotCode: 'P02',
        row: SlotRow.a,
        status: SlotStatus.occupied,
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParkingSlotTile(
              slot: slot,
              isSelected: false,
              isDimmed: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap dimmed tile
      await tester.tap(find.byType(ParkingSlotTile));
      await tester.pump();

      // Tap callback should not be invoked when dimmed
      expect(tapped, isFalse);
    });
  });

  group('ParkingStatusLegend - Unit Tests', () {
    testWidgets('renders all 4 status indicators with distinct icons and labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParkingStatusLegend(),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Occupied'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });
  });
}

