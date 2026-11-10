import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/models/booking.dart';

void main() {
  group('Booking Model', () {
    final t1000 = DateTime.utc(2026, 11, 10, 10, 0);
    final t1100 = DateTime.utc(2026, 11, 10, 11, 0);
    final t1200 = DateTime.utc(2026, 11, 10, 12, 0);
    final t1300 = DateTime.utc(2026, 11, 10, 13, 0);

    test('creates valid Booking with default and explicit properties', () {
      final booking = Booking(
        id: 'bk-001',
        slotId: 'P01',
        startTime: t1000,
        endTime: t1200,
        userId: 'usr-101',
        vehicleNumber: 'KA-01-AB-1234',
        createdAt: t1000,
      );

      expect(booking.id, 'bk-001');
      expect(booking.slotId, 'P01');
      expect(booking.startTime, t1000);
      expect(booking.endTime, t1200);
      expect(booking.status, BookingStatus.confirmed);
      expect(booking.userId, 'usr-101');
      expect(booking.vehicleNumber, 'KA-01-AB-1234');
      expect(booking.createdAt, t1000);
      expect(booking.duration, const Duration(hours: 2));
    });

    group('validation', () {
      test('throws ArgumentError when endTime is equal to startTime', () {
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: 'P01',
            startTime: t1000,
            endTime: t1000,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when endTime is earlier than startTime', () {
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: 'P01',
            startTime: t1200,
            endTime: t1000,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when id is empty', () {
        expect(
          () => Booking(
            id: '',
            slotId: 'P01',
            startTime: t1000,
            endTime: t1100,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Booking(
            id: '   ',
            slotId: 'P01',
            startTime: t1000,
            endTime: t1100,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when slotId is empty', () {
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: '',
            startTime: t1000,
            endTime: t1100,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: '   ',
            startTime: t1000,
            endTime: t1100,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when provided optional strings are blank', () {
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: 'P01',
            startTime: t1000,
            endTime: t1100,
            userId: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Booking(
            id: 'bk-001',
            slotId: 'P01',
            startTime: t1000,
            endTime: t1100,
            vehicleNumber: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('half-open interval overlap rules [start, end)', () {
      test('adjacent bookings on same slot do NOT overlap (back-to-back reservations)', () {
        // Booking A: [10:00, 11:00)
        final bookingA = Booking(
          id: 'bk-a',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1100,
        );

        // Booking B: [11:00, 12:00)
        final bookingB = Booking(
          id: 'bk-b',
          slotId: 'P01',
          startTime: t1100,
          endTime: t1200,
        );

        expect(bookingA.overlaps(bookingB), isFalse);
        expect(bookingB.overlaps(bookingA), isFalse);
      });

      test('overlapping bookings on same slot report true', () {
        // Booking A: [10:00, 12:00)
        final bookingA = Booking(
          id: 'bk-a',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1200,
        );

        // Booking B: [11:00, 13:00) - starts before A ends
        final bookingB = Booking(
          id: 'bk-b',
          slotId: 'P01',
          startTime: t1100,
          endTime: t1300,
        );

        expect(bookingA.overlaps(bookingB), isTrue);
        expect(bookingB.overlaps(bookingA), isTrue);
      });

      test('enclosed booking reports overlap', () {
        // Outer: [10:00, 13:00)
        final outer = Booking(
          id: 'bk-outer',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1300,
        );

        // Inner: [11:00, 12:00)
        final inner = Booking(
          id: 'bk-inner',
          slotId: 'P01',
          startTime: t1100,
          endTime: t1200,
        );

        expect(outer.overlaps(inner), isTrue);
        expect(inner.overlaps(outer), isTrue);
      });

      test('completely disjoint bookings report no overlap', () {
        // A: [10:00, 11:00)
        final bookingA = Booking(
          id: 'bk-a',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1100,
        );

        // B: [12:00, 13:00)
        final bookingB = Booking(
          id: 'bk-b',
          slotId: 'P01',
          startTime: t1200,
          endTime: t1300,
        );

        expect(bookingA.overlaps(bookingB), isFalse);
        expect(bookingB.overlaps(bookingA), isFalse);
      });

      test('bookings for different slots NEVER conflict even with identical times', () {
        final bookingSlot1 = Booking(
          id: 'bk-1',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1200,
        );
        final bookingSlot2 = Booking(
          id: 'bk-2',
          slotId: 'P02',
          startTime: t1000,
          endTime: t1200,
        );

        expect(bookingSlot1.overlaps(bookingSlot2), isFalse);
        expect(bookingSlot2.overlaps(bookingSlot1), isFalse);
      });

      test('overlapsInterval checks against query start and end', () {
        final booking = Booking(
          id: 'bk-001',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1200,
        );

        // Touching boundary: [12:00, 13:00) -> false
        expect(booking.overlapsInterval(t1200, t1300), isFalse);

        // Inside window: [10:30, 11:30) -> true
        final t1030 = DateTime.utc(2026, 11, 10, 10, 30);
        final t1130 = DateTime.utc(2026, 11, 10, 11, 30);
        expect(booking.overlapsInterval(t1030, t1130), isTrue);

        // Invalid query times throw ArgumentError
        expect(
          () => booking.overlapsInterval(t1200, t1000),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('copyWith and equality', () {
      test('copyWith copies fields with overrides', () {
        final original = Booking(
          id: 'bk-001',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1100,
          status: BookingStatus.confirmed,
        );

        final updated = original.copyWith(
          status: BookingStatus.active,
          vehicleNumber: 'KA-01-AB-9999',
        );

        expect(updated.id, 'bk-001');
        expect(updated.slotId, 'P01');
        expect(updated.status, BookingStatus.active);
        expect(updated.vehicleNumber, 'KA-01-AB-9999');
        expect(updated.startTime, t1000);
      });

      test('equality matches identical objects', () {
        final bk1 = Booking(
          id: 'bk-001',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1100,
        );
        final bk2 = Booking(
          id: 'bk-001',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1100,
        );

        expect(bk1, equals(bk2));
        expect(bk1.hashCode, equals(bk2.hashCode));
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON correctly', () {
        final booking = Booking(
          id: 'bk-101',
          slotId: 'P01',
          startTime: t1000,
          endTime: t1200,
          status: BookingStatus.confirmed,
          userId: 'usr-501',
          vehicleNumber: 'KA-01-AB-1234',
          createdAt: t1000,
        );

        final json = booking.toJson();

        expect(json['id'], 'bk-101');
        expect(json['slotId'], 'P01');
        expect(json['startTime'], t1000.toIso8601String());
        expect(json['endTime'], t1200.toIso8601String());
        expect(json['status'], 'CONFIRMED');
        expect(json['userId'], 'usr-501');
        expect(json['vehicleNumber'], 'KA-01-AB-1234');
        expect(json['createdAt'], t1000.toIso8601String());
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'id': 'bk-102',
          'slotId': 'P02',
          'startTime': '2026-11-10T10:00:00.000Z',
          'endTime': '2026-11-10T11:00:00.000Z',
          'status': 'ACTIVE',
          'userId': 'usr-502',
          'vehicleNumber': 'MH-12-CD-5678',
        };

        final booking = Booking.fromJson(json);

        expect(booking.id, 'bk-102');
        expect(booking.slotId, 'P02');
        expect(booking.startTime, DateTime.parse('2026-11-10T10:00:00.000Z'));
        expect(booking.endTime, DateTime.parse('2026-11-10T11:00:00.000Z'));
        expect(booking.status, BookingStatus.active);
        expect(booking.userId, 'usr-502');
        expect(booking.vehicleNumber, 'MH-12-CD-5678');
      });
    });

    group('BookingStatus enum', () {
      test('fromString parses all booking states', () {
        expect(BookingStatus.fromString('CONFIRMED'), BookingStatus.confirmed);
        expect(BookingStatus.fromString('active'), BookingStatus.active);
        expect(BookingStatus.fromString('COMPLETED'), BookingStatus.completed);
        expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
        expect(
          () => BookingStatus.fromString('INVALID'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

