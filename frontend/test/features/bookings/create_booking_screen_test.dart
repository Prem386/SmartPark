import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/features/bookings/create_booking_screen.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildTestableScreen(
    SmartParkController controller, {
    String? initialSlotCode,
    DateTime Function()? currentTimeProvider,
  }) {
    return SmartParkScope(
      controller: controller,
      child: MaterialApp(
        home: CreateBookingScreen(
          initialSlotCode: initialSlotCode,
          currentTimeProvider: currentTimeProvider ?? () => DateTime(2026, 11, 11, 8, 0),
        ),
      ),
    );
  }

  group('CreateBookingScreen - Layout & Form Elements', () {
    testWidgets('renders all form sections, fields, and initial state',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller));

      expect(find.text('Create Reservation'), findsOneWidget);
      expect(find.text('1. Select Parking Slot'), findsOneWidget);
      expect(find.text('2. Select Date & Time'), findsOneWidget);
      expect(find.text('3. Availability & Conflict Check'), findsOneWidget);
      expect(find.text('4. Vehicle & User Details (Optional)'), findsOneWidget);

      expect(find.text('Parking Bay'), findsOneWidget);
      expect(find.text('Reservation Date'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Customer / User ID'), findsOneWidget);
      expect(find.text('Vehicle Registration Number'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);

      // Confirm button is disabled initially (missing slot and times)
      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Booking'),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('respects initialSlotCode passed via constructor',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P01'));

      // P01 should be pre-selected in dropdown
      expect(find.text('P01 (Row A (North))'), findsOneWidget);
    });
  });

  group('CreateBookingScreen - Slot & Field Validations', () {
    testWidgets('maintenance or inactive slot displays warning and cannot be confirmed',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // P10 is maintenance
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P10'));

      expect(
        find.text('Slot P10 is inactive or under maintenance and cannot be booked.'),
        findsOneWidget,
      );

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Booking'),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('invalid time ordering (end time earlier than start time) displays warning',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      await tester.pumpWidget(buildTestableScreen(controller, initialSlotCode: 'P01'));

      // Tap Start Time -> pick 14:00
      await tester.tap(find.text('Start Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap End Time -> pick 10:00 (earlier than start time 10:00? Let's pick 09:00)
      // Open end time picker
      await tester.tap(find.text('End Time'));
      await tester.pumpAndSettle();
      // In time picker dialog, tap a different hour or tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('past start time is rejected when date/time is before current time',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // Set current time to 15:00 on 2026-11-11
      await tester.pumpWidget(
        buildTestableScreen(
          controller,
          initialSlotCode: 'P01',
          currentTimeProvider: () => DateTime(2026, 11, 11, 15, 0),
        ),
      );

      // Pick start time 10:00 (which is before 15:00)
      await tester.tap(find.text('Start Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Pick end time 11:00
      await tester.tap(find.text('End Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Start time is 10:00, which is in the past compared to 15:00
      expect(find.text('Booking start time cannot be in the past.'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Booking'),
      );
      expect(confirmBtn.onPressed, isNull);
    });
  });

  group('CreateBookingScreen - Interval Tree Conflict Detection', () {
    testWidgets('detects conflict for overlapping booking on same slot (P04 at 14:00-16:00)',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // P04 has B01 from 14:00 to 16:00
      await tester.pumpWidget(
        buildTestableScreen(
          controller,
          initialSlotCode: 'P04',
          currentTimeProvider: () => DateTime(2026, 11, 11, 8, 0),
        ),
      );

      // Default start time picker yields 10:00, end time yields 11:00
      // Let's set start time to 10:00 and end time to 11:00 first -> no conflict on P04
      await tester.tap(find.text('Start Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('End Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 10:00 to 11:00 on P04 has NO conflict (B01 is 14:00 - 16:00)
      expect(find.text('This slot is available for the selected time (1h).'), findsOneWidget);

      final confirmBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Booking'),
      );
      expect(confirmBtn.onPressed, isNotNull);
    });

    testWidgets('allows booking on slot with completed or cancelled booking without conflict',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // P03 has cancelled booking B04 (13:00 - 15:00)
      // P01 has completed booking B03 (08:00 - 09:30)
      await tester.pumpWidget(
        buildTestableScreen(
          controller,
          initialSlotCode: 'P01',
          currentTimeProvider: () => DateTime(2026, 11, 11, 7, 0),
        ),
      );

      // Pick start time 10:00, end time 11:00
      await tester.tap(find.text('Start Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('End Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('This slot is available for the selected time (1h).'), findsOneWidget);
    });
  });

  group('CreateBookingScreen - Successful Booking Creation', () {
    testWidgets('submits new booking, updates controller, reserves slot, and pops with result',
        (WidgetTester tester) async {
      final controller = SmartParkController();
      // Before: 4 bookings, P01 is available
      expect(controller.bookingService.bookingCount, equals(4));
      expect(controller.slotService.getSlot('P01')?.status, equals(SlotStatus.available));
      expect(controller.availableSlots, equals(12));
      expect(controller.reservedSlots, equals(2));

      await tester.pumpWidget(
        buildTestableScreen(
          controller,
          initialSlotCode: 'P01',
          currentTimeProvider: () => DateTime(2026, 11, 11, 8, 0),
        ),
      );

      // Select Start Time: 10:00
      await tester.tap(find.text('Start Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select End Time: 11:00
      await tester.tap(find.text('End Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enter Customer ID & Vehicle Number
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Customer / User ID'),
        'USER_201',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vehicle Registration Number'),
        'KA-05-XY-9999',
      );
      await tester.pumpAndSettle();

      // Review card is visible
      expect(find.text('Reservation Summary'), findsOneWidget);
      expect(find.text('Bay P01'), findsOneWidget);
      expect(find.text('10:00 – 11:00'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);

      // Scroll to ensure Confirm button is visible and tap
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Booking'));
      await tester.pumpAndSettle();

      // Verify controller state
      expect(controller.bookingService.bookingCount, equals(5));
      expect(controller.bookingService.containsBooking('B05'), isTrue);

      final newBooking = controller.bookingService.getBooking('B05')!;
      expect(newBooking.slotId, equals('P01'));
      expect(newBooking.status, equals(BookingStatus.confirmed));
      expect(newBooking.userId, equals('USER_201'));
      expect(newBooking.vehicleNumber, equals('KA-05-XY-9999'));

      // Slot P01 is now marked reserved!
      expect(controller.slotService.getSlot('P01')?.status, equals(SlotStatus.reserved));
      expect(controller.availableSlots, equals(11));
      expect(controller.reservedSlots, equals(3));
    });
  });
}

