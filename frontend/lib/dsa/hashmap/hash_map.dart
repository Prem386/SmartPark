import 'hash_node.dart';

export 'hash_node.dart';

/// A generic HashMap implemented from first principles using Separate Chaining.
///
/// Built for the SmartPark academic parking management prototype (Phase 2.3).
///
/// This implementation does NOT use Dart's built-in [Map] or `dart:collection` HashMap.
///
/// Key algorithmic components:
/// 1. **Bucket Array**: Contiguous array (`List<HashNode<K, V>?>`) of bucket heads.
/// 2. **31-bit Hash Calculation**: `key.hashCode & 0x7FFFFFFF` to prevent negative values.
/// 3. **Bucket Indexing**: `hash % capacity` mapping keys into `[0, capacity - 1]`.
/// 4. **Separate Chaining**: Singly-linked list chains in each bucket for collision resolution.
/// 5. **Dynamic Resizing & Rehashing**: Automatically doubles capacity when load factor
///    threshold (default: 0.75) is reached, preserving all entries.
///
/// // ponytail: standard separate chaining, no speculative abstractions, minimal O(1) ops
class CustomHashMap<K, V> {
  /// Default initial bucket array capacity (16 buckets).
  static const int defaultInitialCapacity = 16;

  /// Default maximum load factor threshold (0.75).
  static const double defaultLoadFactorThreshold = 0.75;

  final int _initialCapacity;
  final double _loadFactorThreshold;

  int _capacity;
  int _size = 0;
  List<HashNode<K, V>?> _buckets;

  /// Creates a [CustomHashMap] with optional [initialCapacity] and [loadFactorThreshold].
  CustomHashMap({
    int initialCapacity = defaultInitialCapacity,
    double loadFactorThreshold = defaultLoadFactorThreshold,
  })  : _initialCapacity = initialCapacity,
        _loadFactorThreshold = loadFactorThreshold,
        _capacity = initialCapacity,
        _buckets = List<HashNode<K, V>?>.filled(initialCapacity, null) {
    if (initialCapacity <= 0) {
      throw ArgumentError.value(
        initialCapacity,
        'initialCapacity',
        'Initial capacity must be greater than zero.',
      );
    }
    if (loadFactorThreshold <= 0.0 || loadFactorThreshold.isNaN) {
      throw ArgumentError.value(
        loadFactorThreshold,
        'loadFactorThreshold',
        'Load factor threshold must be a positive number.',
      );
    }
  }

  /// Computes a non-negative 31-bit hash code for [key].
  ///
  /// In Dart, `key.hashCode` returns a signed integer. Masking with `0x7FFFFFFF`
  /// clears the sign bit, guaranteeing a positive 31-bit integer `[0, 2^31 - 1]`
  /// and avoiding negative modulo index results.
  int _computeHash(K key) {
    return key.hashCode & 0x7FFFFFFF;
  }

  /// Calculates the bucket array index for a given cached [hash] and [capacity].
  ///
  /// Guarantees the resulting index satisfies `0 <= index < capacity`.
  int _getBucketIndex(int hash, int capacity) {
    return hash % capacity;
  }

  /// Inserts or updates the [value] associated with [key].
  ///
  /// - If [key] already exists in the bucket chain, its value is updated in place
  ///   and [size] remains unchanged.
  /// - If [key] does not exist, a new [HashNode] is prepended to the bucket chain
  ///   in O(1) time and [size] is incremented.
  /// - If the new size causes `loadFactor >= loadFactorThreshold`, dynamic resizing
  ///   and rehashing is triggered automatically.
  void put(K key, V value) {
    final hash = _computeHash(key);
    final index = _getBucketIndex(hash, _capacity);

    // 1. Search existing chain in the bucket
    var current = _buckets[index];
    while (current != null) {
      if (current.hash == hash && current.key == key) {
        current.value = value;
        return;
      }
      current = current.next;
    }

    // 2. Key does not exist; prepend new node at head of collision chain
    final newNode = HashNode<K, V>(
      key: key,
      value: value,
      hash: hash,
      next: _buckets[index],
    );
    _buckets[index] = newNode;
    _size++;

    // 3. Trigger dynamic resize and rehash if load factor threshold reached
    if (_size / _capacity >= _loadFactorThreshold) {
      _rehash();
    }
  }

  /// Operator syntax for [put].
  void operator []=(K key, V value) => put(key, value);

  /// Retrieves the value associated with [key], or `null` if not found.
  ///
  /// Traverses the collision chain at the target bucket index.
  /// Does not modify the table structure.
  V? get(K key) {
    final hash = _computeHash(key);
    final index = _getBucketIndex(hash, _capacity);

    var current = _buckets[index];
    while (current != null) {
      if (current.hash == hash && current.key == key) {
        return current.value;
      }
      current = current.next;
    }

    return null;
  }

  /// Operator syntax for [get].
  V? operator [](K key) => get(key);

  /// Checks whether [key] exists in the table.
  ///
  /// Correctly distinguishes an existing key with a `null` value from a missing key.
  bool containsKey(K key) {
    final hash = _computeHash(key);
    final index = _getBucketIndex(hash, _capacity);

    var current = _buckets[index];
    while (current != null) {
      if (current.hash == hash && current.key == key) {
        return true;
      }
      current = current.next;
    }

    return false;
  }

  /// Removes the key-value entry associated with [key].
  ///
  /// Returns the removed value, or `null` if [key] was not found.
  /// Handles removal correctly from the head, middle, or tail of a collision chain.
  /// Decrements [size] only when an existing key is removed.
  V? remove(K key) {
    final hash = _computeHash(key);
    final index = _getBucketIndex(hash, _capacity);

    HashNode<K, V>? current = _buckets[index];
    HashNode<K, V>? previous;

    while (current != null) {
      if (current.hash == hash && current.key == key) {
        if (previous == null) {
          // Target is head of bucket chain
          _buckets[index] = current.next;
        } else {
          // Target is in middle or at tail of bucket chain
          previous.next = current.next;
        }
        current.next = null; // Clean dangling pointer
        _size--;
        return current.value;
      }
      previous = current;
      current = current.next;
    }

    return null;
  }

  /// Removes all entries from the table and resets capacity to [_initialCapacity].
  void clear() {
    _capacity = _initialCapacity;
    _buckets = List<HashNode<K, V>?>.filled(_capacity, null);
    _size = 0;
  }

  /// Doubles the bucket array capacity and rehashes all existing entries.
  ///
  /// Reallocates a bucket array with double the previous capacity,
  /// recalculates bucket indices using cached hash codes, and relinks
  /// existing nodes without losing or duplicating entries.
  void _rehash() {
    final newCapacity = _capacity * 2;
    final newBuckets = List<HashNode<K, V>?>.filled(newCapacity, null);

    for (int i = 0; i < _capacity; i++) {
      var current = _buckets[i];
      while (current != null) {
        final nextNode = current.next;
        final newIndex = _getBucketIndex(current.hash, newCapacity);

        // Prepend current node to the new bucket chain
        current.next = newBuckets[newIndex];
        newBuckets[newIndex] = current;

        current = nextNode;
      }
    }

    _buckets = newBuckets;
    _capacity = newCapacity;
  }

  /// Total number of active key-value pairs stored in the table.
  int get size => _size;

  /// Whether the table contains zero entries.
  bool get isEmpty => _size == 0;

  /// Whether the table contains at least one entry.
  bool get isNotEmpty => _size > 0;

  /// Current number of buckets in the underlying array.
  int get capacity => _capacity;

  /// Current load factor (`size / capacity`).
  double get loadFactor => _size / _capacity;

  /// Maximum load factor threshold triggering dynamic resizing.
  double get loadFactorThreshold => _loadFactorThreshold;

  /// An [Iterable] of all keys stored in the table.
  ///
  /// Traverses through the bucket chains without using Dart's built-in Map.
  Iterable<K> get keys sync* {
    for (int i = 0; i < _capacity; i++) {
      var current = _buckets[i];
      while (current != null) {
        yield current.key;
        current = current.next;
      }
    }
  }

  /// An [Iterable] of all values stored in the table.
  ///
  /// Traverses through the bucket chains without using Dart's built-in Map.
  Iterable<V> get values sync* {
    for (int i = 0; i < _capacity; i++) {
      var current = _buckets[i];
      while (current != null) {
        yield current.value;
        current = current.next;
      }
    }
  }

  /// An [Iterable] of all [HashNode] entries stored in the table.
  ///
  /// Traverses through the bucket chains without using Dart's built-in Map.
  Iterable<HashNode<K, V>> get entries sync* {
    for (int i = 0; i < _capacity; i++) {
      var current = _buckets[i];
      while (current != null) {
        yield current;
        current = current.next;
      }
    }
  }

  /// Returns the bucket index where [key] is mapped under current capacity.
  ///
  /// Academic demonstration helper for viva defense and collision verification.
  int bucketIndexFor(K key) {
    return _getBucketIndex(_computeHash(key), _capacity);
  }

  /// Returns the number of colliding entries in bucket [index].
  ///
  /// Academic demonstration helper for viva defense and chain inspection.
  int chainLength(int index) {
    if (index < 0 || index >= _capacity) {
      throw RangeError.index(index, _buckets, 'index');
    }
    int count = 0;
    var current = _buckets[index];
    while (current != null) {
      count++;
      current = current.next;
    }
    return count;
  }
}

/// Academic alias for [CustomHashMap] as described in project documentation.
typedef HashMap<K, V> = CustomHashMap<K, V>;
