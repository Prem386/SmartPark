import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/models/parking_slot.dart';

void main() {
  group('ParkingSlot Model', () {
    test('creates valid ParkingSlot with default and explicit properties', () {
      final slot = ParkingSlot(
        id: 'P01',
        row: SlotRow.a,
        navigationNodeId: 'NODE_P01',
        x: 6.0,
        y: 13.5,
      );

      expect(slot.id, 'P01');
      expect(slot.slotCode, 'P01');
      expect(slot.row, SlotRow.a);
      expect(slot.floorNumber, 1);
      expect(slot.slotType, SlotType.standard);
      expect(slot.status, SlotStatus.available);
      expect(slot.navigationNodeId, 'NODE_P01');
      expect(slot.x, 6.0);
      expect(slot.y, 13.5);
      expect(slot.isActive, isTrue);
      expect(slot.isAvailable, isTrue);
    });

    test('supports custom slotCode and alternate states', () {
      final slot = ParkingSlot(
        id: 'slot-11',
        slotCode: 'P11',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        isActive: true,
      );

      expect(slot.id, 'slot-11');
      expect(slot.slotCode, 'P11');
      expect(slot.row, SlotRow.b);
      expect(slot.status, SlotStatus.occupied);
      expect(slot.isAvailable, isFalse);
    });

    test('isAvailable is false when isActive is false even if status is available', () {
      final slot = ParkingSlot(
        id: 'P02',
        row: SlotRow.a,
        status: SlotStatus.available,
        isActive: false,
      );

      expect(slot.isAvailable, isFalse);
    });

    group('validation', () {
      test('throws ArgumentError on empty id', () {
        expect(
          () => ParkingSlot(id: '', row: SlotRow.a),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ParkingSlot(id: '   ', row: SlotRow.a),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError on empty slotCode', () {
        expect(
          () => ParkingSlot(id: 'P01', slotCode: '', row: SlotRow.a),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ParkingSlot(id: 'P01', slotCode: '   ', row: SlotRow.a),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError on non-positive floor number', () {
        expect(
          () => ParkingSlot(id: 'P01', row: SlotRow.a, floorNumber: 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ParkingSlot(id: 'P01', row: SlotRow.a, floorNumber: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError on negative coordinates', () {
        expect(
          () => ParkingSlot(id: 'P01', row: SlotRow.a, x: -1.0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ParkingSlot(id: 'P01', row: SlotRow.a, y: -0.5),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('copyWith and equality', () {
      test('copyWith updates specified fields and preserves others', () {
        final original = ParkingSlot(
          id: 'P05',
          row: SlotRow.a,
          x: 18.0,
          y: 13.5,
        );

        final updated = original.copyWith(
          status: SlotStatus.occupied,
          navigationNodeId: 'NODE_P05',
        );

        expect(updated.id, 'P05');
        expect(updated.status, SlotStatus.occupied);
        expect(updated.navigationNodeId, 'NODE_P05');
        expect(updated.x, 18.0);
        expect(updated.y, 13.5);
        expect(updated.row, SlotRow.a);
      });

      test('equality and hashCode match for identical field values', () {
        final slotA = ParkingSlot(
          id: 'P03',
          row: SlotRow.a,
          x: 12.0,
          y: 13.5,
          navigationNodeId: 'NODE_P03',
        );
        final slotB = ParkingSlot(
          id: 'P03',
          row: SlotRow.a,
          x: 12.0,
          y: 13.5,
          navigationNodeId: 'NODE_P03',
        );

        expect(slotA, equals(slotB));
        expect(slotA.hashCode, equals(slotB.hashCode));
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON accurately', () {
        final slot = ParkingSlot(
          id: 'P01',
          row: SlotRow.a,
          floorNumber: 1,
          slotType: SlotType.standard,
          status: SlotStatus.available,
          navigationNodeId: 'NODE_P01',
          x: 6.0,
          y: 13.5,
          isActive: true,
        );

        final json = slot.toJson();

        expect(json['id'], 'P01');
        expect(json['slotCode'], 'P01');
        expect(json['row'], 'A');
        expect(json['floorNumber'], 1);
        expect(json['slotType'], 'STANDARD');
        expect(json['status'], 'AVAILABLE');
        expect(json['navigationNodeId'], 'NODE_P01');
        expect(json['x'], 6.0);
        expect(json['y'], 13.5);
        expect(json['isActive'], isTrue);
      });

      test('deserializes from JSON with explicit row', () {
        final json = {
          'id': 'P04',
          'slotCode': 'P04',
          'row': 'Row A',
          'floorNumber': 1,
          'slotType': 'STANDARD',
          'status': 'RESERVED',
          'navigationNodeId': 'NODE_P04',
          'x': 15.0,
          'y': 13.5,
          'isActive': true,
        };

        final slot = ParkingSlot.fromJson(json);

        expect(slot.id, 'P04');
        expect(slot.slotCode, 'P04');
        expect(slot.row, SlotRow.a);
        expect(slot.status, SlotStatus.reserved);
        expect(slot.x, 15.0);
        expect(slot.y, 13.5);
      });

      test('infers row during JSON deserialization when row is omitted', () {
        final jsonA = {
          'id': 'P02',
          'slotCode': 'P02',
          'floorNumber': 1,
          'slotType': 'STANDARD',
          'status': 'AVAILABLE',
        };
        final jsonB = {
          'id': 'P15',
          'slotCode': 'P15',
          'floorNumber': 1,
          'slotType': 'STANDARD',
          'status': 'AVAILABLE',
        };

        final slotA = ParkingSlot.fromJson(jsonA);
        final slotB = ParkingSlot.fromJson(jsonB);

        expect(slotA.row, SlotRow.a);
        expect(slotB.row, SlotRow.b);
      });
    });

    group('SlotRow and SlotStatus enums', () {
      test('SlotRow.fromString parses various representations', () {
        expect(SlotRow.fromString('A'), SlotRow.a);
        expect(SlotRow.fromString('a'), SlotRow.a);
        expect(SlotRow.fromString('Row A'), SlotRow.a);
        expect(SlotRow.fromString('ROW_A'), SlotRow.a);
        expect(SlotRow.fromString('B'), SlotRow.b);
        expect(SlotRow.fromString('b'), SlotRow.b);
        expect(SlotRow.fromString('Row B'), SlotRow.b);
        expect(SlotRow.fromString('ROW_B'), SlotRow.b);
        expect(
          () => SlotRow.fromString('C'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('SlotStatus.fromString parses all standard states', () {
        expect(SlotStatus.fromString('AVAILABLE'), SlotStatus.available);
        expect(SlotStatus.fromString('occupied'), SlotStatus.occupied);
        expect(SlotStatus.fromString('RESERVED'), SlotStatus.reserved);
        expect(SlotStatus.fromString('maintenance'), SlotStatus.maintenance);
        expect(
          () => SlotStatus.fromString('UNKNOWN'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('SlotType.fromString handles standard type', () {
        expect(SlotType.fromString('STANDARD'), SlotType.standard);
        expect(SlotType.fromString('standard'), SlotType.standard);
        expect(
          () => SlotType.fromString('EV_CHARGING'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

