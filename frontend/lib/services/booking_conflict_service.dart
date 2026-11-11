import '../dsa/interval_tree/interval_tree.dart';
import '../models/booking.dart';

/// Exception thrown when a reservation conflicts with an existing booking.
class BookingConflictException implements Exception {
  /// Explanation of the conflict.
  final String message;

  /// The existing bookings that caused the conflict.
  final List<Booking> conflictingBookings;

  const BookingConflictException(this.message, [this.conflictingBookings = const []]);

  @override
  String toString() =>
      'BookingConflictException: $message (conflicts: ${conflictingBookings.length})';
}

/// Application service managing in-memory booking conflict validation.
///
/// Backed by [CustomIntervalTree] (augmented AVL tree) for $O(\log n)$ average
/// temporal overlap queries.
///
/// Business Rules:
/// 1. Intervals use half-open semantics `[startTime, endTime)`: start inclusive, end exclusive.
/// 2. Contiguous / adjacent intervals (e.g. 10:00-11:00 and 11:00-12:00) do NOT conflict.
/// 3. Conflicts are evaluated strictly on the same [Booking.slotId]. Different slots never conflict.
/// 4. Status Filtering: Only blocking statuses ([BookingStatus.confirmed] and [BookingStatus.active])
///    cause conflicts. Non-blocking statuses ([BookingStatus.completed] and [BookingStatus.cancelled])
///    do NOT block future reservations.
///
/// Important Architectural Boundary:
/// This service provides fast, client-side optimistic conflict validation to deliver immediate
/// user feedback before network submission. It is NOT the authoritative booking validation mechanism.
/// The Spring Boot backend performs transactional validation against persistent storage.
///
/// // ponytail: leverages CustomIntervalTree directly; status filtering kept in service layer
class BookingConflictService {
  final CustomIntervalTree _tree;

  /// Creates a [BookingConflictService] optionally populated with [initialBookings].
  BookingConflictService([Iterable<Booking>? initialBookings])
      : _tree = CustomIntervalTree() {
    if (initialBookings != null) {
      for (final booking in initialBookings) {
        // Initial load registers without re-validating conflicts (e.g., loading historical data)
        _tree.insert(booking);
      }
    }
  }

  /// Whether a booking status is considered blocking for reservations.
  ///
  /// Per `DATABASE_DESIGN.md` Section 3.3, only `CONFIRMED` and `ACTIVE` bookings
  /// reserve a physical slot. `COMPLETED` and `CANCELLED` bookings release it.
  static bool isBlockingStatus(BookingStatus status) {
    return status == BookingStatus.confirmed || status == BookingStatus.active;
  }

  /// Finds all blocking bookings for [slotId] that overlap `[startTime, endTime)`.
  ///
  /// Optionally excludes a booking matching [excludeBookingId] (useful when editing an existing booking).
  List<Booking> getConflictingBookings(
    String slotId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeBookingId,
  }) {
    final normalizedSlotId = slotId.trim();
    if (normalizedSlotId.isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'Slot id cannot be empty.');
    }
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'End time (${endTime.toIso8601String()}) must be strictly later '
        'than start time (${startTime.toIso8601String()}).',
      );
    }

    final overlaps = _tree.searchOverlaps(startTime, endTime);
    return overlaps.where((b) {
      if (b.slotId != normalizedSlotId) return false;
      if (!isBlockingStatus(b.status)) return false;
      if (excludeBookingId != null && b.id == excludeBookingId) return false;
      return true;
    }).toList();
  }

  /// Checks if a prospective time window on [slotId] has any blocking conflict.
  bool hasConflict(
    String slotId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeBookingId,
  }) {
    return getConflictingBookings(
      slotId,
      startTime,
      endTime,
      excludeBookingId: excludeBookingId,
    ).isNotEmpty;
  }

  /// Checks if [booking] conflicts with any existing blocking booking.
  ///
  /// If [booking.status] is non-blocking (e.g. cancelled/completed), returns `false`.
  bool isBookingInConflict(Booking booking) {
    if (!isBlockingStatus(booking.status)) {
      return false;
    }
    return hasConflict(
      booking.slotId,
      booking.startTime,
      booking.endTime,
      excludeBookingId: booking.id,
    );
  }

  /// Validates and adds [booking] to the reservation index.
  ///
  /// Throws [ArgumentError] if a booking with identical [booking.id] already exists.
  /// Throws [BookingConflictException] if [booking] is blocking and overlaps with an existing
  /// blocking reservation on the same slot.
  void addBooking(Booking booking) {
    if (_tree.contains(booking.id)) {
      throw ArgumentError('Booking with id "${booking.id}" already exists.');
    }

    if (isBlockingStatus(booking.status)) {
      final conflicts = getConflictingBookings(
        booking.slotId,
        booking.startTime,
        booking.endTime,
      );
      if (conflicts.isNotEmpty) {
        throw BookingConflictException(
          'Reservation conflict on slot "${booking.slotId}" for window '
          '${booking.startTime.toIso8601String()} to ${booking.endTime.toIso8601String()}.',
          conflicts,
        );
      }
    }

    final inserted = _tree.insert(booking);
    if (!inserted) {
      throw StateError('Failed to insert booking "${booking.id}" into interval tree.');
    }
  }

  /// Removes a booking from the index by its unique [bookingId].
  ///
  /// Returns `true` if found and removed; `false` otherwise.
  bool removeBooking(String bookingId) {
    return _tree.remove(bookingId.trim());
  }

  /// Retrieves a booking by its [bookingId], or `null` if not found.
  Booking? getBooking(String bookingId) {
    return _tree.get(bookingId.trim());
  }

  /// Checks whether a booking with [bookingId] is tracked in the index.
  bool containsBooking(String bookingId) {
    return _tree.contains(bookingId.trim());
  }

  /// Returns an in-order list of all bookings stored in the index.
  List<Booking> getAllBookings() {
    return _tree.toList();
  }

  /// Total number of bookings currently in the index.
  int get bookingCount => _tree.size;

  /// Whether the booking index is empty.
  bool get isEmpty => _tree.isEmpty;

  /// Whether the booking index contains at least one booking.
  bool get isNotEmpty => _tree.isNotEmpty;

  /// Clears all bookings from the index.
  void clear() {
    _tree.clear();
  }

  /// Rebuilds the conflict index from [bookings], discarding previous entries.
  void rebuildIndex(Iterable<Booking> bookings) {
    _tree.clear();
    for (final booking in bookings) {
      _tree.insert(booking);
    }
  }
}

