import '../dsa/hashmap/hash_map.dart';
import '../models/parking_slot.dart';

/// Application service managing in-memory parking slot lookup and registry.
///
/// Backed by [CustomHashMap] using separate chaining for $O(1)$ average-time lookup.
///
/// Physical parking bays are indexed by their [ParkingSlot.slotCode] (e.g. 'P01').
/// Note: [ParkingSlot.id] is the backend database record identifier, while [slotCode]
/// is the physical bay code. Lookup in this service is always keyed by [slotCode].
///
/// // ponytail: thin O(1) wrapper over CustomHashMap; no duplicate maps, no unneeded abstractions
class ParkingSlotService {
  final CustomHashMap<String, ParkingSlot> _registry;

  /// Creates a [ParkingSlotService] optionally populated with [initialSlots].
  ParkingSlotService([Iterable<ParkingSlot>? initialSlots])
      : _registry = CustomHashMap<String, ParkingSlot>() {
    if (initialSlots != null) {
      for (final slot in initialSlots) {
        registerSlot(slot);
      }
    }
  }

  /// Registers a new [slot] in the registry.
  ///
  /// Throws [ArgumentError] if a slot with the same [slot.slotCode] is already registered.
  void registerSlot(ParkingSlot slot) {
    final code = _normalizeCode(slot.slotCode);
    if (_registry.containsKey(code)) {
      throw ArgumentError(
        'Parking slot with code "$code" is already registered.',
      );
    }
    _registry.put(code, slot);
  }

  /// Updates an existing [slot] in the registry.
  ///
  /// Throws [ArgumentError] if no slot with [slot.slotCode] is currently registered.
  void updateSlot(ParkingSlot slot) {
    final code = _normalizeCode(slot.slotCode);
    if (!_registry.containsKey(code)) {
      throw ArgumentError(
        'Cannot update unregistered slot with code "$code".',
      );
    }
    _registry.put(code, slot);
  }

  /// Registers [slot] if absent, or overwrites it if already registered.
  void registerOrUpdate(ParkingSlot slot) {
    final code = _normalizeCode(slot.slotCode);
    _registry.put(code, slot);
  }

  /// Retrieves a parking slot by its physical [slotCode], or `null` if not found.
  ParkingSlot? getSlot(String slotCode) {
    return _registry.get(_normalizeCode(slotCode));
  }

  /// Checks whether a slot with [slotCode] exists in the registry.
  bool hasSlot(String slotCode) {
    return _registry.containsKey(_normalizeCode(slotCode));
  }

  /// Removes a slot by its [slotCode] from the registry.
  ///
  /// Returns the removed [ParkingSlot], or `null` if it was not found.
  ParkingSlot? removeSlot(String slotCode) {
    return _registry.remove(_normalizeCode(slotCode));
  }

  /// Returns a snapshot list of all registered parking slots.
  List<ParkingSlot> getAllSlots() {
    return _registry.values.toList();
  }

  /// Total number of registered slots.
  int get slotCount => _registry.size;

  /// Whether the registry is empty.
  bool get isEmpty => _registry.isEmpty;

  /// Whether the registry contains at least one slot.
  bool get isNotEmpty => _registry.isNotEmpty;

  /// Clears all slots from the registry.
  void clear() {
    _registry.clear();
  }

  static String _normalizeCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(code, 'slotCode', 'Slot code cannot be empty.');
    }
    return trimmed.toUpperCase();
  }
}

