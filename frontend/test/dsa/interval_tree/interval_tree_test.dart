import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/interval_tree/interval_tree.dart';
import 'package:smartpark_app/models/booking.dart';

/// Test helper generating deterministic UTC timestamps.
DateTime t(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 11, 11, hour, minute);

/// Helper constructing a [Booking] with concise interval parameters.
Booking makeBooking({
  required String id,
  required String slotId,
  required int startHour,
  required int endHour,
  int startMinute = 0,
  int endMinute = 0,
  BookingStatus status = BookingStatus.confirmed,
}) {
  return Booking(
    id: id,
    slotId: slotId,
    startTime: t(startHour, startMinute),
    endTime: t(endHour, endMinute),
    status: status,
  );
}

void main() {
  group('CustomIntervalTree - Basic Operations', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
    });

    test('newly initialized tree is empty', () {
      expect(tree.size, equals(0));
      expect(tree.isEmpty, isTrue);
      expect(tree.isNotEmpty, isFalse);
      expect(tree.height, equals(0));
      expect(tree.root, isNull);
      expect(tree.isValidTree(), isTrue);
      expect(tree.toList(), isEmpty);
    });

    test('single insertion updates size, height, and root', () {
      final booking = makeBooking(
        id: 'B01',
        slotId: 'P01',
        startHour: 10,
        endHour: 12,
      );

      final inserted = tree.insert(booking);

      expect(inserted, isTrue);
      expect(tree.size, equals(1));
      expect(tree.isEmpty, isFalse);
      expect(tree.isNotEmpty, isTrue);
      expect(tree.height, equals(1));
      expect(tree.root, isNotNull);
      expect(tree.root!.booking, equals(booking));
      expect(tree.root!.maxEnd, equals(booking.endTime));
      expect(tree.isValidTree(), isTrue);
    });

    test('multiple insertions preserve size and validity', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B02', slotId: 'P02', startHour: 8, endHour: 10);
      final b3 = makeBooking(id: 'B03', slotId: 'P03', startHour: 14, endHour: 16);

      tree.insert(b1);
      tree.insert(b2);
      tree.insert(b3);

      expect(tree.size, equals(3));
      expect(tree.height, equals(2));
      expect(tree.isValidTree(), isTrue);
    });

    test('search existing interval returns matching booking', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B02', slotId: 'P02', startHour: 14, endHour: 16);
      tree.insert(b1);
      tree.insert(b2);

      final overlaps = tree.searchOverlaps(t(11), t(13));

      expect(overlaps.length, equals(1));
      expect(overlaps.first.id, equals('B01'));
    });

    test('search missing interval returns empty list', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      final overlaps = tree.searchOverlaps(t(14), t(16));

      expect(overlaps, isEmpty);
    });

    test('searchFirstOverlap returns matching booking or null', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      expect(tree.searchFirstOverlap(t(11), t(13))?.id, equals('B01'));
      expect(tree.searchFirstOverlap(t(13), t(15)), isNull);
    });

    test('hasOverlap distinguishes overlapping from disjoint windows', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      expect(tree.hasOverlap(t(11), t(13)), isTrue);
      expect(tree.hasOverlap(t(12), t(14)), isFalse);
    });

    test('contains and get retrieve booking by id', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      expect(tree.contains('B01'), isTrue);
      expect(tree.contains('B99'), isFalse);
      expect(tree.get('B01'), equals(b1));
      expect(tree.get('B99'), isNull);
    });

    test('clear resets size to 0 and root to null', () {
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12));
      tree.insert(makeBooking(id: 'B02', slotId: 'P02', startHour: 14, endHour: 16));

      expect(tree.size, equals(2));
      tree.clear();

      expect(tree.size, equals(0));
      expect(tree.isEmpty, isTrue);
      expect(tree.root, isNull);
      expect(tree.height, equals(0));
      expect(tree.isValidTree(), isTrue);
    });

    test('remove removes existing booking and decrements size', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B02', slotId: 'P02', startHour: 14, endHour: 16);
      tree.insert(b1);
      tree.insert(b2);

      final removed = tree.remove('B01');

      expect(removed, isTrue);
      expect(tree.size, equals(1));
      expect(tree.contains('B01'), isFalse);
      expect(tree.contains('B02'), isTrue);
      expect(tree.isValidTree(), isTrue);
    });

    test('remove returns false on non-existent booking and preserves size', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      final removed = tree.remove('NON_EXISTENT');

      expect(removed, isFalse);
      expect(tree.size, equals(1));
      expect(tree.isValidTree(), isTrue);
    });
  });

  group('CustomIntervalTree - Half-Open Interval Semantics [start, end)', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
      // Base booking: [10:00, 12:00)
      tree.insert(makeBooking(id: 'BASE', slotId: 'P01', startHour: 10, endHour: 12));
    });

    test('partial overlap: query starts before and ends inside', () {
      // Query: [09:00, 11:00)
      final overlaps = tree.searchOverlaps(t(9), t(11));
      expect(overlaps.map((b) => b.id), contains('BASE'));
    });

    test('partial overlap: query starts inside and ends after', () {
      // Query: [11:00, 13:00)
      final overlaps = tree.searchOverlaps(t(11), t(13));
      expect(overlaps.map((b) => b.id), contains('BASE'));
    });

    test('complete containment: query strictly inside existing booking', () {
      // Query: [10:30, 11:30)
      final overlaps = tree.searchOverlaps(t(10, 30), t(11, 30));
      expect(overlaps.map((b) => b.id), contains('BASE'));
    });

    test('complete containment: existing booking strictly inside query', () {
      // Query: [08:00, 14:00)
      final overlaps = tree.searchOverlaps(t(8), t(14));
      expect(overlaps.map((b) => b.id), contains('BASE'));
    });

    test('equal intervals: exact match reports overlap', () {
      // Query: [10:00, 12:00)
      final overlaps = tree.searchOverlaps(t(10), t(12));
      expect(overlaps.map((b) => b.id), contains('BASE'));
    });

    test('adjacent intervals: contiguous back-to-back bookings do NOT overlap', () {
      // Preceding contiguous interval: [08:00, 10:00) touching at 10:00
      final preceding = tree.searchOverlaps(t(8), t(10));
      expect(preceding, isEmpty);

      // Succeeding contiguous interval: [12:00, 14:00) touching at 12:00
      final succeeding = tree.searchOverlaps(t(12), t(14));
      expect(succeeding, isEmpty);
    });

    test('non-overlapping: completely before reports no overlap', () {
      // Query: [07:00, 09:00)
      expect(tree.searchOverlaps(t(7), t(9)), isEmpty);
    });

    test('non-overlapping: completely after reports no overlap', () {
      // Query: [13:00, 15:00)
      expect(tree.searchOverlaps(t(13), t(15)), isEmpty);
    });

    test('invalid interval query (end <= start) throws ArgumentError', () {
      expect(() => tree.searchOverlaps(t(12), t(10)), throwsArgumentError);
      expect(() => tree.searchOverlaps(t(10), t(10)), throwsArgumentError);
      expect(() => tree.hasOverlap(t(12), t(10)), throwsArgumentError);
      expect(() => tree.searchFirstOverlap(t(12), t(10)), throwsArgumentError);
    });
  });

  group('CustomIntervalTree - Same-Slot Conflict Detection', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
    });

    test('overlap on same slot reports conflict', () {
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12));

      expect(tree.hasConflict('P01', t(11), t(13)), isTrue);
      expect(tree.findConflicts('P01', t(11), t(13)).map((b) => b.id), contains('B01'));
    });

    test('overlap on different slots does NOT report conflict', () {
      // Booking is for P01 [10:00, 12:00)
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12));

      // Query is for P02 at the exact same time [10:00, 12:00)
      expect(tree.hasConflict('P02', t(10), t(12)), isFalse);
      expect(tree.findConflicts('P02', t(10), t(12)), isEmpty);

      // But temporal search without slot filtering STILL finds the interval
      final temporalOverlaps = tree.searchOverlaps(t(10), t(12));
      expect(temporalOverlaps.length, equals(1));
      expect(temporalOverlaps.first.slotId, equals('P01'));
    });

    test('multiple slots with identical time ranges are isolated correctly', () {
      tree.insert(makeBooking(id: 'B_P01', slotId: 'P01', startHour: 10, endHour: 12));
      tree.insert(makeBooking(id: 'B_P02', slotId: 'P02', startHour: 10, endHour: 12));
      tree.insert(makeBooking(id: 'B_P03', slotId: 'P03', startHour: 10, endHour: 12));

      expect(tree.size, equals(3));

      // Querying P01 only conflicts with P01
      final p01Conflicts = tree.findConflicts('P01', t(10), t(12));
      expect(p01Conflicts.length, equals(1));
      expect(p01Conflicts.first.id, equals('B_P01'));

      // Querying P02 only conflicts with P02
      final p02Conflicts = tree.findConflicts('P02', t(10), t(12));
      expect(p02Conflicts.length, equals(1));
      expect(p02Conflicts.first.id, equals('B_P02'));

      // Querying P04 (no bookings) has zero conflicts
      expect(tree.hasConflict('P04', t(10), t(12)), isFalse);
      expect(tree.findConflicts('P04', t(10), t(12)), isEmpty);
    });

    test('same slot with contiguous back-to-back bookings reports no conflict', () {
      // Slot P01 has existing booking 09:00-11:00
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 9, endHour: 11));

      // Querying adjacent 11:00-13:00 on P01 must NOT report conflict
      expect(tree.hasConflict('P01', t(11), t(13)), isFalse);
      expect(tree.findConflicts('P01', t(11), t(13)), isEmpty);
    });

    test('multiple conflicting bookings for one slot are all returned', () {
      // P01 has two bookings: 09:00-11:00 and 12:00-14:00
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 9, endHour: 11));
      tree.insert(makeBooking(id: 'B02', slotId: 'P01', startHour: 12, endHour: 14));
      // P02 also has a booking in between: 10:00-13:00
      tree.insert(makeBooking(id: 'B_OTHER', slotId: 'P02', startHour: 10, endHour: 13));

      // Querying P01 across [08:00, 15:00) should find BOTH B01 and B02, but NOT B_OTHER
      final conflicts = tree.findConflicts('P01', t(8), t(15));
      expect(conflicts.length, equals(2));
      expect(conflicts.map((b) => b.id), containsAll(['B01', 'B02']));
      expect(conflicts.map((b) => b.id), isNot(contains('B_OTHER')));
    });

    test('convenience booking overload checks conflicts accurately', () {
      tree.insert(makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12));

      final prospectiveConflicting =
          makeBooking(id: 'PROSP_1', slotId: 'P01', startHour: 11, endHour: 13);
      final prospectiveSafe =
          makeBooking(id: 'PROSP_2', slotId: 'P01', startHour: 12, endHour: 14);

      expect(tree.hasBookingConflict(prospectiveConflicting), isTrue);
      expect(tree.hasBookingConflict(prospectiveSafe), isFalse);
      expect(tree.findBookingConflicts(prospectiveConflicting).length, equals(1));
      expect(tree.findBookingConflicts(prospectiveSafe), isEmpty);
    });

    test('validation throws ArgumentError on empty slotId', () {
      expect(() => tree.hasConflict('', t(10), t(12)), throwsArgumentError);
      expect(() => tree.findConflicts('   ', t(10), t(12)), throwsArgumentError);
    });
  });

  group('CustomIntervalTree - AVL Balancing Rotations', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
    });

    test('LL rotation: descending insertions trigger right rotation', () {
      // Insert in strictly descending start time: 30, 20, 10
      final b30 = makeBooking(id: 'B30', slotId: 'P01', startHour: 15, endHour: 17);
      final b20 = makeBooking(id: 'B20', slotId: 'P01', startHour: 12, endHour: 14);
      final b10 = makeBooking(id: 'B10', slotId: 'P01', startHour: 9, endHour: 11);

      tree.insert(b30);
      tree.insert(b20);
      tree.insert(b10);

      // Root must have rotated so B20 is at root
      expect(tree.root!.id, equals('B20'));
      expect(tree.root!.left!.id, equals('B10'));
      expect(tree.root!.right!.id, equals('B30'));
      expect(tree.height, equals(2));
      expect(tree.isValidTree(), isTrue);
    });

    test('RR rotation: ascending insertions trigger left rotation', () {
      // Insert in strictly ascending start time: 10, 20, 30
      final b10 = makeBooking(id: 'B10', slotId: 'P01', startHour: 9, endHour: 11);
      final b20 = makeBooking(id: 'B20', slotId: 'P01', startHour: 12, endHour: 14);
      final b30 = makeBooking(id: 'B30', slotId: 'P01', startHour: 15, endHour: 17);

      tree.insert(b10);
      tree.insert(b20);
      tree.insert(b30);

      // Root must have rotated so B20 is at root
      expect(tree.root!.id, equals('B20'));
      expect(tree.root!.left!.id, equals('B10'));
      expect(tree.root!.right!.id, equals('B30'));
      expect(tree.height, equals(2));
      expect(tree.isValidTree(), isTrue);
    });

    test('LR rotation: left child with right child triggers LR double rotation', () {
      // Insert: 30, 10, 20
      final b30 = makeBooking(id: 'B30', slotId: 'P01', startHour: 15, endHour: 17);
      final b10 = makeBooking(id: 'B10', slotId: 'P01', startHour: 9, endHour: 11);
      final b20 = makeBooking(id: 'B20', slotId: 'P01', startHour: 12, endHour: 14);

      tree.insert(b30);
      tree.insert(b10);
      tree.insert(b20);

      expect(tree.root!.id, equals('B20'));
      expect(tree.root!.left!.id, equals('B10'));
      expect(tree.root!.right!.id, equals('B30'));
      expect(tree.height, equals(2));
      expect(tree.isValidTree(), isTrue);
    });

    test('RL rotation: right child with left child triggers RL double rotation', () {
      // Insert: 10, 30, 20
      final b10 = makeBooking(id: 'B10', slotId: 'P01', startHour: 9, endHour: 11);
      final b30 = makeBooking(id: 'B30', slotId: 'P01', startHour: 15, endHour: 17);
      final b20 = makeBooking(id: 'B20', slotId: 'P01', startHour: 12, endHour: 14);

      tree.insert(b10);
      tree.insert(b30);
      tree.insert(b20);

      expect(tree.root!.id, equals('B20'));
      expect(tree.root!.left!.id, equals('B10'));
      expect(tree.root!.right!.id, equals('B30'));
      expect(tree.height, equals(2));
      expect(tree.isValidTree(), isTrue);
    });

    test('deletion requiring rebalancing triggers appropriate rotation', () {
      // Build tree: 20, 10, 30, 5
      final b20 = makeBooking(id: 'B20', slotId: 'P01', startHour: 12, endHour: 14);
      final b10 = makeBooking(id: 'B10', slotId: 'P01', startHour: 9, endHour: 11);
      final b30 = makeBooking(id: 'B30', slotId: 'P01', startHour: 15, endHour: 17);
      final b05 = makeBooking(id: 'B05', slotId: 'P01', startHour: 7, endHour: 8);

      tree.insert(b20);
      tree.insert(b10);
      tree.insert(b30);
      tree.insert(b05);

      expect(tree.isValidTree(), isTrue);

      // Deleting B30 makes node B20 left-heavy (left height 2, right height 0)
      tree.remove('B30');

      expect(tree.isValidTree(), isTrue);
      // B10 should now be root
      expect(tree.root!.id, equals('B10'));
      expect(tree.root!.left!.id, equals('B05'));
      expect(tree.root!.right!.id, equals('B20'));
      expect(tree.height, equals(2));
    });

    test('two-child node deletion replaces with in-order successor and preserves AVL balance', () {
      // Construct a balanced tree with 7 nodes
      final bookings = [
        makeBooking(id: 'B4', slotId: 'P01', startHour: 12, endHour: 13),
        makeBooking(id: 'B2', slotId: 'P01', startHour: 8, endHour: 9),
        makeBooking(id: 'B6', slotId: 'P01', startHour: 16, endHour: 17),
        makeBooking(id: 'B1', slotId: 'P01', startHour: 6, endHour: 7),
        makeBooking(id: 'B3', slotId: 'P01', startHour: 10, endHour: 11),
        makeBooking(id: 'B5', slotId: 'P01', startHour: 14, endHour: 15),
        makeBooking(id: 'B7', slotId: 'P01', startHour: 18, endHour: 19),
      ];

      for (final b in bookings) {
        tree.insert(b);
      }

      expect(tree.size, equals(7));
      expect(tree.root!.id, equals('B4'));
      expect(tree.isValidTree(), isTrue);

      // Delete root B4 (two children: B2 and B6; successor is B5)
      final removed = tree.remove('B4');

      expect(removed, isTrue);
      expect(tree.size, equals(6));
      expect(tree.contains('B4'), isFalse);
      expect(tree.isValidTree(), isTrue);
      // Successor B5 is now at root
      expect(tree.root!.id, equals('B5'));
    });

    test('sequential insertions remain height-balanced within log2 bounds', () {
      // Insert 31 sequential items
      for (int i = 1; i <= 31; i++) {
        tree.insert(
          makeBooking(
            id: 'B${i.toString().padLeft(2, '0')}',
            slotId: 'P01',
            startHour: 0,
            endHour: 1,
            startMinute: i,
            endMinute: i + 20,
          ),
        );
      }

      expect(tree.size, equals(31));
      expect(tree.isValidTree(), isTrue);
      // For AVL tree with 31 nodes, maximum possible height is <= 6
      expect(tree.height, lessThanOrEqualTo(6));
      expect(tree.height, greaterThanOrEqualTo(5));
    });
  });

  group('CustomIntervalTree - maxEnd Augmentation Correctness', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
    });

    test('root maxEnd reflects latest end time across all subtrees', () {
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 8, endHour: 15); // Longest end!
      final b3 = makeBooking(id: 'B3', slotId: 'P01', startHour: 14, endHour: 16);

      tree.insert(b1);
      tree.insert(b2);
      tree.insert(b3);

      expect(tree.root!.maxEnd, equals(t(16)));
      expect(tree.isValidTree(), isTrue);
    });

    test('maxEnd updates correctly after insertion of longer overlapping interval', () {
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);
      expect(tree.root!.maxEnd, equals(t(12)));

      // Insert interval in left subtree with very large end time: [08:00, 20:00)
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 8, endHour: 20);
      tree.insert(b2);

      expect(tree.root!.maxEnd, equals(t(20)));
      expect(tree.isValidTree(), isTrue);
    });

    test('maxEnd updates correctly after deletion of the interval having maxEnd', () {
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 8, endHour: 20); // Has maxEnd 20
      final b3 = makeBooking(id: 'B3', slotId: 'P01', startHour: 14, endHour: 15);

      tree.insert(b1);
      tree.insert(b2);
      tree.insert(b3);

      expect(tree.root!.maxEnd, equals(t(20)));

      // Delete B2
      tree.remove('B2');

      expect(tree.contains('B2'), isFalse);
      // New maxEnd should be 15 (from B3)
      expect(tree.root!.maxEnd, equals(t(15)));
      expect(tree.isValidTree(), isTrue);
    });

    test('maxEnd remains strictly correct after rotations', () {
      // Cause an RR rotation: 10, 20, 30
      // Give node 10 an end time of 18
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 9, endHour: 18);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 12, endHour: 14);
      final b3 = makeBooking(id: 'B3', slotId: 'P01', startHour: 15, endHour: 16);

      tree.insert(b1);
      tree.insert(b2);
      tree.insert(b3); // Triggers RR rotation; B2 becomes root

      expect(tree.root!.id, equals('B2'));
      expect(tree.root!.maxEnd, equals(t(18)));
      expect(tree.root!.left!.id, equals('B1'));
      expect(tree.root!.left!.maxEnd, equals(t(18)));
      expect(tree.root!.right!.id, equals('B3'));
      expect(tree.root!.right!.maxEnd, equals(t(16)));
      expect(tree.isValidTree(), isTrue);
    });

    test('subtree pruning does not miss intervals when left subtree has high maxEnd', () {
      // Left child starts at 8:00 but extends until 18:00
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 12, endHour: 14);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 8, endHour: 18);
      final b3 = makeBooking(id: 'B3', slotId: 'P01', startHour: 15, endHour: 16);

      tree.insert(b1);
      tree.insert(b2);
      tree.insert(b3);

      // Query [15:30, 16:30):
      // - b1 [12:00, 14:00) at root: does not overlap
      // - b2 [08:00, 18:00) in left subtree: starts before b1, but maxEnd 18:00 > 15:30, so left is NOT pruned and b2 is found
      // - b3 [15:00, 16:00) in right subtree: overlaps 15:30-16:00 and is found
      final overlaps = tree.searchOverlaps(t(15, 30), t(16, 30));

      expect(overlaps.length, equals(2));
      expect(overlaps.map((b) => b.id), containsAll(['B2', 'B3']));
      expect(overlaps.map((b) => b.id), isNot(contains('B1')));
    });

    test('subtree pruning does not miss intervals when right subtree has matching start', () {
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 14, endHour: 16);
      tree.insert(b1);
      tree.insert(b2);

      // Query [13:00, 15:00): overlaps with right child B2
      final overlaps = tree.searchOverlaps(t(13), t(15));

      expect(overlaps.length, equals(1));
      expect(overlaps.first.id, equals('B2'));
    });
  });

  group('CustomIntervalTree - Duplicates and Edge Cases', () {
    late CustomIntervalTree tree;

    setUp(() {
      tree = CustomIntervalTree();
    });

    test('duplicate booking identifier insertion is rejected and returns false', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final duplicate = makeBooking(id: 'B01', slotId: 'P02', startHour: 14, endHour: 16);

      expect(tree.insert(b1), isTrue);
      expect(tree.insert(duplicate), isFalse);
      expect(tree.size, equals(1));
      expect(tree.get('B01'), equals(b1)); // Did not replace
      expect(tree.isValidTree(), isTrue);
    });

    test('multiple bookings with identical start times are deterministically ordered', () {
      // Both start at 10:00, but have different ends
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B02', slotId: 'P02', startHour: 10, endHour: 14);

      expect(tree.insert(b1), isTrue);
      expect(tree.insert(b2), isTrue);
      expect(tree.size, equals(2));
      expect(tree.isValidTree(), isTrue);

      final overlaps = tree.searchOverlaps(t(11), t(13));
      expect(overlaps.length, equals(2));
      expect(overlaps.map((b) => b.id), containsAll(['B01', 'B02']));
    });

    test('multiple bookings with identical start and end times are deterministically ordered by id', () {
      // Identical interval [10:00, 12:00) on different slots
      final b1 = makeBooking(id: 'B_ALPHA', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B_BETA', slotId: 'P02', startHour: 10, endHour: 12);

      expect(tree.insert(b1), isTrue);
      expect(tree.insert(b2), isTrue);
      expect(tree.size, equals(2));
      expect(tree.isValidTree(), isTrue);

      final overlaps = tree.searchOverlaps(t(10), t(12));
      expect(overlaps.length, equals(2));
      // In-order traversal must be sorted by ID when times are identical
      expect(overlaps.first.id, equals('B_ALPHA'));
      expect(overlaps.last.id, equals('B_BETA'));
    });

    test('removing root of single-node tree results in valid empty tree', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      tree.insert(b1);

      expect(tree.remove('B01'), isTrue);
      expect(tree.size, equals(0));
      expect(tree.isEmpty, isTrue);
      expect(tree.root, isNull);
      expect(tree.isValidTree(), isTrue);
    });

    test('removing root with single child preserves remaining subtree', () {
      final b1 = makeBooking(id: 'B01', slotId: 'P01', startHour: 10, endHour: 12);
      final b2 = makeBooking(id: 'B02', slotId: 'P01', startHour: 14, endHour: 16);
      tree.insert(b1);
      tree.insert(b2);

      expect(tree.remove('B01'), isTrue);
      expect(tree.size, equals(1));
      expect(tree.root!.id, equals('B02'));
      expect(tree.isValidTree(), isTrue);
    });

    test('repeated insertion and deletion stress test preserves invariants', () {
      final ids = <String>[];
      for (int i = 0; i < 40; i++) {
        final id = 'STRESS_${i.toString().padLeft(3, '0')}';
        ids.add(id);
        tree.insert(
          makeBooking(
            id: id,
            slotId: 'P${(i % 20 + 1).toString().padLeft(2, '0')}',
            startHour: (i * 23) % 20,
            endHour: ((i * 23) % 20) + 1 + (i % 3),
          ),
        );
        expect(tree.isValidTree(), isTrue);
      }

      expect(tree.size, equals(40));

      // Remove every second booking
      for (int i = 0; i < ids.length; i += 2) {
        expect(tree.remove(ids[i]), isTrue);
        expect(tree.isValidTree(), isTrue);
      }

      expect(tree.size, equals(20));

      // Ensure remaining are present and deleted are absent
      for (int i = 0; i < ids.length; i++) {
        if (i % 2 == 0) {
          expect(tree.contains(ids[i]), isFalse);
        } else {
          expect(tree.contains(ids[i]), isTrue);
        }
      }
    });

    test('toList returns all bookings in sorted in-order traversal', () {
      final b3 = makeBooking(id: 'B3', slotId: 'P01', startHour: 15, endHour: 17);
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 9, endHour: 11);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 12, endHour: 14);

      tree.insert(b3);
      tree.insert(b1);
      tree.insert(b2);

      final list = tree.toList();
      expect(list.map((b) => b.id).toList(), equals(['B1', 'B2', 'B3']));
    });

    test('removeBooking by instance removes cleanly in O(log n)', () {
      final b1 = makeBooking(id: 'B1', slotId: 'P01', startHour: 9, endHour: 11);
      final b2 = makeBooking(id: 'B2', slotId: 'P01', startHour: 12, endHour: 14);
      tree.insert(b1);
      tree.insert(b2);

      expect(tree.removeBooking(b1), isTrue);
      expect(tree.size, equals(1));
      expect(tree.contains('B1'), isFalse);
      expect(tree.isValidTree(), isTrue);

      // Attempting to remove already removed booking returns false
      expect(tree.removeBooking(b1), isFalse);
    });
  });
}
