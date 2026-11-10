import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/min_heap/min_heap.dart';
import 'package:smartpark_app/models/parking_slot.dart';

/// Test helper class for verifying generic custom object support.
class PriorityTask {
  final String name;
  final int priority;

  PriorityTask(this.name, this.priority);

  @override
  String toString() => 'PriorityTask($name, priority: $priority)';
}

/// Simulated Dijkstra entry demonstrating future compatibility.
class DijkstraEntry {
  final String nodeId;
  final double distance;

  DijkstraEntry(this.nodeId, this.distance);

  @override
  String toString() => 'DijkstraEntry($nodeId, dist: $distance)';
}

void main() {
  group('CustomMinHeap - Basic Operations', () {
    late CustomMinHeap<int> heap;

    setUp(() {
      heap = CustomMinHeap<int>();
    });

    test('newly initialized heap is empty', () {
      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.isNotEmpty, isFalse);
      expect(heap.peek(), isNull);
      expect(heap.extractMin(), isNull);
      expect(heap.elements, isEmpty);
    });

    test('insert adds a single element and updates size', () {
      heap.insert(42);

      expect(heap.size, equals(1));
      expect(heap.isEmpty, isFalse);
      expect(heap.isNotEmpty, isTrue);
      expect(heap.peek(), equals(42));
      expect(heap.isValidHeap(), isTrue);
    });

    test('peek returns the minimum without removing it', () {
      heap.insert(30);
      heap.insert(10);
      heap.insert(20);

      expect(heap.peek(), equals(10));
      expect(heap.size, equals(3));
      expect(heap.peek(), equals(10));
    });

    test('extractMin removes and returns the root minimum', () {
      heap.insert(25);
      heap.insert(5);
      heap.insert(15);

      expect(heap.extractMin(), equals(5));
      expect(heap.size, equals(2));
      expect(heap.peek(), equals(15));
      expect(heap.extractMin(), equals(15));
      expect(heap.size, equals(1));
      expect(heap.peek(), equals(25));
      expect(heap.extractMin(), equals(25));
      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.extractMin(), isNull);
    });

    test('single-element heap extraction leaves heap empty', () {
      heap.insert(99);
      expect(heap.size, equals(1));

      final extracted = heap.extractMin();
      expect(extracted, equals(99));
      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.peek(), isNull);
      expect(heap.extractMin(), isNull);
    });

    test('clear empties the heap completely', () {
      heap.insert(1);
      heap.insert(2);
      heap.insert(3);
      expect(heap.size, equals(3));

      heap.clear();
      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.peek(), isNull);
      expect(heap.elements, isEmpty);
    });
  });

  group('CustomMinHeap - Min-Heap Invariant & Sifting', () {
    late CustomMinHeap<int> heap;

    setUp(() {
      heap = CustomMinHeap<int>();
    });

    test('maintains heap property with ascending insertions', () {
      final input = [1, 2, 3, 4, 5, 6, 7];
      for (final val in input) {
        heap.insert(val);
        expect(heap.isValidHeap(), isTrue);
      }

      final extracted = <int>[];
      while (heap.isNotEmpty) {
        extracted.add(heap.extractMin()!);
        expect(heap.isValidHeap(), isTrue);
      }
      expect(extracted, equals([1, 2, 3, 4, 5, 6, 7]));
    });

    test('maintains heap property with descending insertions', () {
      final input = [7, 6, 5, 4, 3, 2, 1];
      for (final val in input) {
        heap.insert(val);
        expect(heap.isValidHeap(), isTrue);
      }

      final extracted = <int>[];
      while (heap.isNotEmpty) {
        extracted.add(heap.extractMin()!);
        expect(heap.isValidHeap(), isTrue);
      }
      expect(extracted, equals([1, 2, 3, 4, 5, 6, 7]));
    });

    test('maintains heap property with mixed/random priorities', () {
      final input = [19, 3, 36, 2, 25, 1, 17, 7, 100];
      for (final val in input) {
        heap.insert(val);
        expect(heap.isValidHeap(), isTrue);
      }

      final extracted = <int>[];
      while (heap.isNotEmpty) {
        extracted.add(heap.extractMin()!);
        expect(heap.isValidHeap(), isTrue);
      }
      expect(extracted, equals([1, 2, 3, 7, 17, 19, 25, 36, 100]));
    });

    test('stress test: 200 elements maintain invariant after every step', () {
      // Insert elements in reverse order
      for (int i = 200; i >= 1; i--) {
        heap.insert(i);
      }
      expect(heap.size, equals(200));
      expect(heap.isValidHeap(), isTrue);

      // Extract all elements and assert strict ascending order
      for (int expected = 1; expected <= 200; expected++) {
        expect(heap.extractMin(), equals(expected));
      }
      expect(heap.isEmpty, isTrue);
    });
  });

  group('CustomMinHeap - Duplicate Priorities', () {
    test('retains all duplicate elements and extracts in valid order', () {
      final heap = CustomMinHeap<int>();
      final items = [5, 2, 5, 1, 2, 5, 1];

      for (final item in items) {
        heap.insert(item);
        expect(heap.isValidHeap(), isTrue);
      }

      expect(heap.size, equals(7));

      final extracted = <int>[];
      while (heap.isNotEmpty) {
        extracted.add(heap.extractMin()!);
      }

      expect(extracted, equals([1, 1, 2, 2, 5, 5, 5]));
    });
  });

  group('CustomMinHeap - Generic Support & Custom Comparators', () {
    test('works with String elements using natural Comparable ordering', () {
      final stringHeap = CustomMinHeap<String>();
      stringHeap.insert('charlie');
      stringHeap.insert('alpha');
      stringHeap.insert('bravo');

      expect(stringHeap.extractMin(), equals('alpha'));
      expect(stringHeap.extractMin(), equals('bravo'));
      expect(stringHeap.extractMin(), equals('charlie'));
    });

    test('works with custom non-Comparable type via explicit comparator', () {
      final taskHeap = CustomMinHeap<PriorityTask>(
        (a, b) => a.priority.compareTo(b.priority),
      );

      taskHeap.insert(PriorityTask('Low priority bug', 3));
      taskHeap.insert(PriorityTask('Critical outage', 1));
      taskHeap.insert(PriorityTask('Feature request', 4));
      taskHeap.insert(PriorityTask('Medium issue', 2));

      expect(taskHeap.size, equals(4));
      expect(taskHeap.isValidHeap(), isTrue);

      expect(taskHeap.extractMin()!.name, equals('Critical outage'));
      expect(taskHeap.extractMin()!.name, equals('Medium issue'));
      expect(taskHeap.extractMin()!.name, equals('Low priority bug'));
      expect(taskHeap.extractMin()!.name, equals('Feature request'));
    });

    test('throws StateError when non-Comparable type has no comparator', () {
      final heap = CustomMinHeap<Object>();
      heap.insert(Object());
      expect(() => heap.insert(Object()), throwsStateError);
    });
  });

  group('CustomMinHeap - Bulk Building (buildHeap & from)', () {
    test('buildHeap handles empty collection', () {
      final heap = CustomMinHeap<int>();
      heap.buildHeap([]);
      expect(heap.isEmpty, isTrue);
      expect(heap.peek(), isNull);
    });

    test('buildHeap handles single-element collection', () {
      final heap = CustomMinHeap<int>();
      heap.buildHeap([42]);
      expect(heap.size, equals(1));
      expect(heap.peek(), equals(42));
      expect(heap.extractMin(), equals(42));
      expect(heap.isEmpty, isTrue);
    });

    test('buildHeap establishes valid heap in O(n) from unordered list', () {
      final unordered = [15, 3, 22, 10, 8, 45, 1, 19, 7];
      final heap = CustomMinHeap<int>();
      heap.buildHeap(unordered);

      expect(heap.size, equals(9));
      expect(heap.isValidHeap(), isTrue);

      final extracted = <int>[];
      while (heap.isNotEmpty) {
        extracted.add(heap.extractMin()!);
      }
      expect(extracted, equals([1, 3, 7, 8, 10, 15, 19, 22, 45]));
    });

    test('CustomMinHeap.from factory builds heap correctly', () {
      final heap = CustomMinHeap<int>.from([9, 5, 2, 7, 1]);
      expect(heap.size, equals(5));
      expect(heap.isValidHeap(), isTrue);
      expect(heap.extractMin(), equals(1));
      expect(heap.extractMin(), equals(2));
      expect(heap.extractMin(), equals(5));
      expect(heap.extractMin(), equals(7));
      expect(heap.extractMin(), equals(9));
    });
  });

  group('SmartPark Recommendation Integration (ParkingSlotCandidate)', () {
    late ParkingSlot slotP01;
    late ParkingSlot slotP02;
    late ParkingSlot slotP03;
    late ParkingSlot slotP10;
    late ParkingSlot slotP11;
    late ParkingSlot slotOccupied;
    late ParkingSlot slotInactive;

    setUp(() {
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

      slotP03 = ParkingSlot(
        id: 'slot-003',
        slotCode: 'P03',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 12.0,
        y: 13.5,
      );

      slotP10 = ParkingSlot(
        id: 'slot-010',
        slotCode: 'P10',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 33.0,
        y: 13.5,
      );

      slotP11 = ParkingSlot(
        id: 'slot-011',
        slotCode: 'P11',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        x: 6.0,
        y: 2.5,
      );

      slotOccupied = ParkingSlot(
        id: 'slot-099',
        slotCode: 'P99',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
      );

      slotInactive = ParkingSlot(
        id: 'slot-098',
        slotCode: 'P98',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        isActive: false,
      );
    });

    test('validates distance parameter in ParkingSlotCandidate', () {
      expect(
        () => ParkingSlotCandidate(slot: slotP01, distance: -1.0),
        throwsArgumentError,
      );
      expect(
        () => ParkingSlotCandidate(slot: slotP01, distance: double.nan),
        throwsArgumentError,
      );
    });

    test('ranks candidates in ascending order of supplied route distance', () {
      final heap = CustomMinHeap<ParkingSlotCandidate>();

      // Caller supplies route distances (e.g. from Dijkstra pathfinder)
      heap.insert(ParkingSlotCandidate(slot: slotP10, distance: 34.5));
      heap.insert(ParkingSlotCandidate(slot: slotP01, distance: 7.2));
      heap.insert(ParkingSlotCandidate(slot: slotP03, distance: 13.2));
      heap.insert(ParkingSlotCandidate(slot: slotP02, distance: 10.2));

      expect(heap.size, equals(4));
      expect(heap.isValidHeap(), isTrue);

      // Best recommendation: closest slot P01 (7.2m)
      final rank1 = heap.extractMin()!;
      expect(rank1.slot.slotCode, equals('P01'));
      expect(rank1.distance, equals(7.2));
      expect(rank1.slot.row, equals(SlotRow.a));

      // Rank 2: P02 (10.2m)
      final rank2 = heap.extractMin()!;
      expect(rank2.slot.slotCode, equals('P02'));
      expect(rank2.distance, equals(10.2));

      // Rank 3: P03 (13.2m)
      final rank3 = heap.extractMin()!;
      expect(rank3.slot.slotCode, equals('P03'));
      expect(rank3.distance, equals(13.2));

      // Rank 4: P10 (34.5m)
      final rank4 = heap.extractMin()!;
      expect(rank4.slot.slotCode, equals('P10'));
      expect(rank4.distance, equals(34.5));

      expect(heap.isEmpty, isTrue);
    });

    test('deterministic tie-breaking: uses ascending slotCode on equal distance', () {
      final heap = CustomMinHeap<ParkingSlotCandidate>();

      // P01 (Row A) and P11 (Row B) both have equal aisle distance from entrance (e.g. 7.5m)
      final candidateP11 = ParkingSlotCandidate(slot: slotP11, distance: 7.5);
      final candidateP01 = ParkingSlotCandidate(slot: slotP01, distance: 7.5);

      // Insert P11 first, then P01
      heap.insert(candidateP11);
      heap.insert(candidateP01);

      expect(heap.size, equals(2));

      // Tie-breaker: 'P01' < 'P11' -> P01 extracted first
      final first = heap.extractMin()!;
      expect(first.slot.slotCode, equals('P01'));

      final second = heap.extractMin()!;
      expect(second.slot.slotCode, equals('P11'));
    });

    test('excludes unavailable or inactive slots prior to heap insertion', () {
      final allSlots = [
        slotP01, // Available, active -> eligible
        slotOccupied, // Occupied -> ineligible
        slotInactive, // Inactive -> ineligible
        slotP02, // Available, active -> eligible
      ];

      final heap = CustomMinHeap<ParkingSlotCandidate>();

      // Eligibility filtering rule: only insert if slot.isAvailable is true
      for (final slot in allSlots) {
        if (slot.isAvailable) {
          // Supplied route distances: P01 = 8.0m, P02 = 11.0m
          final distance = slot.slotCode == 'P01' ? 8.0 : 11.0;
          heap.insert(ParkingSlotCandidate(slot: slot, distance: distance));
        }
      }

      // Ineligible slots were filtered out; only 2 candidates entered heap
      expect(heap.size, equals(2));

      final rec1 = heap.extractMin()!;
      expect(rec1.slot.slotCode, equals('P01'));

      final rec2 = heap.extractMin()!;
      expect(rec2.slot.slotCode, equals('P02'));

      expect(heap.isEmpty, isTrue);
    });
  });

  group('CustomMinHeap - Future Dijkstra Compatibility', () {
    test('supports tentative distance entries and lazy deletion pattern', () {
      final priorityQueue = CustomMinHeap<DijkstraEntry>(
        (a, b) => a.distance.compareTo(b.distance),
      );

      // Map of shortest distances known so far
      final shortestDistance = <String, double>{
        'A': 0.0,
        'B': double.infinity,
        'C': double.infinity,
      };

      // Start node
      priorityQueue.insert(DijkstraEntry('A', 0.0));

      // Relaxation pushes edge (A, B, weight: 10.0)
      shortestDistance['B'] = 10.0;
      priorityQueue.insert(DijkstraEntry('B', 10.0));

      // Relaxation pushes edge (A, C, weight: 5.0)
      shortestDistance['C'] = 5.0;
      priorityQueue.insert(DijkstraEntry('C', 5.0));

      // Later, shorter path to B found via C: (C, B, weight: 2.0) -> total: 7.0
      // In lazy Dijkstra, we insert new entry without deleting previous entry (B, 10.0)
      shortestDistance['B'] = 7.0;
      priorityQueue.insert(DijkstraEntry('B', 7.0));

      // Process priority queue
      final visitedNodes = <String>[];
      while (priorityQueue.isNotEmpty) {
        final current = priorityQueue.extractMin()!;

        // Lazy deletion check: if extracted distance > known shortest, skip stale entry
        if (current.distance > shortestDistance[current.nodeId]!) {
          continue;
        }

        visitedNodes.add('${current.nodeId}:${current.distance}');
      }

      // Expected order: A:0.0, C:5.0, B:7.0 (the stale B:10.0 entry was lazily skipped)
      expect(visitedNodes, equals(['A:0.0', 'C:5.0', 'B:7.0']));
    });
  });
}
