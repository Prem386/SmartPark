import '../hashmap/hash_map.dart';
import 'graph_edge.dart';
import 'graph_node.dart';

/// A weighted graph implementation using adjacency lists.
///
/// Built for the SmartPark academic parking management prototype (Phase 2.6).
///
/// Adjacency lists and vertex registries are stored internally using the custom
/// [CustomHashMap] developed in Phase 2.3.
///
/// // ponytail: adjacency list via CustomHashMap, explicit validation, defensive unmodifiable views
class WeightedGraph {
  final CustomHashMap<String, GraphNode> _vertices;
  final CustomHashMap<String, List<GraphEdge>> _adjacency;

  int _undirectedEdgeCount = 0;
  int _directedEdgeCount = 0;

  /// Creates an empty [WeightedGraph].
  WeightedGraph()
      : _vertices = CustomHashMap<String, GraphNode>(),
        _adjacency = CustomHashMap<String, List<GraphEdge>>();

  /// Total number of vertices in the graph.
  int get vertexCount => _vertices.size;

  /// Logical edge count.
  ///
  /// For undirected graphs, returns the number of bidirectional connections.
  /// If directed edges are added without reverse counterparts, returns total unique links.
  int get edgeCount => _undirectedEdgeCount;

  /// Total number of undirected (bidirectional) edges.
  int get undirectedEdgeCount => _undirectedEdgeCount;

  /// Total number of directed adjacency entries across all vertices.
  int get directedEdgeCount => _directedEdgeCount;

  /// Whether the graph has zero vertices.
  bool get isEmpty => _vertices.isEmpty;

  /// Whether the graph has at least one vertex.
  bool get isNotEmpty => _vertices.isNotEmpty;

  /// Returns an iterable over all registered [GraphNode] instances.
  Iterable<GraphNode> get vertices => _vertices.values;

  /// Returns an iterable over all registered vertex IDs.
  Iterable<String> get vertexIds => _vertices.keys;

  /// Adds a new [vertex] to the graph.
  ///
  /// Throws [ArgumentError] if a vertex with the same ID already exists.
  void addVertex(GraphNode vertex) {
    if (_vertices.containsKey(vertex.id)) {
      throw ArgumentError.value(
        vertex.id,
        'vertex.id',
        'A vertex with ID "${vertex.id}" already exists in the graph.',
      );
    }
    _vertices.put(vertex.id, vertex);
    _adjacency.put(vertex.id, <GraphEdge>[]);
  }

  /// Alias for [addVertex].
  void addNode(GraphNode node) => addVertex(node);

  /// Checks whether a vertex with [id] exists in the graph.
  bool containsVertex(String id) => _vertices.containsKey(id);

  /// Retrieves the [GraphNode] with [id], or `null` if not found.
  GraphNode? getVertex(String id) => _vertices.get(id);

  /// Alias for [getVertex].
  GraphNode? getNode(String id) => getVertex(id);

  /// Checks whether a directed edge from [sourceId] to [targetId] exists.
  bool hasEdge(String sourceId, String targetId) {
    final edges = _adjacency.get(sourceId);
    if (edges == null) {
      return false;
    }
    for (final edge in edges) {
      if (edge.targetNodeId == targetId) {
        return true;
      }
    }
    return false;
  }

  /// Adds an undirected (bidirectional) edge between [u] and [v] with [weight].
  ///
  /// Throws [ArgumentError] if:
  /// - [u] or [v] does not exist in the graph.
  /// - [u] == [v] (self-loop).
  /// - [weight] is negative or not finite.
  /// - An edge between [u] and [v] already exists in either direction.
  void addUndirectedEdge(String u, String v, double weight) {
    _validateEndpoints(u, v);
    _validateWeight(weight);

    if (hasEdge(u, v) || hasEdge(v, u)) {
      throw ArgumentError('An edge already exists between "$u" and "$v".');
    }

    final forwardEdge = GraphEdge(sourceNodeId: u, targetNodeId: v, weight: weight);
    final reverseEdge = GraphEdge(sourceNodeId: v, targetNodeId: u, weight: weight);

    _adjacency.get(u)!.add(forwardEdge);
    _adjacency.get(v)!.add(reverseEdge);

    _undirectedEdgeCount++;
    _directedEdgeCount += 2;
  }

  /// Adds a directed edge from [sourceId] to [targetId] with [weight].
  ///
  /// Throws [ArgumentError] if:
  /// - [sourceId] or [targetId] does not exist in the graph.
  /// - [sourceId] == [targetId] (self-loop).
  /// - [weight] is negative or not finite.
  /// - A directed edge from [sourceId] to [targetId] already exists.
  void addDirectedEdge(String sourceId, String targetId, double weight) {
    _validateEndpoints(sourceId, targetId);
    _validateWeight(weight);

    if (hasEdge(sourceId, targetId)) {
      throw ArgumentError(
        'A directed edge from "$sourceId" to "$targetId" already exists.',
      );
    }

    final edge = GraphEdge(
      sourceNodeId: sourceId,
      targetNodeId: targetId,
      weight: weight,
    );
    _adjacency.get(sourceId)!.add(edge);
    _directedEdgeCount++;
  }

  /// General edge addition method.
  ///
  /// When [isBidirectional] is true (default), adds an undirected edge.
  /// Otherwise, adds a directed edge from [u] to [v].
  void addEdge(String u, String v, double weight, {bool isBidirectional = true}) {
    if (isBidirectional) {
      addUndirectedEdge(u, v, weight);
    } else {
      addDirectedEdge(u, v, weight);
    }
  }

  /// Removes the undirected or directed edge between [u] and [v].
  ///
  /// If [isBidirectional] is true (default), removes both `u -> v` and `v -> u`.
  /// Returns `true` if any edge was removed, `false` otherwise.
  bool removeEdge(String u, String v, {bool isBidirectional = true}) {
    if (!_vertices.containsKey(u) || !_vertices.containsKey(v)) {
      return false;
    }

    bool removedAny = false;
    final forwardList = _adjacency.get(u);
    if (forwardList != null) {
      final initialLen = forwardList.length;
      forwardList.removeWhere((e) => e.targetNodeId == v);
      if (forwardList.length < initialLen) {
        _directedEdgeCount -= (initialLen - forwardList.length);
        removedAny = true;
      }
    }

    if (isBidirectional) {
      final reverseList = _adjacency.get(v);
      if (reverseList != null) {
        final initialLen = reverseList.length;
        reverseList.removeWhere((e) => e.targetNodeId == u);
        if (reverseList.length < initialLen) {
          _directedEdgeCount -= (initialLen - reverseList.length);
          removedAny = true;
        }
      }
      if (removedAny) {
        _undirectedEdgeCount = (_undirectedEdgeCount > 0) ? _undirectedEdgeCount - 1 : 0;
      }
    }

    return removedAny;
  }

  /// Removes a vertex [id] and all its incoming and outgoing edges.
  ///
  /// Returns `true` if the vertex was removed, `false` if it did not exist.
  bool removeVertex(String id) {
    if (!_vertices.containsKey(id)) {
      return false;
    }

    // 1. Remove all outgoing edges from this vertex
    final outgoing = _adjacency.get(id);
    if (outgoing != null) {
      _directedEdgeCount -= outgoing.length;
    }
    _adjacency.remove(id);

    // 2. Remove all incoming edges targeting this vertex from other vertices
    for (final otherId in _vertices.keys) {
      if (otherId == id) continue;
      final edges = _adjacency.get(otherId);
      if (edges != null) {
        final initialLen = edges.length;
        edges.removeWhere((e) => e.targetNodeId == id);
        _directedEdgeCount -= (initialLen - edges.length);
      }
    }

    // 3. Remove vertex from registry
    _vertices.remove(id);

    // 4. Recalculate undirected edge count
    _recalculateUndirectedEdgeCount();

    return true;
  }

  /// Returns an unmodifiable list of outgoing [GraphEdge]s adjacent to [vertexId].
  ///
  /// Throws [ArgumentError] if [vertexId] is not present in the graph.
  List<GraphEdge> getAdjacentEdges(String vertexId) {
    final edges = _adjacency.get(vertexId);
    if (edges == null) {
      throw ArgumentError.value(
        vertexId,
        'vertexId',
        'Vertex "$vertexId" does not exist in the graph.',
      );
    }
    return List.unmodifiable(edges);
  }

  /// Alias for [getAdjacentEdges].
  List<GraphEdge> getNeighbors(String vertexId) => getAdjacentEdges(vertexId);

  /// Removes all vertices and edges from the graph.
  void clear() {
    _vertices.clear();
    _adjacency.clear();
    _undirectedEdgeCount = 0;
    _directedEdgeCount = 0;
  }

  /// Validates graph internal structural consistency.
  ///
  /// Checks:
  /// 1. Every vertex has an initialized adjacency list.
  /// 2. Every edge references valid endpoints.
  /// 3. No edge is a self-loop.
  /// 4. Every edge weight is finite and non-negative.
  /// 5. No duplicate edges exist in any adjacency list.
  ///
  /// Returns `true` if consistent, throws [StateError] on violation.
  bool validateConsistency() {
    for (final vertexId in _vertices.keys) {
      final edges = _adjacency.get(vertexId);
      if (edges == null) {
        throw StateError('Vertex "$vertexId" has no initialized adjacency list.');
      }

      final seenTargets = <String>{};
      for (final edge in edges) {
        if (edge.sourceNodeId != vertexId) {
          throw StateError(
            'Edge source "${edge.sourceNodeId}" mismatch with vertex "$vertexId".',
          );
        }
        if (!_vertices.containsKey(edge.targetNodeId)) {
          throw StateError(
            'Edge from "$vertexId" references unknown target "${edge.targetNodeId}".',
          );
        }
        if (edge.targetNodeId == vertexId) {
          throw StateError('Self-loop detected at vertex "$vertexId".');
        }
        if (edge.weight < 0 || !edge.weight.isFinite) {
          throw StateError(
            'Invalid edge weight ${edge.weight} on edge "$vertexId" -> "${edge.targetNodeId}".',
          );
        }
        if (!seenTargets.add(edge.targetNodeId)) {
          throw StateError(
            'Duplicate edge detected from "$vertexId" to "${edge.targetNodeId}".',
          );
        }
      }
    }
    return true;
  }

  void _validateEndpoints(String u, String v) {
    if (u.trim().isEmpty) {
      throw ArgumentError.value(u, 'u', 'Endpoint ID cannot be empty.');
    }
    if (v.trim().isEmpty) {
      throw ArgumentError.value(v, 'v', 'Endpoint ID cannot be empty.');
    }
    if (u == v) {
      throw ArgumentError('Self-loops are not permitted: $u -> $v.');
    }
    if (!_vertices.containsKey(u)) {
      throw ArgumentError('Source vertex "$u" does not exist in the graph.');
    }
    if (!_vertices.containsKey(v)) {
      throw ArgumentError('Target vertex "$v" does not exist in the graph.');
    }
  }

  void _validateWeight(double weight) {
    if (weight < 0 || !weight.isFinite) {
      throw ArgumentError.value(
        weight,
        'weight',
        'Edge weight must be a non-negative finite number.',
      );
    }
  }

  void _recalculateUndirectedEdgeCount() {
    int count = 0;
    for (final u in _vertices.keys) {
      final edges = _adjacency.get(u);
      if (edges == null) continue;
      for (final edge in edges) {
        final v = edge.targetNodeId;
        // Count pair once where u < v and reverse edge exists
        if (u.compareTo(v) < 0 && hasEdge(v, u)) {
          count++;
        }
      }
    }
    _undirectedEdgeCount = count;
  }
}

