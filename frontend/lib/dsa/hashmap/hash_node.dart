/// Represents a single key-value entry in the [CustomHashMap] collision chain.
///
/// Implements Separate Chaining: when multiple keys hash to the same bucket index,
/// they form a singly-linked list of nodes connected via [next].
///
/// Academic demonstration component for SmartPark DSA Phase 2.3.
/// // ponytail: minimal node structure with cached 31-bit hash code for fast traversal
class HashNode<K, V> {
  /// Search key for this entry.
  final K key;

  /// Value payload mapped to [key].
  V value;

  /// Cached 31-bit non-negative hash code of [key].
  ///
  /// Caching avoids recomputing expensive hash codes during collision
  /// traversals and dynamic table rehashing.
  final int hash;

  /// Next entry in the same bucket collision chain, or `null` if at the end of the chain.
  HashNode<K, V>? next;

  /// Constructs a [HashNode] holding [key], [value], and cached [hash].
  HashNode({
    required this.key,
    required this.value,
    required this.hash,
    this.next,
  });

  @override
  String toString() => '$key: $value';
}

/// Alias for [HashNode] matching the naming convention in `docs/DSA_DESIGN.md`.
typedef HashMapEntry<K, V> = HashNode<K, V>;
