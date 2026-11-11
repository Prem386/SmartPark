import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/booking_conflict_service.dart';
import 'package:smartpark_app/services/parking_navigation_service.dart';
import 'package:smartpark_app/services/parking_recommendation_service.dart';
import 'package:smartpark_app/services/parking_slot_service.dart';
import 'package:smartpark_app/services/smartpark_dsa_service.dart';

void main() {
  group('End-to-End DSA Workflows (Realistic Integrated Scenarios)', () {
    // 20 facility slots factory helper
    List<ParkingSlot> buildFacilitySlots() {
      final slots = <ParkingSlot>[];
      for (int i = 1; i <= 10; i++) {
        final code = 'P${i.toString().padLeft(2, '0')}';
        slots.add(
          ParkingSlot(
            id: 'slot-record-$code',
            slotCode: code,
            row: SlotRow.a,
            status: SlotStatus.available,
            isActive: true,
            navigationNodeId: 'NODE_$code',
          ),
        );
      }
      for (int i = 1; i <= 10; i++) {
        final code = 'P${i + 10}';
        slots.add(
          ParkingSlot(
            id: 'slot-record-$code',
            slotCode: code,
            row: SlotRow.b,
            status: SlotStatus.available,
            isActive: true,
            navigationNodeId: 'NODE_$code',
          ),
        );
      }
      return slots;
    }

    test('Workflow A — Find and recommend parking', () {
      // 1. Initialize the parking facility
      final slotService = ParkingSlotService();
      final navService = ParkingNavigationService();
      final recommendationService = ParkingRecommendationService(
        slotService: slotService,
        navigationService: navService,
      );

      // 2. Register parking slots (simulate some occupied/reserved)
      final allSlots = buildFacilitySlots();
      for (final slot in allSlots) {
        if (slot.slotCode == 'P01') {
          // P01 is occupied
          slotService.registerSlot(slot.copyWith(status: SlotStatus.occupied));
        } else if (slot.slotCode == 'P11') {
          // P11 is under maintenance
          slotService.registerSlot(slot.copyWith(status: SlotStatus.maintenance));
        } else {
          slotService.registerSlot(slot);
        }
      }

      expect(slotService.slotCount, equals(20));

      // 3 & 4. Calculate navigation distances and rank eligible slots using Custom Min-Heap
      // P01 (9.5m) and P11 (9.5m) are unavailable, so the next closest are P02 (12.5m) and P12 (12.5m)
      final top3 = recommendationService.getRecommendations(limit: 3);

      // 5. Retrieve top recommendations
      expect(top3.length, equals(3));
      expect(top3[0].slot.slotCode, equals('P02'));
      expect(top3[0].distance, equals(12.5));

      expect(top3[1].slot.slotCode, equals('P12'));
      expect(top3[1].distance, equals(12.5));

      expect(top3[2].slot.slotCode, equals('P03'));
      expect(top3[2].distance, equals(15.5));
    });

    test('Workflow B — Booking conflict validation', () {
      // 1. Initialize the booking conflict service
      final conflictService = BookingConflictService();

      // 2. Add an existing booking on slot P04 from 14:00 to 16:00
      final existingBooking = Booking(
        id: 'BK-1001',
        slotId: 'P04',
        startTime: DateTime(2026, 11, 20, 14, 0),
        endTime: DateTime(2026, 11, 20, 16, 0),
        status: BookingStatus.confirmed,
        userId: 'USR-88',
      );
      conflictService.addBooking(existingBooking);
      expect(conflictService.bookingCount, equals(1));

      // 3. Attempt to add an overlapping booking for the same slot (15:00 to 17:00)
      final overlappingBooking = Booking(
        id: 'BK-1002',
        slotId: 'P04',
        startTime: DateTime(2026, 11, 20, 15, 0),
        endTime: DateTime(2026, 11, 20, 17, 0),
        status: BookingStatus.confirmed,
        userId: 'USR-99',
      );

      // 4. Verify that conflict is detected and rejected
      expect(conflictService.isBookingInConflict(overlappingBooking), isTrue);
      expect(
        () => conflictService.addBooking(overlappingBooking),
        throwsA(isA<BookingConflictException>()),
      );
      expect(conflictService.bookingCount, equals(1));

      // 5. Attempt an adjacent booking (16:00 to 18:00 on P04 - back to back)
      final adjacentBooking = Booking(
        id: 'BK-1003',
        slotId: 'P04',
        startTime: DateTime(2026, 11, 20, 16, 0),
        endTime: DateTime(2026, 11, 20, 18, 0),
        status: BookingStatus.confirmed,
        userId: 'USR-100',
      );

      // 6. Verify that adjacent booking is accepted without conflict
      expect(conflictService.isBookingInConflict(adjacentBooking), isFalse);
      expect(() => conflictService.addBooking(adjacentBooking), returnsNormally);
      expect(conflictService.bookingCount, equals(2));
    });

    test('Workflow C — Slot lookup and navigation', () {
      final slotService = ParkingSlotService(buildFacilitySlots());
      final navService = ParkingNavigationService();

      // 1. Look up a slot using its slot code
      final targetSlot = slotService.getSlot('P05');
      expect(targetSlot, isNotNull);
      expect(targetSlot!.slotCode, equals('P05'));

      // 2. Retrieve its navigation node
      final navNodeId = navService.resolveNodeId(targetSlot);
      expect(navNodeId, equals('NODE_P05'));

      // 3. Calculate its route from the entrance
      final route = navService.getRouteToSlot(targetSlot);
      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);

      // 4. Return slot and route details
      // d = 4.0 + 3.0 * 4 + 5.5 = 21.5m
      expect(route.distance, equals(21.5));
      expect(
        route.path,
        equals([
          'NODE_ENTRANCE',
          'NODE_W01',
          'NODE_W02',
          'NODE_W03',
          'NODE_W04',
          'NODE_W05',
          'NODE_P05',
        ]),
      );
    });

    test('Workflow D — Unified SmartParkDsaService Facade orchestration', () {
      final dsa = SmartParkDsaService();
      dsa.registerSlots(buildFacilitySlots());

      // 1. Fast lookup
      final slot = dsa.findSlot('P04');
      expect(slot, isNotNull);
      expect(slot!.slotCode, equals('P04'));

      // 2. Recommendations
      final recommendations = dsa.getRecommendations(limit: 2);
      expect(recommendations.length, equals(2));
      expect(recommendations[0].slot.slotCode, equals('P01'));
      expect(recommendations[1].slot.slotCode, equals('P11'));

      // 3. Navigation
      final route = dsa.findRouteToSlot('P04');
      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);
      expect(route.distance, equals(18.5));

      // 4. Booking and conflict checking
      final booking = Booking(
        id: 'BK-555',
        slotId: 'P04',
        startTime: DateTime(2026, 11, 25, 9, 0),
        endTime: DateTime(2026, 11, 25, 11, 0),
      );

      expect(dsa.checkBookingConflict(booking), isFalse);
      dsa.bookSlot(booking);

      // Same slot overlap check
      expect(
        dsa.checkTimeConflict('P04', DateTime(2026, 11, 25, 10, 0), DateTime(2026, 11, 25, 12, 0)),
        isTrue,
      );

      // Different slot no conflict
      expect(
        dsa.checkTimeConflict('P05', DateTime(2026, 11, 25, 10, 0), DateTime(2026, 11, 25, 12, 0)),
        isFalse,
      );
    });
  });
}

