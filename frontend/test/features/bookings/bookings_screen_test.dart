import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/features/bookings/bookings_screen.dart';
import 'package:smartpark_app/features/bookings/create_booking_screen.dart';
import 'package:smartpark_app/features/bookings/widgets/booking_card.dart';
import 'package:smartpark_app/features/bookings/widgets/booking_details_sheet.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildTestableScreen(SmartParkController controller) {
    return SmartParkScope(
      controller: controller,
      child: const MaterialApp(
        home: BookingsScreen(),
      ),
    );
  }

  group('BookingsScreen - Layout & Rendering', () {
    testWidgets('displays header, live metrics, and sample bookings',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Header checks
      expect(find.text('Bookings & Reservations'), findsOneWidget);
      expect(find.text('SmartPark Reservations'), findsOneWidget);
      expect(
        find.text(
          'In-memory temporal conflict detection backed by custom AVL Interval Tree',
        ),
        findsOneWidget,
      );

      // Metrics checks (4 sample bookings: 1 confirmed, 1 active, 1 completed, 1 cancelled)
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('1'), findsNWidgets(4)); // 1 for Confirmed, Active, Completed, Cancelled
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);

      // Verify all 4 sample booking cards are present
      expect(find.text('B01'), findsOneWidget);
      expect(find.text('B02'), findsOneWidget);
      expect(find.text('B03'), findsOneWidget);
      expect(find.text('B04'), findsOneWidget);

      expect(find.text('P04'), findsOneWidget);
      expect(find.text('P15'), findsOneWidget);
      expect(find.text('P01'), findsOneWidget);
      expect(find.text('P03'), findsOneWidget);
    });

    testWidgets('floating action button navigates to CreateBookingScreen',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      await tester.tap(find.text('New Booking'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateBookingScreen), findsOneWidget);
      expect(find.text('Create Reservation'), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(BookingsScreen), findsOneWidget);
    });
  });

  group('BookingsScreen - Status Filtering', () {
    testWidgets('filters by status chips presentation-only without mutating state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Filter: Confirmed
      await tester.tap(find.widgetWithText(ChoiceChip, 'Confirmed'));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsOneWidget);
      expect(find.text('B02'), findsNothing);
      expect(find.text('B03'), findsNothing);
      expect(find.text('B04'), findsNothing);

      // Filter: Active
      await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsNothing);
      expect(find.text('B02'), findsOneWidget);
      expect(find.text('B03'), findsNothing);
      expect(find.text('B04'), findsNothing);

      // Filter: Completed
      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsNothing);
      expect(find.text('B02'), findsNothing);
      expect(find.text('B03'), findsOneWidget);
      expect(find.text('B04'), findsNothing);

      // Filter: Cancelled
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cancelled'));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsNothing);
      expect(find.text('B02'), findsNothing);
      expect(find.text('B03'), findsNothing);
      expect(find.text('B04'), findsOneWidget);

      // Reset to All
      await tester.tap(find.widgetWithText(ChoiceChip, 'All (4)'));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsOneWidget);
      expect(find.text('B02'), findsOneWidget);
      expect(find.text('B03'), findsOneWidget);
      expect(find.text('B04'), findsOneWidget);

      // Underlying controller data is unchanged
      expect(controller.allBookings.length, equals(4));
    });

    testWidgets('shows empty state when no bookings match filter and resets cleanly',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // Remove all bookings
      controller.bookingService.clear();

      await tester.pumpWidget(buildTestableScreen(controller));

      expect(find.text('No bookings found'), findsOneWidget);
      expect(find.text('Create New Booking'), findsOneWidget);
    });
  });

  group('BookingsScreen - Inspection Details Sheet', () {
    testWidgets('tapping booking card opens BookingDetailsSheet with full attributes',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Scroll to B01 and tap
      await tester.ensureVisible(find.text('B01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B01'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingDetailsSheet), findsOneWidget);
      expect(find.text('Booking B01'), findsOneWidget);
      expect(find.text('Parking Bay P04'), findsOneWidget);
      expect(find.text('Row A (North) • Floor 1'), findsOneWidget);
      expect(find.text('14:00 – 16:00 [start, end)'), findsOneWidget);
      expect(find.text('2h'), findsWidgets);
      expect(find.text('USER_101'), findsOneWidget);
      expect(find.text('KA-01-AB-1001'), findsOneWidget);

      // Close modal
      await tester.tap(find.byTooltip('Close Details'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingDetailsSheet), findsNothing);
    });
  });

  group('BookingsScreen - Booking Cancellation', () {
    testWidgets('cancelling confirmed booking updates status, metrics, and releases slot',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Before: P04 is reserved, 2 reserved total, 12 available
      expect(controller.slotService.getSlot('P04')?.status, equals(SlotStatus.reserved));
      expect(controller.reservedSlots, equals(2));
      expect(controller.availableSlots, equals(12));

      // Find Cancel button specifically on B01 card
      final b01Card = find.ancestor(of: find.text('B01'), matching: find.byType(BookingCard));
      final cancelButton = find.descendant(of: b01Card, matching: find.widgetWithText(TextButton, 'Cancel Booking'));
      expect(cancelButton, findsOneWidget);

      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Cancel Booking B01?'), findsOneWidget);
      expect(find.text('Cancel Reservation'), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.text('Cancel Reservation'));
      await tester.pumpAndSettle();

      // Verify SnackBar
      expect(find.text('Booking B01 cancelled successfully.'), findsOneWidget);

      // Status in UI has updated: 0 Confirmed, 2 Cancelled
      expect(controller.bookingService.getBooking('B01')?.status, equals(BookingStatus.cancelled));

      // P04 should be released back to available!
      expect(controller.slotService.getSlot('P04')?.status, equals(SlotStatus.available));
      expect(controller.availableSlots, equals(13));
      expect(controller.reservedSlots, equals(1));
    });

    testWidgets('completed and cancelled bookings do not show cancel button on card',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Filter: Completed
      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pumpAndSettle();

      // B03 is completed; should NOT have cancel button
      final b03Card = find.byWidgetPredicate((w) => w is BookingCard && w.booking.id == 'B03');
      expect(b03Card, findsOneWidget);
      expect(find.descendant(of: b03Card, matching: find.text('Cancel Booking')), findsNothing);

      // Filter: Cancelled
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cancelled'));
      await tester.pumpAndSettle();

      // B04 is cancelled; should NOT have cancel button
      final b04Card = find.byWidgetPredicate((w) => w is BookingCard && w.booking.id == 'B04');
      expect(b04Card, findsOneWidget);
      expect(find.descendant(of: b04Card, matching: find.text('Cancel Booking')), findsNothing);
    });
  });

  group('BookingsScreen - State Integration & App Bar Reset', () {
    testWidgets('reset button restores original sample bookings and counts',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      // Cancel B01
      controller.cancelBooking('B01');
      await tester.pumpAndSettle();
      expect(controller.bookingService.getBooking('B01')?.status, equals(BookingStatus.cancelled));

      // Tap Reset action
      await tester.tap(find.byTooltip('Reset Data to Defaults'));
      await tester.pumpAndSettle();

      expect(find.text('Facility data reset to defaults.'), findsOneWidget);
      expect(controller.bookingService.getBooking('B01')?.status, equals(BookingStatus.confirmed));
      expect(controller.availableSlots, equals(12));
      expect(controller.reservedSlots, equals(2));
    });
  });
}
