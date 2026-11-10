export 'parking_slot_candidate.dart';

/// A generic Binary Min-Heap implemented from first principles using a contiguous Dart [List].
///
/// Built for the SmartPark academic parking management prototype (Phase 2.4).
///
/// This implementation does NOT use Dart's built-in `PriorityQueue` or third-party packages.
///
/// Key algorithmic components:
/// 1. **Complete Binary Tree representation**: Mapped to 0-indexed contiguous array.
/// 2. **Index Formulas**:
///    - Parent: `(i - 1) ~/ 2`
///    - Left child: `2 * i + 1`
///    - Right child: `2 * i + 2`
/// 3. **Min-Heap Property**: For every node $i > 0$, `comparator(elements[parent(i)], elements[i]) <= 0`.
/// 4. **Sift Up**: Restores invariant in O(log n) after inserting at the bottom/end of the heap.
/// 5. **Sift Down**: Restores invariant in O(log n) after moving the last element to the root on extraction.
/// 6. **Bottom-Up Heap Construction (Floyd's Algorithm)**: Builds a valid heap in O(n) time.
///
/// // ponytail: contiguous List backing, zero-indexed integer math, standard comparator
class CustomMinHeap<T> {
  final List<T> _elements;
  final int Function(T a, T b) _comparator;

  /// Creates an empty [CustomMinHeap].
  ///
  /// If [comparator] is omitted, [T] must implement [Comparable].
  CustomMinHeap([int Function(T a, T b)? comparator])
      : _comparator = comparator ?? _defaultComparator<T>(),
        _elements = [];

  /// Creates a [CustomMinHeap] populated from [elements] using O(n) Floyd's algorithm.
  factory CustomMinHeap.from(
    Iterable<T> elements, [
    int Function(T a, T b)? comparator,
  ]) {
    final heap = CustomMinHeap<T>(comparator);
    heap.buildHeap(elements);
    return heap;
  }

  /// Default comparator for types implementing [Comparable].
  static int Function(T a, T b) _defaultComparator<T>() {
    return (T a, T b) {
      if (a is Comparable) {
        return a.compareTo(b);
      }
      throw StateError(
        'No comparator provided and element type does not implement Comparable: $T',
      );
    };
  }

  /// Inserts [item] into the heap in O(log n) time.
  ///
  /// Appends [item] to the end of the backing array and bubbles it up
  /// to its correct position via [_siftUp].
  void insert(T item) {
    _elements.add(item);
    _siftUp(_elements.length - 1);
  }

  /// Returns the minimum element without removing it in O(1) time.
  ///
  /// Returns `null` if the heap is empty.
  T? peek() {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements[0];
  }

  /// Removes and returns the minimum element from the root in O(log n) time.
  ///
  /// Returns `null` if the heap is empty.
  /// If the heap contains a single element, it is removed and returned in O(1).
  /// Otherwise, the last element replaces the root, and [_siftDown] restores
  /// the min-heap invariant.
  T? extractMin() {
    if (_elements.isEmpty) {
      return null;
    }
    if (_elements.length == 1) {
      return _elements.removeLast();
    }

    final root = _elements[0];
    _elements[0] = _elements.removeLast();
    _siftDown(0);
    return root;
  }

  /// Populates the heap with [items] in O(n) time using bottom-up heapification.
  ///
  /// Clears any existing elements, adds all [items], and runs [_siftDown]
  /// starting from the last non-leaf parent node down to the root.
  void buildHeap(Iterable<T> items) {
    _elements.clear();
    _elements.addAll(items);

    if (_elements.length <= 1) {
      return;
    }

    // Index of the last non-leaf node: parent of last element (n - 1)
    // parent(n - 1) = ((n - 1) - 1) ~/ 2 = (n - 2) ~/ 2
    final lastNonLeafIndex = (_elements.length - 2) ~/ 2;
    for (int i = lastNonLeafIndex; i >= 0; i--) {
      _siftDown(i);
    }
  }

  /// Removes all elements from the heap.
  void clear() {
    _elements.clear();
  }

  /// Total number of elements currently stored in the heap.
  int get size => _elements.length;

  /// Whether the heap contains zero elements.
  bool get isEmpty => _elements.isEmpty;

  /// Whether the heap contains at least one element.
  bool get isNotEmpty => _elements.isNotEmpty;

  /// Returns an unmodifiable snapshot of the backing array in level-order.
  List<T> get elements => List.unmodifiable(_elements);

  /// Moves the element at [index] upward until the min-heap invariant is restored.
  ///
  /// Repeatedly compares with parent at `(index - 1) ~/ 2`. If the child has higher
  /// priority (smaller value), it swaps with the parent.
  void _siftUp(int index) {
    var current = index;
    while (current > 0) {
      final parentIndex = (current - 1) ~/ 2;
      // If current element < parent element, swap
      if (_comparator(_elements[current], _elements[parentIndex]) < 0) {
        _swap(current, parentIndex);
        current = parentIndex;
      } else {
        break;
      }
    }
  }

  /// Moves the element at [index] downward until the min-heap invariant is restored.
  ///
  /// Repeatedly identifies the smallest among [index], its left child, and its
  /// right child. If a child has higher priority (smaller value), it swaps with
  /// that child and continues downward.
  void _siftDown(int index) {
    var current = index;
    final length = _elements.length;

    while (true) {
      var smallest = current;
      final leftChild = 2 * current + 1;
      final rightChild = 2 * current + 2;

      if (leftChild < length &&
          _comparator(_elements[leftChild], _elements[smallest]) < 0) {
        smallest = leftChild;
      }

      if (rightChild < length &&
          _comparator(_elements[rightChild], _elements[smallest]) < 0) {
        smallest = rightChild;
      }

      if (smallest != current) {
        _swap(current, smallest);
        current = smallest;
      } else {
        break;
      }
    }
  }

  /// Swaps elements at indices [i] and [j] in the backing list.
  void _swap(int i, int j) {
    final temp = _elements[i];
    _elements[i] = _elements[j];
    _elements[j] = temp;
  }

  /// Validates whether the backing array satisfies the min-heap invariant.
  ///
  /// Academic verification helper for testing and viva demonstration.
  bool isValidHeap() {
    final length = _elements.length;
    for (int i = 0; i <= (length - 2) ~/ 2; i++) {
      final left = 2 * i + 1;
      final right = 2 * i + 2;

      if (left < length && _comparator(_elements[left], _elements[i]) < 0) {
        return false;
      }
      if (right < length && _comparator(_elements[right], _elements[i]) < 0) {
        return false;
      }
    }
    return true;
  }
}

