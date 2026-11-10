/// Parking bay row in the facility layout.
///
/// In the approved facility design, Row A is on the North side (P01-P10)
/// and Row B is on the South side (P11-P20).
enum SlotRow {
  a('Row A (North)'),
  b('Row B (South)');

  const SlotRow(this.displayName);

  /// Human-friendly row description.
  final String displayName;

  /// Parses a string into a [SlotRow].
  ///
  /// Supports values like 'A', 'B', 'Row A', 'Row B', 'ROW_A', 'ROW_B'.
  static SlotRow fromString(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'A' ||
        normalized == 'ROW A' ||
        normalized == 'ROW_A' ||
        normalized.contains('ROW A')) {
      return SlotRow.a;
    }
    if (normalized == 'B' ||
        normalized == 'ROW B' ||
        normalized == 'ROW_B' ||
        normalized.contains('ROW B')) {
      return SlotRow.b;
    }
    throw ArgumentError.value(value, 'value', 'Invalid slot row: $value');
  }
}

/// Category of parking space.
///
/// // ponytail: prototype uses uniform STANDARD slots; specialized types excluded per Phase 2.1 design
enum SlotType {
  standard;

  /// Parses a string into a [SlotType].
  static SlotType fromString(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'STANDARD') {
      return SlotType.standard;
    }
    throw ArgumentError.value(value, 'value', 'Invalid slot type: $value');
  }
}

/// Operational state of a parking bay.
enum SlotStatus {
  available,
  occupied,
  reserved,
  maintenance;

  /// Parses a string into a [SlotStatus].
  static SlotStatus fromString(String value) {
    final normalized = value.trim().toUpperCase();
    for (final status in SlotStatus.values) {
      if (status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'Invalid slot status: $value');
  }
}

/// Represents an individual physical parking bay in the facility.
///
/// // ponytail: single floor, no pricing/billing attributes, direct coordinate fields
class ParkingSlot {
  /// Unique slot identifier (e.g. 'P01').
  final String id;

  /// Display code for the slot (defaults to [id]).
  final String slotCode;

  /// Row where the slot is situated (Row A or Row B).
  final SlotRow row;

  /// Floor level where the bay resides (defaults to 1).
  final int floorNumber;

  /// Classification of the bay (uniform [SlotType.standard] for prototype).
  final SlotType slotType;

  /// Current availability state.
  final SlotStatus status;

  /// Associated navigation graph node ID (e.g. 'NODE_P01').
  final String? navigationNodeId;

  /// Center X coordinate in meters from origin (West boundary).
  final double? x;

  /// Center Y coordinate in meters from origin (South boundary).
  final double? y;

  /// Whether the slot is currently active and operational.
  final bool isActive;

  ParkingSlot({
    required this.id,
    String? slotCode,
    required this.row,
    this.floorNumber = 1,
    this.slotType = SlotType.standard,
    this.status = SlotStatus.available,
    this.navigationNodeId,
    this.x,
    this.y,
    this.isActive = true,
  }) : slotCode = slotCode ?? id {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Slot id cannot be empty');
    }
    if (this.slotCode.trim().isEmpty) {
      throw ArgumentError.value(
        this.slotCode,
        'slotCode',
        'Slot code cannot be empty',
      );
    }
    if (floorNumber <= 0) {
      throw ArgumentError.value(
        floorNumber,
        'floorNumber',
        'Floor number must be positive',
      );
    }
    if (x != null && x! < 0) {
      throw ArgumentError.value(x, 'x', 'Coordinate x cannot be negative');
    }
    if (y != null && y! < 0) {
      throw ArgumentError.value(y, 'y', 'Coordinate y cannot be negative');
    }
  }

  /// Convenience getter checking if this slot is ready for immediate reservation.
  bool get isAvailable => isActive && status == SlotStatus.available;

  /// Creates a copy of this slot with updated properties.
  ParkingSlot copyWith({
    String? id,
    String? slotCode,
    SlotRow? row,
    int? floorNumber,
    SlotType? slotType,
    SlotStatus? status,
    String? navigationNodeId,
    double? x,
    double? y,
    bool? isActive,
  }) {
    return ParkingSlot(
      id: id ?? this.id,
      slotCode: slotCode ?? this.slotCode,
      row: row ?? this.row,
      floorNumber: floorNumber ?? this.floorNumber,
      slotType: slotType ?? this.slotType,
      status: status ?? this.status,
      navigationNodeId: navigationNodeId ?? this.navigationNodeId,
      x: x ?? this.x,
      y: y ?? this.y,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Deserializes a [ParkingSlot] from a JSON map.
  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final slotCode = json['slotCode'] as String? ?? id;

    // Resolve row from explicit attribute or infer from slotCode convention
    SlotRow resolvedRow;
    final rawRow = json['row'];
    if (rawRow != null && rawRow is String && rawRow.trim().isNotEmpty) {
      resolvedRow = SlotRow.fromString(rawRow);
    } else {
      // In approved layout: P01-P10 is Row A, P11-P20 is Row B
      final match = RegExp(r'^P(\d+)$', caseSensitive: false).firstMatch(slotCode.trim());
      if (match != null) {
        final slotNum = int.tryParse(match.group(1)!);
        if (slotNum != null && slotNum >= 1 && slotNum <= 10) {
          resolvedRow = SlotRow.a;
        } else if (slotNum != null && slotNum >= 11 && slotNum <= 20) {
          resolvedRow = SlotRow.b;
        } else {
          throw ArgumentError('Cannot infer row from slot code: $slotCode');
        }
      } else {
        throw ArgumentError('Missing required row information for slot: $slotCode');
      }
    }

    return ParkingSlot(
      id: id,
      slotCode: slotCode,
      row: resolvedRow,
      floorNumber: json['floorNumber'] as int? ?? 1,
      slotType: json['slotType'] != null
          ? SlotType.fromString(json['slotType'] as String)
          : SlotType.standard,
      status: json['status'] != null
          ? SlotStatus.fromString(json['status'] as String)
          : SlotStatus.available,
      navigationNodeId: json['navigationNodeId'] as String?,
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serializes this [ParkingSlot] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slotCode': slotCode,
      'row': row.name.toUpperCase(),
      'floorNumber': floorNumber,
      'slotType': slotType.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      if (navigationNodeId != null) 'navigationNodeId': navigationNodeId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slotCode == other.slotCode &&
          row == other.row &&
          floorNumber == other.floorNumber &&
          slotType == other.slotType &&
          status == other.status &&
          navigationNodeId == other.navigationNodeId &&
          x == other.x &&
          y == other.y &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        slotCode,
        row,
        floorNumber,
        slotType,
        status,
        navigationNodeId,
        x,
        y,
        isActive,
      );

  @override
  String toString() {
    return 'ParkingSlot(id: $id, slotCode: $slotCode, row: ${row.name.toUpperCase()}, '
        'status: ${status.name}, floor: $floorNumber)';
  }
}

