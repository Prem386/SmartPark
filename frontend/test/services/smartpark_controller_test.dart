import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';

void main() {
  group('SmartParkController - Reactive State Management', () {
    late SmartParkController controller;

    setUp(() {
      controller = SmartParkController();
    });

    test('initializes with correct baseline facility counts', () {
      expect(controller.totalSlots, equals(20));
      expect(controller.availableSlots, equals(12));
      expect(controller.occupiedSlots, equals(4));
      expect(controller.reservedSlots, equals(2));
      expect(controller.maintenanceSlots, equals(2));
    });

    test('underlying service getters expose shared instances', () {
      expect(identical(controller.slotService, controller.dsaService.slotService), isTrue);
      expect(identical(controller.bookingService, controller.dsaService.bookingService), isTrue);
      expect(identical(controller.navigationService, controller.dsaService.navigationService), isTrue);
      expect(identical(controller.recommendationService, controller.dsaService.recommendationService), isTrue);
    });

    test('updateSlotStatus modifies slot, recalculates metrics, and triggers notification', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // P01 was available; update to occupied
      controller.updateSlotStatus('P01', SlotStatus.occupied);

      expect(notifyCount, equals(1));
      expect(controller.availableSlots, equals(11));
      expect(controller.occupiedSlots, equals(5));
      expect(controller.slotService.getSlot('P01')?.status, equals(SlotStatus.occupied));
    });

    test('bookSlot adds reservation, marks slot reserved, and triggers notification', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final newBooking = Booking(
        id: 'B_NEW_01',
        slotId: 'P01',
        startTime: DateTime(2026, 11, 11, 17, 0),
        endTime: DateTime(2026, 11, 11, 18, 0),
        status: BookingStatus.confirmed,
        userId: 'USER_TEST',
      );

      controller.bookSlot(newBooking);

      expect(notifyCount, equals(1));
      expect(controller.slotService.getSlot('P01')?.status, equals(SlotStatus.reserved));
      expect(controller.availableSlots, equals(11));
      expect(controller.reservedSlots, equals(3));
    });

    test('allBookings exposes all indexed reservations', () {
      expect(controller.allBookings.length, equals(4));
      expect(controller.allBookings.map((b) => b.id), containsAll(['B01', 'B02', 'B03', 'B04']));
    });

    test('generateNextBookingId creates next sequential ID format', () {
      expect(controller.generateNextBookingId(), equals('B05'));

      // Add B05
      controller.bookSlot(Booking(
        id: 'B05',
        slotId: 'P01',
        startTime: DateTime(2026, 11, 11, 18, 0),
        endTime: DateTime(2026, 11, 11, 19, 0),
        status: BookingStatus.confirmed,
      ));

      expect(controller.generateNextBookingId(), equals('B06'));
    });

    test('cancelBooking marks booking cancelled, releases reserved slot, and notifies', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // B01 is confirmed on P04; P04 is currently reserved
      expect(controller.slotService.getSlot('P04')?.status, equals(SlotStatus.reserved));
      expect(controller.bookingService.getBooking('B01')?.status, equals(BookingStatus.confirmed));

      final cancelled = controller.cancelBooking('B01');

      expect(notifyCount, equals(1));
      expect(cancelled.status, equals(BookingStatus.cancelled));
      expect(controller.bookingService.getBooking('B01')?.status, equals(BookingStatus.cancelled));
      // P04 should now be restored to available
      expect(controller.slotService.getSlot('P04')?.status, equals(SlotStatus.available));
      expect(controller.availableSlots, equals(13));
      expect(controller.reservedSlots, equals(1));
    });

    test('cancelBooking throws when trying to cancel already cancelled or completed booking', () {
      // B04 is already cancelled
      expect(
        () => controller.cancelBooking('B04'),
        throwsA(isA<StateError>()),
      );

      // B03 is completed
      expect(
        () => controller.cancelBooking('B03'),
        throwsA(isA<StateError>()),
      );

      // Non-existent ID
      expect(
        () => controller.cancelBooking('B99'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('resetToDefaults restores initial state after mutations and notifies', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.updateSlotStatus('P01', SlotStatus.occupied);
      controller.updateSlotStatus('P03', SlotStatus.occupied);
      expect(controller.availableSlots, equals(10));

      controller.resetToDefaults();
      expect(controller.availableSlots, equals(12));
      expect(controller.occupiedSlots, equals(4));
      expect(notifyCount, equals(3));
    });
  });
}
