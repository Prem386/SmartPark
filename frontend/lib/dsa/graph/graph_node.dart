/// Semantic classification of facility graph vertices.
enum GraphNodeType {
  /// Facility vehicle/pedestrian access point.
  entrance,

  /// Driving aisle decision/transit point along aisle centerline.
  aisleWaypoint,

  /// Physical parking bay navigation target.
  parkingSlot,
}

/// Represents an immutable graph vertex in the navigation network.
///
/// // ponytail: immutable value object; coordinates and floor optional for general graphs
class GraphNode {
  /// Unique identifier of the node (e.g. 'NODE_ENTRANCE', 'NODE_W01', 'NODE_P01').
  final String id;

  /// Semantic role of the node within the parking facility.
  final GraphNodeType type;

  /// Human-readable label (e.g. 'Main Entrance', 'Aisle Waypoint 1').
  final String label;

  /// Spatial X coordinate in meters from facility origin (West boundary).
  final double? x;

  /// Spatial Y coordinate in meters from facility origin (South boundary).
  final double? y;

  /// Facility floor level (defaults to 1).
  final int floor;

  /// Creates a [GraphNode] vertex.
  GraphNode({
    required this.id,
    required this.type,
    String? label,
    this.x,
    this.y,
    this.floor = 1,
  }) : label = label ?? id {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Node ID cannot be empty.');
    }
    if (this.label.trim().isEmpty) {
      throw ArgumentError.value(this.label, 'label', 'Node label cannot be empty.');
    }
    if (floor <= 0) {
      throw ArgumentError.value(floor, 'floor', 'Floor level must be positive.');
    }
    if (x != null && !x!.isFinite) {
      throw ArgumentError.value(x, 'x', 'X coordinate must be finite.');
    }
    if (y != null && !y!.isFinite) {
      throw ArgumentError.value(y, 'y', 'Y coordinate must be finite.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          label == other.label &&
          x == other.x &&
          y == other.y &&
          floor == other.floor;

  @override
  int get hashCode => Object.hash(id, type, label, x, y, floor);

  @override
  String toString() => 'GraphNode($id, type: ${type.name}, floor: $floor)';
}

