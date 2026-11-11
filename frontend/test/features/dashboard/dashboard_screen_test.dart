import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/features/dashboard/dashboard_screen.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildTestableDashboard(SmartParkController controller) {
    return SmartParkScope(
      controller: controller,
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen - Widget Foundation', () {
    testWidgets('renders dynamic counts directly from service layer',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Check header
      expect(find.text('SmartPark Facility (Floor 1)'), findsOneWidget);

      // Check summary card values
      expect(find.text('Total Slots'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      expect(find.text('Occupied'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
    });

    testWidgets('renders optimal slot recommendation from Min-Heap & Dijkstra',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Recommendation card
      expect(find.text('Optimal Slot Recommendation'), findsOneWidget);
      expect(find.text('Bay P01 (Row A (North))'), findsOneWidget);
      expect(
        find.text('9.5m from entrance via Dijkstra path'),
        findsOneWidget,
      );
    });

    testWidgets('rebuilds dynamically when controller state mutates',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      expect(find.text('12'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Mutate slot in controller
      controller.updateSlotStatus('P01', SlotStatus.occupied);
      await tester.pump();

      // Available should be 11, Occupied should be 5
      expect(find.text('11'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('parking slots quick action navigates to ParkingSlotsScreen and back',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Tap Parking Slots
      await tester.tap(find.text('Parking Slots'));
      await tester.pumpAndSettle();

      // Verify ParkingSlotsScreen is displayed
      expect(find.text('20 standard bays • Two parallel rows • Central driving aisle'), findsOneWidget);
      expect(find.text('ROW A (NORTH)'), findsOneWidget);
      expect(find.text('ROW B (SOUTH)'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify returned to Dashboard
      expect(find.text('SmartPark Dashboard'), findsOneWidget);
    });

    testWidgets('bookings quick action navigates to BookingsScreen and back',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Scroll to and tap Bookings & Reservations
      await tester.ensureVisible(find.text('Bookings & Reservations'));
      await tester.tap(find.text('Bookings & Reservations'));
      await tester.pumpAndSettle();

      // Verify BookingsScreen is displayed
      expect(find.text('SmartPark Reservations'), findsOneWidget);
      expect(find.text('In-memory temporal conflict detection backed by custom AVL Interval Tree'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify returned to Dashboard
      expect(find.text('SmartPark Dashboard'), findsOneWidget);
    });

    testWidgets('facility navigation quick action navigates to FacilityNavigationScreen and back',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Scroll to and tap Facility Navigation
      await tester.ensureVisible(find.text('Facility Navigation'));
      await tester.tap(find.text('Facility Navigation'));
      await tester.pumpAndSettle();

      // Verify FacilityNavigationScreen is displayed
      expect(find.text('Facility Navigation (Floor 1)'), findsOneWidget);
      expect(find.text('Shortest-path routing via custom Weighted Graph & Dijkstra algorithm'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify returned to Dashboard
      expect(find.text('SmartPark Dashboard'), findsOneWidget);
    });

    testWidgets('app bar reset action restores default counts',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableDashboard(controller));

      // Mutate
      controller.updateSlotStatus('P01', SlotStatus.occupied);
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      // Tap reset button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Facility data reset to defaults.'), findsOneWidget);
    });
  });
}
