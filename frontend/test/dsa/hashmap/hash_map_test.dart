import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/hashmap/hash_map.dart';
import 'package:smartpark_app/models/parking_slot.dart';

/// Test helper key class with deterministically controlled `hashCode` and `==`.
///
/// Used to force bucket collisions and verify separate chaining traversals.
class TestHashKey {
  final String id;
  final int forcedHash;

  TestHashKey(this.id, this.forcedHash);

  @override
  int get hashCode => forcedHash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestHashKey && runtimeType == other.runtimeType && id == other.id;

  @override
  String toString() => 'TestHashKey($id, hash: $forcedHash)';
}

void main() {
  group('CustomHashMap - Basic Operations', () {
    late CustomHashMap<String, int> map;

    setUp(() {
      map = CustomHashMap<String, int>();
    });

    test('newly initialized map is empty with default capacity 16', () {
      expect(map.size, equals(0));
      expect(map.isEmpty, isTrue);
      expect(map.isNotEmpty, isFalse);
      expect(map.capacity, equals(16));
      expect(map.loadFactor, equals(0.0));
      expect(map.loadFactorThreshold, equals(0.75));
    });

    test('put inserts a single key-value pair and increments size', () {
      map.put('slotA', 101);

      expect(map.size, equals(1));
      expect(map.isEmpty, isFalse);
      expect(map.isNotEmpty, isTrue);
      expect(map.get('slotA'), equals(101));
      expect(map['slotA'], equals(101));
      expect(map.containsKey('slotA'), isTrue);
    });

    test('get returns null when key does not exist', () {
      expect(map.get('nonExistent'), isNull);
      expect(map['nonExistent'], isNull);
    });

    test('containsKey distinguishes existing from missing key', () {
      map.put('P01', 1);

      expect(map.containsKey('P01'), isTrue);
      expect(map.containsKey('P02'), isFalse);
    });

    test('put updates existing key value without incrementing size', () {
      map.put('slotA', 100);
      expect(map.size, equals(1));
      expect(map.get('slotA'), equals(100));

      map.put('slotA', 200);
      expect(map.size, equals(1));
      expect(map.get('slotA'), equals(200));
    });

    test('operator []= updates and operator [] retrieves', () {
      map['key1'] = 42;
      expect(map['key1'], equals(42));

      map['key1'] = 99;
      expect(map['key1'], equals(99));
      expect(map.size, equals(1));
    });

    test('remove removes existing key and returns its value', () {
      map.put('slotA', 50);
      map.put('slotB', 60);

      final removed = map.remove('slotA');
      expect(removed, equals(50));
      expect(map.size, equals(1));
      expect(map.get('slotA'), isNull);
      expect(map.containsKey('slotA'), isFalse);
      expect(map.get('slotB'), equals(60));
    });

    test('remove returns null when removing missing key and preserves size', () {
      map.put('slotA', 50);

      final removed = map.remove('missing');
      expect(removed, isNull);
      expect(map.size, equals(1));
    });

    test('clear resets size and restores empty state', () {
      map.put('k1', 1);
      map.put('k2', 2);
      map.put('k3', 3);
      expect(map.size, equals(3));

      map.clear();
      expect(map.size, equals(0));
      expect(map.isEmpty, isTrue);
      expect(map.get('k1'), isNull);
      expect(map.containsKey('k1'), isFalse);
      expect(map.keys.toList(), isEmpty);
    });

    test('keys, values, and entries iterate over all items without built-in Map', () {
      map.put('alpha', 1);
      map.put('beta', 2);
      map.put('gamma', 3);

      final keysList = map.keys.toSet();
      final valuesList = map.values.toSet();
      final entriesList = map.entries.toList();

      expect(keysList, equals({'alpha', 'beta', 'gamma'}));
      expect(valuesList, equals({1, 2, 3}));
      expect(entriesList.length, equals(3));

      for (final entry in entriesList) {
        expect(map.get(entry.key), equals(entry.value));
      }
    });
  });

  group('CustomHashMap - Collision Handling (Separate Chaining)', () {
    late CustomHashMap<TestHashKey, String> map;
    late TestHashKey k1;
    late TestHashKey k2;
    late TestHashKey k3;
    late TestHashKey k4;

    setUp(() {
      map = CustomHashMap<TestHashKey, String>(initialCapacity: 8);
      // All keys share the exact same hash code (42), mapping to bucket (42 % 8 = 2)
      k1 = TestHashKey('key-1', 42);
      k2 = TestHashKey('key-2', 42);
      k3 = TestHashKey('key-3', 42);
      k4 = TestHashKey('key-4', 42);
    });

    test('all colliding keys map to the same bucket index', () {
      final idx1 = map.bucketIndexFor(k1);
      final idx2 = map.bucketIndexFor(k2);
      final idx3 = map.bucketIndexFor(k3);

      expect(idx1, equals(idx2));
      expect(idx2, equals(idx3));
      expect(idx1, equals(42 % 8));
    });

    test('inserting colliding keys forms a separate chaining linked list', () {
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');

      final bucketIdx = map.bucketIndexFor(k1);
      expect(map.chainLength(bucketIdx), equals(3));
      expect(map.size, equals(3));

      // Each colliding key can be retrieved independently
      expect(map.get(k1), equals('val-1'));
      expect(map.get(k2), equals('val-2'));
      expect(map.get(k3), equals('val-3'));
    });

    test('updating a colliding key modifies value without disturbing others in chain', () {
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');

      // Update middle/head node
      map.put(k2, 'updated-val-2');

      expect(map.size, equals(3));
      expect(map.get(k1), equals('val-1'));
      expect(map.get(k2), equals('updated-val-2'));
      expect(map.get(k3), equals('val-3'));
    });

    test('removes the head node in a collision chain', () {
      // Insertion prepends: chain is k3 -> k2 -> k1
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');

      final bucketIdx = map.bucketIndexFor(k1);
      expect(map.chainLength(bucketIdx), equals(3));

      // Remove head of chain (k3)
      final removed = map.remove(k3);
      expect(removed, equals('val-3'));
      expect(map.size, equals(2));
      expect(map.chainLength(bucketIdx), equals(2));
      expect(map.get(k3), isNull);
      expect(map.get(k2), equals('val-2'));
      expect(map.get(k1), equals('val-1'));
    });

    test('removes a middle node in a collision chain', () {
      // Chain: k3 -> k2 -> k1
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');

      final bucketIdx = map.bucketIndexFor(k1);

      // Remove middle node (k2)
      final removed = map.remove(k2);
      expect(removed, equals('val-2'));
      expect(map.size, equals(2));
      expect(map.chainLength(bucketIdx), equals(2));
      expect(map.get(k2), isNull);
      expect(map.get(k3), equals('val-3'));
      expect(map.get(k1), equals('val-1'));
    });

    test('removes the tail node in a collision chain', () {
      // Chain: k3 -> k2 -> k1 (k1 is tail)
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');

      final bucketIdx = map.bucketIndexFor(k1);

      // Remove tail node (k1)
      final removed = map.remove(k1);
      expect(removed, equals('val-1'));
      expect(map.size, equals(2));
      expect(map.chainLength(bucketIdx), equals(2));
      expect(map.get(k1), isNull);
      expect(map.get(k3), equals('val-3'));
      expect(map.get(k2), equals('val-2'));
    });

    test('exhaustively removes all nodes from collision chain until empty', () {
      map.put(k1, 'val-1');
      map.put(k2, 'val-2');
      map.put(k3, 'val-3');
      map.put(k4, 'val-4');

      final bucketIdx = map.bucketIndexFor(k1);
      expect(map.chainLength(bucketIdx), equals(4));

      expect(map.remove(k1), equals('val-1'));
      expect(map.remove(k2), equals('val-2'));
      expect(map.remove(k3), equals('val-3'));
      expect(map.remove(k4), equals('val-4'));

      expect(map.size, equals(0));
      expect(map.chainLength(bucketIdx), equals(0));
      expect(map.get(k1), isNull);
      expect(map.get(k2), isNull);
      expect(map.get(k3), isNull);
      expect(map.get(k4), isNull);
    });
  });

  group('CustomHashMap - Dynamic Resizing and Rehashing', () {
    test('triggers resize when size / capacity reaches loadFactorThreshold', () {
      // initialCapacity = 4, threshold = 0.75.
      // Threshold count: 4 * 0.75 = 3 items.
      final map = CustomHashMap<String, int>(
        initialCapacity: 4,
        loadFactorThreshold: 0.75,
      );

      expect(map.capacity, equals(4));

      map.put('a', 1);
      map.put('b', 2);
      expect(map.capacity, equals(4));
      expect(map.size, equals(2));
      expect(map.loadFactor, equals(0.5));

      // 3rd item: 3 / 4 = 0.75 >= 0.75 -> triggers rehash!
      map.put('c', 3);
      expect(map.capacity, equals(8)); // Doubled
      expect(map.size, equals(3));
      expect(map.loadFactor, equals(3 / 8));

      // Verify all items are preserved
      expect(map.get('a'), equals(1));
      expect(map.get('b'), equals(2));
      expect(map.get('c'), equals(3));
    });

    test('preserves all entries and maintains retrieval after multiple resizes', () {
      final map = CustomHashMap<int, String>(
        initialCapacity: 2,
        loadFactorThreshold: 0.75,
      );

      // Insert 20 elements, crossing capacities 2 -> 4 -> 8 -> 16 -> 32
      for (int i = 1; i <= 20; i++) {
        map.put(i, 'value-$i');
      }

      expect(map.size, equals(20));
      expect(map.capacity, greaterThanOrEqualTo(32));

      // Verify every single element is intact
      for (int i = 1; i <= 20; i++) {
        expect(map.get(i), equals('value-$i'));
        expect(map.containsKey(i), isTrue);
      }
    });

    test('clearing a resized map restores initial capacity and resets size', () {
      final map = CustomHashMap<int, String>(
        initialCapacity: 4,
        loadFactorThreshold: 0.75,
      );

      for (int i = 1; i <= 10; i++) {
        map.put(i, 'val-$i');
      }
      expect(map.capacity, greaterThan(4));
      expect(map.size, equals(10));

      map.clear();
      expect(map.capacity, equals(4));
      expect(map.size, equals(0));
      expect(map.isEmpty, isTrue);
    });
  });

  group('CustomHashMap - Edge Cases', () {
    test('handles negative hash codes safely without negative bucket indices', () {
      final map = CustomHashMap<TestHashKey, String>();
      final negKey = TestHashKey('neg', -999999);

      map.put(negKey, 'negative-hash-ok');

      final bucketIdx = map.bucketIndexFor(negKey);
      expect(bucketIdx, greaterThanOrEqualTo(0));
      expect(bucketIdx, lessThan(map.capacity));
      expect(map.get(negKey), equals('negative-hash-ok'));
      expect(map.containsKey(negKey), isTrue);
    });

    test('supports nullable values and distinguishes key with null value from missing key', () {
      final map = CustomHashMap<String, String?>();

      map.put('keyWithNull', null);

      expect(map.size, equals(1));
      expect(map.get('keyWithNull'), isNull);
      expect(map.containsKey('keyWithNull'), isTrue); // Key exists!
      expect(map.containsKey('nonExistent'), isFalse); // Key does NOT exist!
    });

    test('handles repeated removals of the same key safely', () {
      final map = CustomHashMap<String, int>();
      map.put('k1', 10);

      expect(map.remove('k1'), equals(10));
      expect(map.size, equals(0));

      expect(map.remove('k1'), isNull);
      expect(map.size, equals(0));
    });

    test('rejects non-positive initialCapacity', () {
      expect(
        () => CustomHashMap<String, int>(initialCapacity: 0),
        throwsArgumentError,
      );
      expect(
        () => CustomHashMap<String, int>(initialCapacity: -5),
        throwsArgumentError,
      );
    });

    test('rejects non-positive or NaN loadFactorThreshold', () {
      expect(
        () => CustomHashMap<String, int>(loadFactorThreshold: 0.0),
        throwsArgumentError,
      );
      expect(
        () => CustomHashMap<String, int>(loadFactorThreshold: -0.5),
        throwsArgumentError,
      );
      expect(
        () => CustomHashMap<String, int>(loadFactorThreshold: double.nan),
        throwsArgumentError,
      );
    });

    test('chainLength throws RangeError on out-of-bounds bucket index', () {
      final map = CustomHashMap<String, int>(initialCapacity: 4);

      expect(() => map.chainLength(-1), throwsRangeError);
      expect(() => map.chainLength(4), throwsRangeError);
    });
  });

  group('CustomHashMap - SmartPark Integration (ParkingSlot Lookup)', () {
    late CustomHashMap<String, ParkingSlot> slotMap;
    late ParkingSlot slotP01;
    late ParkingSlot slotP02;
    late ParkingSlot slotP10;
    late ParkingSlot slotP20;

    setUp(() {
      slotMap = CustomHashMap<String, ParkingSlot>();

      slotP01 = ParkingSlot(
        id: 'slot-001',
        slotCode: 'P01',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 6.0,
        y: 13.5,
      );

      slotP02 = ParkingSlot(
        id: 'slot-002',
        slotCode: 'P02',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 9.0,
        y: 13.5,
      );

      slotP10 = ParkingSlot(
        id: 'slot-010',
        slotCode: 'P10',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        x: 33.0,
        y: 13.5,
      );

      slotP20 = ParkingSlot(
        id: 'slot-020',
        slotCode: 'P20',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 33.0,
        y: 2.5,
      );
    });

    test('inserts ParkingSlot objects keyed by slotCode', () {
      slotMap.put(slotP01.slotCode, slotP01);
      slotMap.put(slotP02.slotCode, slotP02);
      slotMap.put(slotP10.slotCode, slotP10);
      slotMap.put(slotP20.slotCode, slotP20);

      expect(slotMap.size, equals(4));
      expect(slotMap.containsKey('P01'), isTrue);
      expect(slotMap.containsKey('P02'), isTrue);
      expect(slotMap.containsKey('P10'), isTrue);
      expect(slotMap.containsKey('P20'), isTrue);
    });

    test('retrieves slots P01, P10, and P20 with exact metadata', () {
      slotMap.put(slotP01.slotCode, slotP01);
      slotMap.put(slotP02.slotCode, slotP02);
      slotMap.put(slotP10.slotCode, slotP10);
      slotMap.put(slotP20.slotCode, slotP20);

      final retrievedP01 = slotMap.get('P01');
      expect(retrievedP01, isNotNull);
      expect(retrievedP01!.id, equals('slot-001'));
      expect(retrievedP01.slotCode, equals('P01'));
      expect(retrievedP01.row, equals(SlotRow.a));
      expect(retrievedP01.status, equals(SlotStatus.available));
      expect(retrievedP01.x, equals(6.0));
      expect(retrievedP01.y, equals(13.5));

      final retrievedP10 = slotMap.get('P10');
      expect(retrievedP10, isNotNull);
      expect(retrievedP10!.id, equals('slot-010'));
      expect(retrievedP10.slotCode, equals('P10'));
      expect(retrievedP10.status, equals(SlotStatus.occupied));

      final retrievedP20 = slotMap.get('P20');
      expect(retrievedP20, isNotNull);
      expect(retrievedP20!.id, equals('slot-020'));
      expect(retrievedP20.slotCode, equals('P20'));
      expect(retrievedP20.row, equals(SlotRow.b));
    });

    test('updates a parking slot state when slot is booked or occupied', () {
      slotMap.put(slotP01.slotCode, slotP01);
      expect(slotMap.get('P01')!.status, equals(SlotStatus.available));

      // Simulate slot occupation
      final updatedP01 = slotP01.copyWith(status: SlotStatus.occupied);
      slotMap.put('P01', updatedP01);

      expect(slotMap.size, equals(1));
      expect(slotMap.get('P01')!.status, equals(SlotStatus.occupied));
      expect(slotMap.get('P01')!.isAvailable, isFalse);
    });

    test('removes slot and verifies it cannot be retrieved while others remain', () {
      slotMap.put(slotP01.slotCode, slotP01);
      slotMap.put(slotP10.slotCode, slotP10);
      slotMap.put(slotP20.slotCode, slotP20);

      expect(slotMap.size, equals(3));

      // Remove P10
      final removed = slotMap.remove('P10');
      expect(removed, isNotNull);
      expect(removed!.slotCode, equals('P10'));
      expect(slotMap.size, equals(2));

      // Verify P10 is no longer found
      expect(slotMap.get('P10'), isNull);
      expect(slotMap.containsKey('P10'), isFalse);

      // Verify P01 and P20 are completely intact
      expect(slotMap.containsKey('P01'), isTrue);
      expect(slotMap.containsKey('P20'), isTrue);
      expect(slotMap.get('P01')!.slotCode, equals('P01'));
      expect(slotMap.get('P20')!.slotCode, equals('P20'));
    });
  });
}
