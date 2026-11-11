import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/features/bookings/bookings_screen.dart';
import 'package:smartpark_app/features/bookings/create_booking_screen.dart';
import 'package:smartpark_app/features/bookings/widgets/booking_card.dart';
import 'package:smartpark_app/features/bookings/widgets/booking_details_sheet.dart';
import 'package:smartpark_app/features/dashboard/dashboard_screen.dart';
import 'package:smartpark_app/features/navigation/facility_navigation_screen.dart';
import 'package:smartpark_app/features/parking/parking_slots_screen.dart';
import 'package:smartpark_app/features/parking/widgets/parking_slot_details_sheet.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';
import 'package:smartpark_app/widgets/smartpark_scope.dart';

void main() {
  Widget buildApp(Widget home, SmartParkController controller) {
    return SmartParkScope(
      controller: controller,
      child: MaterialApp(
        home: home,
      ),
    );
  }

  final testViewports = <String, Size>{
    'Narrow Mobile (320x640)': const Size(320, 640),
    'Standard Mobile (360x800)': const Size(360, 800),
    'Modern Mobile (390x844)': const Size(390, 844),
    'Reported Emulator (728x1000)': const Size(728, 1000),
    'Reported Emulator Tall (728x1280)': const Size(728, 1280),
    'Tablet Viewport (800x1280)': const Size(800, 1280),
    'Tablet Landscape (1024x768)': const Size(1024, 768),
  };

  group('UI Overflow Audit — Booking Statistics Cards', () {
    for (final entry in testViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('BookingsScreen metrics render with zero overflow on $name',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Catch any overflow exceptions explicitly
        final originalOnError = FlutterError.onError;
        Object? capturedException;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.toString().contains('overflowed')) {
            capturedException = details.exception;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        final controller = SmartParkController();
        await tester.pumpWidget(buildApp(const BookingsScreen(), controller));
        await tester.pumpAndSettle();

        // 1. Zero framework exceptions or RenderFlex overflows
        expect(capturedException, isNull,
            reason: 'RenderFlex overflow detected on viewport $name: $capturedException');
        expect(tester.takeException(), isNull);

        // 2. All 5 statistics cards and their labels are present and rendered
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Confirmed'), findsWidgets);
        expect(find.text('Active'), findsWidgets);
        expect(find.text('Completed'), findsWidgets);
        expect(find.text('Cancelled'), findsWidgets);

        // 3. All 5 numeric values are visible
        expect(find.text('4'), findsOneWidget); // Total count
        expect(find.text('1'), findsNWidgets(4)); // 1 each for Confirmed, Active, Completed, Cancelled
      });
    }
  });

  group('UI Overflow Audit — Parking Slots Screen Metrics', () {
    for (final entry in testViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('ParkingSlotsScreen live metrics render with zero overflow on $name',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final originalOnError = FlutterError.onError;
        Object? capturedException;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.toString().contains('overflowed')) {
            capturedException = details.exception;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        final controller = SmartParkController();
        await tester.pumpWidget(buildApp(const ParkingSlotsScreen(), controller));
        await tester.pumpAndSettle();

        expect(capturedException, isNull,
            reason: 'RenderFlex overflow detected on viewport $name: $capturedException');
        expect(tester.takeException(), isNull);

        // Verify all 5 slot metrics rendered
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Available'), findsWidgets);
        expect(find.text('Occupied'), findsWidgets);
        expect(find.text('Reserved'), findsWidgets);
        expect(find.text('Maintenance'), findsWidgets);
      });
    }
  });

  group('UI Overflow Audit — Dashboard Screen', () {
    for (final entry in testViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('DashboardScreen renders cleanly with zero overflow on $name',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final originalOnError = FlutterError.onError;
        Object? capturedException;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.toString().contains('overflowed')) {
            capturedException = details.exception;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        final controller = SmartParkController();
        await tester.pumpWidget(buildApp(const DashboardScreen(), controller));
        await tester.pumpAndSettle();

        expect(capturedException, isNull,
            reason: 'RenderFlex overflow on Dashboard on viewport $name');
        expect(tester.takeException(), isNull);

        expect(find.text('SmartPark Dashboard'), findsOneWidget);
        expect(find.text('Parking Availability Summary'), findsOneWidget);
      });
    }
  });

  group('UI Overflow Audit — Facility Navigation Screen', () {
    for (final entry in testViewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('FacilityNavigationScreen renders route cleanly with zero overflow on $name',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final originalOnError = FlutterError.onError;
        Object? capturedException;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.toString().contains('overflowed')) {
            capturedException = details.exception;
          }
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        final controller = SmartParkController();
        await tester.pumpWidget(
          buildApp(const FacilityNavigationScreen(initialSlotCode: 'P01'), controller),
        );
        await tester.pumpAndSettle();

        expect(capturedException, isNull,
            reason: 'RenderFlex overflow on Facility Navigation on viewport $name');
        expect(tester.takeException(), isNull);

        expect(find.text('Facility Navigation'), findsOneWidget);
        expect(find.text('Destination: Bay P01'), findsOneWidget);
        expect(find.text('9.5m'), findsOneWidget);
      });
    }
  });

  group('UI Overflow Audit — Dialogs and Modal Sheets', () {
    testWidgets('BookingDetailsSheet renders without overflow on narrow viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      final sampleBooking = controller.allBookings.firstWhere(
        (b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.active,
      );

      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: BookingDetailsSheet(booking: sampleBooking, controller: controller),
          ),
          controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Booking ${sampleBooking.id}'), findsOneWidget);
      expect(find.text('Parking Bay ${sampleBooking.slotId}'), findsOneWidget);
    });

    testWidgets('ParkingSlotDetailsSheet renders without overflow on narrow viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      final slot = controller.slotService.getSlot('P01')!;

      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: ParkingSlotDetailsSheet(slot: slot),
          ),
          controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Parking Bay P01'), findsOneWidget);
    });

    testWidgets('CreateBookingScreen renders without overflow on narrow viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();

      await tester.pumpWidget(
        buildApp(
          const CreateBookingScreen(initialSlotCode: 'P01'),
          controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Create Reservation'), findsOneWidget);
    });

    testWidgets('BookingCard renders buttons without overflow on narrow viewport (320px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SmartParkController();
      final sampleBooking = controller.allBookings.firstWhere(
        (b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.active,
      );

      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BookingCard(booking: sampleBooking, controller: controller),
            ),
          ),
          controller,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Cancel Booking'), findsOneWidget);
    });
  });
}
