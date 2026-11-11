import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/data/local/smartpark_local_data.dart';
import 'package:smartpark_app/dsa/graph/parking_graph_factory.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/models/parking_slot.dart';

void main() {
  group('SmartParkLocalData - Parking Slots Specification', () {
    test('creates exactly 20 parking bays matching facility design', () {
      final slots = SmartParkLocalData.createInitialSlots();
      expect(slots.length, equals(20));
    });

    test('verifies 10 bays in Row A (P01-P10) and 10 bays in Row B (P11-P20)', () {
      final slots = SmartParkLocalData.createInitialSlots();
      final rowA = slots.where((s) => s.row == SlotRow.a).toList();
      final rowB = slots.where((s) => s.row == SlotRow.b).toList();

      expect(rowA.length, equals(10));
      expect(rowB.length, equals(10));

      for (int i = 1; i <= 10; i++) {
        final expectedCode = 'P${i.toString().padLeft(2, '0')}';
        expect(rowA[i - 1].slotCode, equals(expectedCode));
        expect(rowA[i - 1].y, equals(13.5));
        expect(rowA[i - 1].x, equals(6.0 + 3.0 * (i - 1)));
      }

      for (int i = 1; i <= 10; i++) {
        final slotIndex = i + 10;
        final expectedCode = 'P$slotIndex';
        expect(rowB[i - 1].slotCode, equals(expectedCode));
        expect(rowB[i - 1].y, equals(2.5));
        expect(rowB[i - 1].x, equals(6.0 + 3.0 * (i - 1)));
      }
    });

    test('verifies each bay maps to correct canonical navigation node ID', () {
      final slots = SmartParkLocalData.createInitialSlots();
      for (int i = 1; i <= 20; i++) {
        final slot = slots[i - 1];
        final expectedNodeId = ParkingGraphFactory.slotNodeId(i);
        expect(slot.navigationNodeId, equals(expectedNodeId));
      }
    });

    test('verifies realistic status distribution (12 available, 4 occupied, 2 reserved, 2 maintenance)', () {
      final slots = SmartParkLocalData.createInitialSlots();
      final available = slots.where((s) => s.status == SlotStatus.available && s.isActive).length;
      final occupied = slots.where((s) => s.status == SlotStatus.occupied).length;
      final reserved = slots.where((s) => s.status == SlotStatus.reserved).length;
      final maintenance = slots.where((s) => s.status == SlotStatus.maintenance).length;

      expect(available, equals(12));
      expect(occupied, equals(4));
      expect(reserved, equals(2));
      expect(maintenance, equals(2));
      expect(available + occupied + reserved + maintenance, equals(20));
    });
  });

  group('SmartParkLocalData - Sample Bookings Specification', () {
    test('creates sample bookings demonstrating all 4 lifecycle statuses', () {
      final bookings = SmartParkLocalData.createInitialBookings();
      expect(bookings.length, equals(4));

      final statuses = bookings.map((b) => b.status).toSet();
      expect(statuses, contains(BookingStatus.confirmed));
      expect(statuses, contains(BookingStatus.active));
      expect(statuses, contains(BookingStatus.completed));
      expect(statuses, contains(BookingStatus.cancelled));
    });

    test('verifies all sample bookings have strictly positive duration and valid intervals', () {
      final bookings = SmartParkLocalData.createInitialBookings();
      for (final booking in bookings) {
        expect(booking.endTime.isAfter(booking.startTime), isTrue);
        expect(booking.duration.inMinutes, greaterThan(0));
        expect(booking.slotId.isNotEmpty, isTrue);
      }
    });
  });

  group('SmartParkLocalData - Service Initialization', () {
    test('initializeServices wires all 4 services into facade with local data', () {
      final dsaService = SmartParkLocalData.initializeServices();

      // Slot registry verification
      expect(dsaService.slotService.slotCount, equals(20));
      expect(dsaService.findSlot('P01'), isNotNull);
      expect(dsaService.findSlot('P20'), isNotNull);

      // Conflict validation verification (B01 is on P04 from 14:00 to 16:00)
      final conflict = dsaService.checkTimeConflict(
        'P04',
        DateTime(2026, 11, 11, 14, 30),
        DateTime(2026, 11, 11, 15, 30),
      );
      expect(conflict, isTrue);

      // Non-conflicting window
      final noConflict = dsaService.checkTimeConflict(
        'P04',
        DateTime(2026, 11, 11, 16, 0),
        DateTime(2026, 11, 11, 17, 0),
      );
      expect(noConflict, isFalse);

      // Navigation verification
      final route = dsaService.findRouteToSlot('P01');
      expect(route, isNotNull);
      expect(route!.hasPath, isTrue);
      expect(route.distance, equals(9.5));

      // Recommendation verification (P01 is available and 9.5m away)
      final recommendations = dsaService.getRecommendations(limit: 3);
      expect(recommendations.isNotEmpty, isTrue);
      expect(recommendations.first.slot.slotCode, equals('P01'));
      expect(recommendations.first.distance, equals(9.5));
    });
  });
}
