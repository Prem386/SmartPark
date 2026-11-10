/// Lifecycle status of a parking booking.
enum BookingStatus {
  confirmed,
  active,
  completed,
  cancelled;

  /// Parses a string into a [BookingStatus].
  static BookingStatus fromString(String value) {
    final normalized = value.trim().toUpperCase();
    for (final status in BookingStatus.values) {
      if (status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'Invalid booking status: $value');
  }
}

/// Represents a reservation for a designated parking bay across a time interval.
///
/// Follows the half-open interval convention `[startTime, endTime)` where:
/// - Start time is inclusive.
/// - End time is exclusive.
/// - Adjacent bookings (e.g. 10:00-11:00 and 11:00-12:00) do not overlap.
///
/// // ponytail: direct DateTime interval logic on model; pricing excluded per Phase 2.1 design
class Booking {
  /// Unique identifier for this booking reservation.
  final String id;

  /// Identifier of the allocated parking slot (e.g. 'P01').
  final String slotId;

  /// Reservation start time (inclusive).
  final DateTime startTime;

  /// Reservation end time (exclusive). Must be strictly after [startTime].
  final DateTime endTime;

  /// Current reservation status.
  final BookingStatus status;

  /// Optional customer / user identifier.
  final String? userId;

  /// Optional vehicle registration number (e.g. 'KA-01-AB-1234').
  final String? vehicleNumber;

  /// Optional timestamp recording when this booking was created.
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    this.status = BookingStatus.confirmed,
    this.userId,
    this.vehicleNumber,
    this.createdAt,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Booking id cannot be empty');
    }
    if (slotId.trim().isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'Slot id cannot be empty');
    }
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'Booking end time (${endTime.toIso8601String()}) must be strictly '
        'later than start time (${startTime.toIso8601String()})',
      );
    }
    if (userId != null && userId!.trim().isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'User id cannot be empty when provided',
      );
    }
    if (vehicleNumber != null && vehicleNumber!.trim().isEmpty) {
      throw ArgumentError.value(
        vehicleNumber,
        'vehicleNumber',
        'Vehicle number cannot be empty when provided',
      );
    }
  }

  /// Total duration of the reserved parking interval.
  Duration get duration => endTime.difference(startTime);

  /// Checks if this booking overlaps with another booking for the same slot.
  ///
  /// Uses the half-open interval convention `[start, end)`.
  /// Adjacent intervals (e.g. 10:00-11:00 and 11:00-12:00) do NOT overlap.
  /// Bookings for different slots never conflict.
  bool overlaps(Booking other) {
    if (slotId != other.slotId) {
      return false;
    }
    return overlapsInterval(other.startTime, other.endTime);
  }

  /// Checks if this booking's time window overlaps with a query `[start, end)` window.
  ///
  /// Two half-open intervals `[s1, e1)` and `[s2, e2)` overlap if and only if:
  /// `s1 < e2` AND `s2 < e1`.
  bool overlapsInterval(DateTime start, DateTime end) {
    if (!end.isAfter(start)) {
      throw ArgumentError(
        'Query end time (${end.toIso8601String()}) must be strictly '
        'later than start time (${start.toIso8601String()})',
      );
    }
    return startTime.isBefore(end) && start.isBefore(endTime);
  }

  /// Creates a copy of this booking with updated fields.
  Booking copyWith({
    String? id,
    String? slotId,
    DateTime? startTime,
    DateTime? endTime,
    BookingStatus? status,
    String? userId,
    String? vehicleNumber,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Deserializes a [Booking] from a JSON map.
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      slotId: json['slotId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] != null
          ? BookingStatus.fromString(json['status'] as String)
          : BookingStatus.confirmed,
      userId: json['userId'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Serializes this [Booking] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slotId': slotId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.name.toUpperCase(),
      if (userId != null) 'userId': userId,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slotId == other.slotId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status &&
          userId == other.userId &&
          vehicleNumber == other.vehicleNumber &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        slotId,
        startTime,
        endTime,
        status,
        userId,
        vehicleNumber,
        createdAt,
      );

  @override
  String toString() {
    return 'Booking(id: $id, slotId: $slotId, '
        '${startTime.toIso8601String()} -> ${endTime.toIso8601String()}, '
        'status: ${status.name})';
  }
}

