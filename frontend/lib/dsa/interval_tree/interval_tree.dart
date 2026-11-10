import '../../models/booking.dart';
import 'interval_tree_node.dart';

export 'interval_tree_node.dart';

/// A self-balancing AVL Interval Tree augmented with subtree `maxEnd`.
///
/// Built for the SmartPark academic parking management prototype (Phase 2.5).
///
/// This implementation does NOT use built-in balanced trees or external packages.
///
/// Key algorithmic invariants:
/// 1. **AVL Height-Balance Invariant**:
///    For every node $u$, $\text{balanceFactor}(u) = \text{height}(u.left) - \text{height}(u.right) \in \{-1, 0, 1\}$.
/// 2. **Interval Augmentation Invariant**:
///    For every node $u$, $u.\text{maxEnd} = \max(u.\text{booking.endTime}, u.left?.\text{maxEnd}, u.right?.\text{maxEnd})$.
/// 3. **Half-Open Interval Semantics**:
///    $[start, end)$ where start is inclusive and end is exclusive.
///    Two intervals overlap if and only if $s_1 < e_2 \land s_2 < e_1$.
///    Adjacent intervals (e.g. 10:00-11:00 and 11:00-12:00) do NOT overlap.
/// 4. **Deterministic Ordering**:
///    Nodes with identical start times are ordered by start time, then end time,
///    then unique booking id.
///
/// // ponytail: direct domain Booking wrapping, standard AVL rotations, honest O(n) slot filtering
class CustomIntervalTree {
  IntervalTreeNode? _root;
  int _size = 0;

  /// Creates an empty [CustomIntervalTree].
  CustomIntervalTree();

  /// Total number of active booking intervals in the tree.
  int get size => _size;

  /// Whether the tree contains zero bookings.
  bool get isEmpty => _size == 0;

  /// Whether the tree contains at least one booking.
  bool get isNotEmpty => _size > 0;

  /// Height of the tree (0 if empty).
  int get height => _root?.height ?? 0;

  /// The root node of the tree (exposed for testing and viva inspection).
  IntervalTreeNode? get root => _root;

  /// Deterministic comparator ordering bookings:
  /// 1. Ascending [Booking.startTime].
  /// 2. Ascending [Booking.endTime] (tie-breaker for equal start times).
  /// 3. Ascending [Booking.id] (tie-breaker for identical time ranges).
  static int _compareBookings(Booking a, Booking b) {
    final startCmp = a.startTime.compareTo(b.startTime);
    if (startCmp != 0) return startCmp;

    final endCmp = a.endTime.compareTo(b.endTime);
    if (endCmp != 0) return endCmp;

    return a.id.compareTo(b.id);
  }

  /// Returns the height of [node] (0 for null).
  static int _nodeHeight(IntervalTreeNode? node) => node?.height ?? 0;

  /// Returns the balance factor of [node]: `height(left) - height(right)`.
  static int _balanceFactor(IntervalTreeNode node) =>
      _nodeHeight(node.left) - _nodeHeight(node.right);

  /// Recomputes [node.height] and [node.maxEnd] from its children in O(1) time.
  static void _updateNode(IntervalTreeNode node) {
    final leftHeight = _nodeHeight(node.left);
    final rightHeight = _nodeHeight(node.right);
    node.height = 1 + (leftHeight > rightHeight ? leftHeight : rightHeight);

    var max = node.booking.endTime;
    if (node.left != null && node.left!.maxEnd.isAfter(max)) {
      max = node.left!.maxEnd;
    }
    if (node.right != null && node.right!.maxEnd.isAfter(max)) {
      max = node.right!.maxEnd;
    }
    node.maxEnd = max;
  }

  /// Performs an AVL Right Rotation on node [y].
  ///
  /// ```
  ///        y                               x
  ///       / \                             / \
  ///      x   T3   -- RightRotate(y) -->  T1  y
  ///     / \                                 / \
  ///    T1  T2                              T2  T3
  /// ```
  /// Updates [y] first, then [x] so augmentation metadata remains valid.
  static IntervalTreeNode _rotateRight(IntervalTreeNode y) {
    final x = y.left!;
    final t2 = x.right;

    x.right = y;
    y.left = t2;

    _updateNode(y);
    _updateNode(x);

    return x;
  }

  /// Performs an AVL Left Rotation on node [x].
  ///
  /// ```
  ///      x                                 y
  ///     / \                               / \
  ///    T1  y      -- LeftRotate(x) -->   x   T3
  ///       / \                           / \
  ///      T2  T3                        T1  T2
  /// ```
  /// Updates [x] first, then [y] so augmentation metadata remains valid.
  static IntervalTreeNode _rotateLeft(IntervalTreeNode x) {
    final y = x.right!;
    final t2 = y.left;

    y.left = x;
    x.right = t2;

    _updateNode(x);
    _updateNode(y);

    return y;
  }

  /// Restores the AVL balance invariant at [node] and updates `maxEnd`.
  ///
  /// Handles all 4 imbalance cases:
  /// - Left-Left (LL): Right rotation.
  /// - Right-Right (RR): Left rotation.
  /// - Left-Right (LR): Left rotate left child, then right rotate node.
  /// - Right-Left (RL): Right rotate right child, then left rotate node.
  static IntervalTreeNode _rebalance(IntervalTreeNode node) {
    _updateNode(node);
    final balance = _balanceFactor(node);

    // Left-heavy
    if (balance > 1) {
      if (_balanceFactor(node.left!) < 0) {
        // Left-Right case
        node.left = _rotateLeft(node.left!);
      }
      // Left-Left case
      return _rotateRight(node);
    }

    // Right-heavy
    if (balance < -1) {
      if (_balanceFactor(node.right!) > 0) {
        // Right-Left case
        node.right = _rotateRight(node.right!);
      }
      // Right-Right case
      return _rotateLeft(node);
    }

    return node;
  }

  /// Traverses the tree to find an [IntervalTreeNode] with matching booking [id].
  ///
  /// // ponytail: linear scan for non-key identifier lookup; O(n) worst-case
  static IntervalTreeNode? _findNodeById(IntervalTreeNode? node, String id) {
    if (node == null) return null;
    if (node.id == id) return node;

    final leftSearch = _findNodeById(node.left, id);
    if (leftSearch != null) return leftSearch;

    return _findNodeById(node.right, id);
  }

  /// Finds the node with the minimum booking under [_compareBookings] in [node]'s subtree.
  static IntervalTreeNode _findMin(IntervalTreeNode node) {
    var current = node;
    while (current.left != null) {
      current = current.left!;
    }
    return current;
  }

  /// Inserts [booking] into the interval tree.
  ///
  /// Returns `true` if inserted successfully.
  /// Returns `false` if a booking with the same [booking.id] already exists in the tree.
  ///
  /// Preserves the AVL balance property and correctly updates `maxEnd` on all ancestors.
  bool insert(Booking booking) {
    // Prevent duplicate booking IDs from entering the tree
    if (_findNodeById(_root, booking.id) != null) {
      return false;
    }

    _root = _insertRecursive(_root, booking);
    _size++;
    return true;
  }

  /// Convenience alias for [insert].
  bool add(Booking booking) => insert(booking);

  IntervalTreeNode _insertRecursive(IntervalTreeNode? node, Booking booking) {
    if (node == null) {
      return IntervalTreeNode(booking: booking);
    }

    final cmp = _compareBookings(booking, node.booking);
    if (cmp < 0) {
      node.left = _insertRecursive(node.left, booking);
    } else if (cmp > 0) {
      node.right = _insertRecursive(node.right, booking);
    } else {
      // Identical booking already in tree (guarded by ID check earlier)
      return node;
    }

    return _rebalance(node);
  }

  /// Removes the booking with [bookingId] from the tree.
  ///
  /// Returns `true` if the booking was found and removed; `false` otherwise.
  ///
  /// Restores the AVL invariant and updates `maxEnd` throughout the affected path.
  bool remove(String bookingId) {
    final trimmedId = bookingId.trim();
    if (trimmedId.isEmpty) return false;

    final targetNode = _findNodeById(_root, trimmedId);
    if (targetNode == null) return false;

    _root = _deleteRecursive(_root, targetNode.booking);
    _size--;
    return true;
  }

  /// Removes [booking] directly from the tree using logarithmic BST search.
  ///
  /// Returns `true` if found and removed; `false` otherwise.
  bool removeBooking(Booking booking) {
    final targetNode = _findNodeByBooking(_root, booking);
    if (targetNode == null) return false;

    _root = _deleteRecursive(_root, booking);
    _size--;
    return true;
  }

  /// Locates a node in O(log n) time using the deterministic comparator.
  static IntervalTreeNode? _findNodeByBooking(
    IntervalTreeNode? node,
    Booking booking,
  ) {
    if (node == null) return null;
    final cmp = _compareBookings(booking, node.booking);
    if (cmp < 0) return _findNodeByBooking(node.left, booking);
    if (cmp > 0) return _findNodeByBooking(node.right, booking);
    return node;
  }

  /// Recursively deletes [target] from the subtree rooted at [node].
  IntervalTreeNode? _deleteRecursive(
    IntervalTreeNode? node,
    Booking target,
  ) {
    if (node == null) return null;

    final cmp = _compareBookings(target, node.booking);
    if (cmp < 0) {
      node.left = _deleteRecursive(node.left, target);
    } else if (cmp > 0) {
      node.right = _deleteRecursive(node.right, target);
    } else {
      // Node to delete located
      if (node.left == null) {
        return node.right;
      } else if (node.right == null) {
        return node.left;
      } else {
        // Two children: replace with in-order successor (min of right subtree)
        final successor = _findMin(node.right!);
        node.booking = successor.booking;
        node.right = _deleteRecursive(node.right, successor.booking);
      }
    }

    return _rebalance(node);
  }

  /// Retrieves the [Booking] with [bookingId], or `null` if not found.
  Booking? get(String bookingId) {
    final node = _findNodeById(_root, bookingId.trim());
    return node?.booking;
  }

  /// Checks whether a booking with [bookingId] is stored in the tree.
  bool contains(String bookingId) => get(bookingId) != null;

  /// Removes all bookings from the tree, resetting size to 0.
  void clear() {
    _root = null;
    _size = 0;
  }

  /// Searches and returns all bookings overlapping the query range `[startTime, endTime)`.
  ///
  /// Uses subtree `maxEnd` augmentation to prune subtrees that cannot contain an overlap.
  /// Results are returned in ascending order of interval start times (in-order traversal).
  ///
  /// Throws [ArgumentError] if [endTime] is not strictly after [startTime].
  List<Booking> searchOverlaps(DateTime startTime, DateTime endTime) {
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'Query end time (${endTime.toIso8601String()}) must be strictly '
        'later than start time (${startTime.toIso8601String()})',
      );
    }

    final results = <Booking>[];
    _searchOverlapsRecursive(_root, startTime, endTime, results);
    return results;
  }

  /// Alias matching proposed design in `DSA_DESIGN.md`.
  List<Booking> queryAllOverlaps(DateTime startTime, DateTime endTime) =>
      searchOverlaps(startTime, endTime);

  /// Convenience overload querying overlaps for an existing [booking]'s time window.
  List<Booking> searchOverlapsForBooking(Booking booking) =>
      searchOverlaps(booking.startTime, booking.endTime);

  static void _searchOverlapsRecursive(
    IntervalTreeNode? node,
    DateTime start,
    DateTime end,
    List<Booking> results,
  ) {
    if (node == null) return;

    // 1. Explore left subtree if its maximum end extends beyond query start
    if (node.left != null && node.left!.maxEnd.isAfter(start)) {
      _searchOverlapsRecursive(node.left, start, end, results);
    }

    // 2. Check current node interval
    if (node.booking.overlapsInterval(start, end)) {
      results.add(node.booking);
    }

    // 3. Explore right subtree if current node's start time precedes query end
    //    and right subtree's maximum end extends beyond query start
    if (node.right != null &&
        node.startTime.isBefore(end) &&
        node.right!.maxEnd.isAfter(start)) {
      _searchOverlapsRecursive(node.right, start, end, results);
    }
  }

  /// Returns the first booking overlapping `[startTime, endTime)`, or `null` if none exist.
  ///
  /// Performs early termination as soon as any overlap is identified.
  Booking? searchFirstOverlap(DateTime startTime, DateTime endTime) {
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'Query end time (${endTime.toIso8601String()}) must be strictly '
        'later than start time (${startTime.toIso8601String()})',
      );
    }

    return _searchFirstOverlapRecursive(_root, startTime, endTime);
  }

  static Booking? _searchFirstOverlapRecursive(
    IntervalTreeNode? node,
    DateTime start,
    DateTime end,
  ) {
    if (node == null) return null;

    // Check left subtree
    if (node.left != null && node.left!.maxEnd.isAfter(start)) {
      final match = _searchFirstOverlapRecursive(node.left, start, end);
      if (match != null) return match;
    }

    // Check current node
    if (node.booking.overlapsInterval(start, end)) {
      return node.booking;
    }

    // Check right subtree
    if (node.right != null &&
        node.startTime.isBefore(end) &&
        node.right!.maxEnd.isAfter(start)) {
      return _searchFirstOverlapRecursive(node.right, start, end);
    }

    return null;
  }

  /// Checks whether any booking in the tree overlaps `[startTime, endTime)`.
  bool hasOverlap(DateTime startTime, DateTime endTime) =>
      searchFirstOverlap(startTime, endTime) != null;

  /// Checks whether a booking conflict exists for the specified [slotId]
  /// across the query interval `[startTime, endTime)`.
  ///
  /// Returns `true` if and only if:
  /// 1. A booking overlaps temporally with `[startTime, endTime)`.
  /// 2. The overlapping booking belongs to the exact [slotId].
  ///
  /// Bookings for different slots never conflict.
  bool hasConflict(String slotId, DateTime startTime, DateTime endTime) {
    if (slotId.trim().isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'Slot id cannot be empty');
    }
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'Query end time (${endTime.toIso8601String()}) must be strictly '
        'later than start time (${startTime.toIso8601String()})',
      );
    }

    return _hasConflictRecursive(_root, slotId.trim(), startTime, endTime);
  }

  /// Convenience overload checking conflicts for a prospective [booking].
  bool hasBookingConflict(Booking booking) =>
      hasConflict(booking.slotId, booking.startTime, booking.endTime);

  static bool _hasConflictRecursive(
    IntervalTreeNode? node,
    String slotId,
    DateTime start,
    DateTime end,
  ) {
    if (node == null) return false;

    // 1. Search left if potential overlap exists
    if (node.left != null && node.left!.maxEnd.isAfter(start)) {
      if (_hasConflictRecursive(node.left, slotId, start, end)) {
        return true;
      }
    }

    // 2. Check current node
    if (node.slotId == slotId && node.booking.overlapsInterval(start, end)) {
      return true;
    }

    // 3. Search right if potential overlap exists
    if (node.right != null &&
        node.startTime.isBefore(end) &&
        node.right!.maxEnd.isAfter(start)) {
      if (_hasConflictRecursive(node.right, slotId, start, end)) {
        return true;
      }
    }

    return false;
  }

  /// Finds and returns all bookings for [slotId] conflicting with `[startTime, endTime)`.
  List<Booking> findConflicts(
    String slotId,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (slotId.trim().isEmpty) {
      throw ArgumentError.value(slotId, 'slotId', 'Slot id cannot be empty');
    }
    final normalizedSlotId = slotId.trim();
    final allOverlaps = searchOverlaps(startTime, endTime);
    return allOverlaps.where((b) => b.slotId == normalizedSlotId).toList();
  }

  /// Convenience overload returning conflicts for a prospective [booking].
  List<Booking> findBookingConflicts(Booking booking) =>
      findConflicts(booking.slotId, booking.startTime, booking.endTime);

  /// Returns an in-order [List] of all bookings stored in the tree.
  List<Booking> toList() {
    final list = <Booking>[];
    _inOrderTraversal(_root, list);
    return list;
  }

  static void _inOrderTraversal(
    IntervalTreeNode? node,
    List<Booking> list,
  ) {
    if (node == null) return;
    _inOrderTraversal(node.left, list);
    list.add(node.booking);
    _inOrderTraversal(node.right, list);
  }

  /// Validates both the AVL balance invariant and the `maxEnd` augmentation invariant.
  ///
  /// Academic verification helper for testing and viva demonstration.
  ///
  /// Checks:
  /// 1. BST order with deterministic comparator.
  /// 2. Height correctness: $h = 1 + \max(h_{left}, h_{right})$.
  /// 3. AVL balance condition: $|h_{left} - h_{right}| \le 1$.
  /// 4. Subtree `maxEnd` correctness: $\text{maxEnd} = \max(\text{end}, \text{maxEnd}_{left}, \text{maxEnd}_{right})$.
  /// 5. Node count matches recorded [_size].
  bool isValidTree() {
    if (_root == null) {
      return _size == 0;
    }
    int visitedCount = 0;
    final valid = _validateSubtree(_root, null, null, () => visitedCount++);
    return valid && visitedCount == _size;
  }

  static bool _validateSubtree(
    IntervalTreeNode? node,
    Booking? minBound,
    Booking? maxBound,
    void Function() onNodeVisited,
  ) {
    if (node == null) return true;

    onNodeVisited();

    // 1. BST bounds check
    if (minBound != null && _compareBookings(node.booking, minBound) <= 0) {
      return false;
    }
    if (maxBound != null && _compareBookings(node.booking, maxBound) >= 0) {
      return false;
    }

    // 2. Height invariant check
    final leftHeight = _nodeHeight(node.left);
    final rightHeight = _nodeHeight(node.right);
    final expectedHeight = 1 + (leftHeight > rightHeight ? leftHeight : rightHeight);
    if (node.height != expectedHeight) {
      return false;
    }

    // 3. AVL balance invariant check: |balanceFactor| <= 1
    final balance = leftHeight - rightHeight;
    if (balance < -1 || balance > 1) {
      return false;
    }

    // 4. Augmentation invariant check: maxEnd
    var expectedMaxEnd = node.booking.endTime;
    if (node.left != null && node.left!.maxEnd.isAfter(expectedMaxEnd)) {
      expectedMaxEnd = node.left!.maxEnd;
    }
    if (node.right != null && node.right!.maxEnd.isAfter(expectedMaxEnd)) {
      expectedMaxEnd = node.right!.maxEnd;
    }
    if (node.maxEnd != expectedMaxEnd) {
      return false;
    }

    // 5. Recursively validate subtrees
    return _validateSubtree(node.left, minBound, node.booking, onNodeVisited) &&
        _validateSubtree(node.right, node.booking, maxBound, onNodeVisited);
  }
}

/// Academic alias for [CustomIntervalTree] as described in project documentation.
typedef IntervalTree = CustomIntervalTree;

