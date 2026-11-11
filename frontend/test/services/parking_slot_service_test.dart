import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/parking_slot_service.dart';

void main() {
  group('ParkingSlotService (Custom HashMap Integration)', () {
    late ParkingSlotService service;

    final slotA1 = ParkingSlot(
      id: 'slot-uuid-001',
      slotCode: 'P01',
      row: SlotRow.a,
      status: SlotStatus.available,
      isActive: true,
      navigationNodeId: 'NODE_P01',
      x: 6.0,
      y: 13.5,
    );

    final slotA2 = ParkingSlot(
      id: 'slot-uuid-002',
      slotCode: 'P02',
      row: SlotRow.a,
      status: SlotStatus.occupied,
      isActive: true,
      navigationNodeId: 'NODE_P02',
      x: 9.0,
      y: 13.5,
    );

    final slotB11 = ParkingSlot(
      id: 'slot-uuid-011',
      slotCode: 'P11',
      row: SlotRow.b,
      status: SlotStatus.available,
      isActive: true,
      navigationNodeId: 'NODE_P11',
      x: 6.0,
      y: 2.5,
    );

    setUp(() {
      service = ParkingSlotService();
    });

    test('initializes empty registry by default', () {
      expect(service.slotCount, equals(0));
      expect(service.isEmpty, isTrue);
      expect(service.isNotEmpty, isFalse);
      expect(service.getAllSlots(), isEmpty);
    });

    test('initializes with a collection of ParkingSlot objects', () {
      final initialized = ParkingSlotService([slotA1, slotA2, slotB11]);
      expect(initialized.slotCount, equals(3));
      expect(initialized.hasSlot('P01'), isTrue);
      expect(initialized.hasSlot('P02'), isTrue);
      expect(initialized.hasSlot('P11'), isTrue);
      expect(initialized.getSlot('P01'), equals(slotA1));
    });

    test('retrieves slot by slotCode with case and whitespace trimming', () {
      service.registerSlot(slotA1);
      expect(service.getSlot('P01'), equals(slotA1));
      expect(service.getSlot('p01'), equals(slotA1));
      expect(service.getSlot('  P01  '), equals(slotA1));
      expect(service.hasSlot('P01'), isTrue);
      expect(service.hasSlot('p01'), isTrue);
    });

    test('missing slot lookup returns null and hasSlot returns false', () {
      service.registerSlot(slotA1);
      expect(service.getSlot('P99'), isNull);
      expect(service.hasSlot('P99'), isFalse);
    });

    test('indexes strictly on slotCode and not model id', () {
      // Model id is 'slot-uuid-001', slotCode is 'P01'
      service.registerSlot(slotA1);
      expect(service.hasSlot('P01'), isTrue);
      expect(service.getSlot('P01'), equals(slotA1));
      expect(service.hasSlot('slot-uuid-001'), isFalse);
      expect(service.getSlot('slot-uuid-001'), isNull);
    });

    test('adding slots increments count and updates registry', () {
      service.registerSlot(slotA1);
      expect(service.slotCount, equals(1));
      expect(service.isEmpty, isFalse);
      expect(service.isNotEmpty, isTrue);

      service.registerSlot(slotB11);
      expect(service.slotCount, equals(2));
      expect(service.getAllSlots(), containsAll([slotA1, slotB11]));
    });

    test('rejects duplicate slot codes on registerSlot', () {
      service.registerSlot(slotA1);

      final duplicateSlot = ParkingSlot(
        id: 'slot-diff-id',
        slotCode: 'P01',
        row: SlotRow.a,
      );

      expect(
        () => service.registerSlot(duplicateSlot),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('already registered'),
        )),
      );
    });

    test('updating existing slot succeeds and preserves count', () {
      service.registerSlot(slotA1);
      expect(service.getSlot('P01')!.status, equals(SlotStatus.available));

      final updated = slotA1.copyWith(status: SlotStatus.occupied);
      service.updateSlot(updated);

      expect(service.slotCount, equals(1));
      expect(service.getSlot('P01')!.status, equals(SlotStatus.occupied));
    });

    test('updating unregistered slot throws ArgumentError', () {
      expect(
        () => service.updateSlot(slotA1),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot update unregistered slot'),
        )),
      );
    });

    test('registerOrUpdate adds when missing and updates when present', () {
      service.registerOrUpdate(slotA1);
      expect(service.slotCount, equals(1));

      final modified = slotA1.copyWith(status: SlotStatus.reserved);
      service.registerOrUpdate(modified);
      expect(service.slotCount, equals(1));
      expect(service.getSlot('P01')!.status, equals(SlotStatus.reserved));
    });

    test('removing slot unlinks it and decreases count', () {
      service.registerSlot(slotA1);
      service.registerSlot(slotA2);
      expect(service.slotCount, equals(2));

      final removed = service.removeSlot('P01');
      expect(removed, equals(slotA1));
      expect(service.slotCount, equals(1));
      expect(service.hasSlot('P01'), isFalse);
      expect(service.getSlot('P01'), isNull);

      // Second removal returns null
      final secondRemoval = service.removeSlot('P01');
      expect(secondRemoval, isNull);
      expect(service.slotCount, equals(1));
    });

    test('clear resets the registry completely', () {
      service.registerSlot(slotA1);
      service.registerSlot(slotA2);
      service.registerSlot(slotB11);
      expect(service.slotCount, equals(3));

      service.clear();
      expect(service.slotCount, equals(0));
      expect(service.isEmpty, isTrue);
      expect(service.getAllSlots(), isEmpty);
    });

    test('empty or blank slotCode throws ArgumentError', () {
      expect(() => service.getSlot(''), throwsArgumentError);
      expect(() => service.getSlot('   '), throwsArgumentError);
      expect(() => service.hasSlot(''), throwsArgumentError);
      expect(() => service.removeSlot(''), throwsArgumentError);
    });
  });
}

