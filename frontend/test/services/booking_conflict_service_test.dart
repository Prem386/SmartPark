import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/models/booking.dart';
import 'package:smartpark_app/services/booking_conflict_service.dart';

void main() {
  group('BookingConflictService (Custom Interval Tree Integration)', () {
    late BookingConflictService service;

    final baseTime = DateTime(2026, 11, 15, 10, 0); // 10:00

    Booking createBooking({
      required String id,
      required String slotId,
      required int startHour,
      required int endHour,
      BookingStatus status = BookingStatus.confirmed,
    }) {
      return Booking(
        id: id,
        slotId: slotId,
        startTime: DateTime(2026, 11, 15, startHour, 0),
        endTime: DateTime(2026, 11, 15, endHour, 0),
        status: status,
      );
    }

    setUp(() {
      service = BookingConflictService();
    });

    test('initializes empty service by default', () {
      expect(service.bookingCount, equals(0));
      expect(service.isEmpty, isTrue);
      expect(service.getAllBookings(), isEmpty);
    });

    test('initializes with a collection of existing bookings', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = createBooking(id: 'B2', slotId: 'P02', startHour: 10, endHour: 12);

      final initialized = BookingConflictService([b1, b2]);
      expect(initialized.bookingCount, equals(2));
      expect(initialized.containsBooking('B1'), isTrue);
      expect(initialized.containsBooking('B2'), isTrue);
    });

    test('adds non-conflicting bookings across disjoint times', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = createBooking(id: 'B2', slotId: 'P01', startHour: 14, endHour: 16);

      service.addBooking(b1);
      service.addBooking(b2);

      expect(service.bookingCount, equals(2));
      expect(service.hasConflict('P01', DateTime(2026, 11, 15, 12, 0), DateTime(2026, 11, 15, 14, 0)), isFalse);
    });

    test('rejects overlapping bookings for the same slot with BookingConflictException', () {
      final existing = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(existing);

      // Overlapping booking: 11:00 - 13:00 on P01
      final conflicting = createBooking(id: 'B2', slotId: 'P01', startHour: 11, endHour: 13);

      expect(service.isBookingInConflict(conflicting), isTrue);
      expect(
        () => service.addBooking(conflicting),
        throwsA(isA<BookingConflictException>().having(
          (e) => e.conflictingBookings,
          'conflictingBookings',
          contains(existing),
        )),
      );
      expect(service.bookingCount, equals(1));
    });

    test('allows adjacent bookings for the same slot under half-open semantics [start, end)', () {
      // B1: 10:00 to 12:00
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);

      // B2: 12:00 to 14:00 (adjacent back-to-back, shares boundary 12:00)
      final b2 = createBooking(id: 'B2', slotId: 'P01', startHour: 12, endHour: 14);
      expect(service.isBookingInConflict(b2), isFalse);
      expect(() => service.addBooking(b2), returnsNormally);

      // B3: 8:00 to 10:00 (adjacent immediately before B1)
      final b3 = createBooking(id: 'B3', slotId: 'P01', startHour: 8, endHour: 10);
      expect(service.isBookingInConflict(b3), isFalse);
      expect(() => service.addBooking(b3), returnsNormally);

      expect(service.bookingCount, equals(3));
    });

    test('allows overlapping bookings on different slots without conflict', () {
      // Both at 10:00 - 12:00 but different slots
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = createBooking(id: 'B2', slotId: 'P02', startHour: 10, endHour: 12);

      service.addBooking(b1);
      expect(service.isBookingInConflict(b2), isFalse);
      expect(() => service.addBooking(b2), returnsNormally);

      expect(service.bookingCount, equals(2));
    });

    group('Booking Status Filtering', () {
      test('CONFIRMED and ACTIVE bookings cause conflicts', () {
        final confirmed = createBooking(
          id: 'B1',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.confirmed,
        );
        service.addBooking(confirmed);

        final query1 = createBooking(
          id: 'Q1',
          slotId: 'P01',
          startHour: 11,
          endHour: 13,
        );
        expect(service.isBookingInConflict(query1), isTrue);

        service.clear();

        final active = createBooking(
          id: 'B2',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.active,
        );
        service.addBooking(active);
        expect(service.isBookingInConflict(query1), isTrue);
      });

      test('CANCELLED and COMPLETED bookings do NOT cause conflicts', () {
        final cancelled = createBooking(
          id: 'B_CANCELLED',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.cancelled,
        );
        service.addBooking(cancelled);

        // New prospective booking for the same slot and time window
        final newBooking = createBooking(
          id: 'B_NEW',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.confirmed,
        );

        // Cancelled booking does not block
        expect(service.isBookingInConflict(newBooking), isFalse);
        expect(() => service.addBooking(newBooking), returnsNormally);

        // Completed booking does not block either
        final completed = createBooking(
          id: 'B_COMPLETED',
          slotId: 'P02',
          startHour: 8,
          endHour: 10,
          status: BookingStatus.completed,
        );
        service.addBooking(completed);

        final queryOnP02 = createBooking(
          id: 'B_NEW_P02',
          slotId: 'P02',
          startHour: 9,
          endHour: 11,
          status: BookingStatus.confirmed,
        );
        expect(service.isBookingInConflict(queryOnP02), isFalse);
        expect(() => service.addBooking(queryOnP02), returnsNormally);
      });

      test('adding a non-blocking booking (cancelled/completed) is accepted even if it overlaps', () {
        final b1 = createBooking(
          id: 'B1',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.confirmed,
        );
        service.addBooking(b1);

        // Storing a historical/cancelled booking overlapping with B1 is allowed
        final bCancelled = createBooking(
          id: 'B2',
          slotId: 'P01',
          startHour: 10,
          endHour: 12,
          status: BookingStatus.cancelled,
        );
        expect(service.isBookingInConflict(bCancelled), isFalse);
        expect(() => service.addBooking(bCancelled), returnsNormally);
      });
    });

    test('rejects duplicate booking id with ArgumentError', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);

      final duplicateId = createBooking(id: 'B1', slotId: 'P02', startHour: 14, endHour: 16);
      expect(
        () => service.addBooking(duplicateId),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('retrieves and removes booking by ID', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);

      expect(service.getBooking('B1'), equals(b1));
      expect(service.containsBooking('B1'), isTrue);

      final removed = service.removeBooking('B1');
      expect(removed, isTrue);
      expect(service.getBooking('B1'), isNull);
      expect(service.containsBooking('B1'), isFalse);
      expect(service.bookingCount, equals(0));

      // Removing non-existent booking returns false
      expect(service.removeBooking('B1'), isFalse);
    });

    test('rebuildIndex clears previous entries and populates new bookings', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);
      expect(service.bookingCount, equals(1));

      final newBookings = [
        createBooking(id: 'B2', slotId: 'P02', startHour: 8, endHour: 9),
        createBooking(id: 'B3', slotId: 'P03', startHour: 9, endHour: 10),
      ];
      service.rebuildIndex(newBookings);

      expect(service.bookingCount, equals(2));
      expect(service.containsBooking('B1'), isFalse);
      expect(service.containsBooking('B2'), isTrue);
      expect(service.containsBooking('B3'), isTrue);
    });

    test('excludeBookingId allows booking modification without self-conflict', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);

      // Checking window for updating B1 should not conflict with itself if excluded
      expect(
        service.hasConflict(
          'P01',
          DateTime(2026, 11, 15, 10, 30),
          DateTime(2026, 11, 15, 12, 30),
          excludeBookingId: 'B1',
        ),
        isFalse,
      );

      // Without exclusion, it detects conflict
      expect(
        service.hasConflict(
          'P01',
          DateTime(2026, 11, 15, 10, 30),
          DateTime(2026, 11, 15, 12, 30),
        ),
        isTrue,
      );
    });

    test('updateBooking replaces existing booking in interval tree', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);

      final updated = b1.copyWith(status: BookingStatus.cancelled);
      final success = service.updateBooking(updated);

      expect(success, isTrue);
      expect(service.getBooking('B1')?.status, equals(BookingStatus.cancelled));
      // Cancelled booking no longer conflicts
      expect(service.hasConflict('P01', DateTime(2026, 11, 15, 10, 0), DateTime(2026, 11, 15, 12, 0)), isFalse);
    });

    test('cancelBooking marks booking as cancelled and unblocks slot window', () {
      final b1 = createBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      service.addBooking(b1);
      expect(service.hasConflict('P01', DateTime(2026, 11, 15, 10, 0), DateTime(2026, 11, 15, 12, 0)), isTrue);

      final cancelled = service.cancelBooking('B1');
      expect(cancelled.status, equals(BookingStatus.cancelled));
      expect(service.getBooking('B1')?.status, equals(BookingStatus.cancelled));
      expect(service.hasConflict('P01', DateTime(2026, 11, 15, 10, 0), DateTime(2026, 11, 15, 12, 0)), isFalse);
    });

    test('validates inputs and throws ArgumentError on invalid parameters', () {
      expect(
        () => service.hasConflict('', baseTime, baseTime.add(const Duration(hours: 1))),
        throwsArgumentError,
      );
      expect(
        () => service.hasConflict('P01', baseTime.add(const Duration(hours: 1)), baseTime),
        throwsArgumentError,
      );
    });
  });
}

