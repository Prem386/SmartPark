import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/graph/graph.dart';

void main() {
  group('WeightedGraph - Vertex Operations', () {
    late WeightedGraph graph;

    setUp(() {
      graph = WeightedGraph();
    });

    test('new graph is empty with zero vertices and edges', () {
      expect(graph.isEmpty, isTrue);
      expect(graph.isNotEmpty, isFalse);
      expect(graph.vertexCount, equals(0));
      expect(graph.edgeCount, equals(0));
      expect(graph.directedEdgeCount, equals(0));
      expect(graph.undirectedEdgeCount, equals(0));
      expect(graph.vertices, isEmpty);
      expect(graph.vertexIds, isEmpty);
    });

    test('addVertex successfully inserts vertices and updates counts', () {
      final nodeA = GraphNode(
        id: 'A',
        type: GraphNodeType.entrance,
        label: 'Node A',
        x: 1.0,
        y: 2.0,
        floor: 1,
      );
      final nodeB = GraphNode(
        id: 'B',
        type: GraphNodeType.aisleWaypoint,
        label: 'Node B',
      );

      graph.addVertex(nodeA);
      expect(graph.vertexCount, equals(1));
      expect(graph.isEmpty, isFalse);
      expect(graph.isNotEmpty, isTrue);
      expect(graph.containsVertex('A'), isTrue);
      expect(graph.containsVertex('B'), isFalse);
      expect(graph.getVertex('A'), equals(nodeA));

      graph.addNode(nodeB);
      expect(graph.vertexCount, equals(2));
      expect(graph.containsVertex('B'), isTrue);
      expect(graph.getVertex('B'), equals(nodeB));
    });

    test('addVertex rejects duplicate vertex IDs with ArgumentError', () {
      final node1 = GraphNode(id: 'A', type: GraphNodeType.entrance);
      final node2 = GraphNode(id: 'A', type: GraphNodeType.parkingSlot);

      graph.addVertex(node1);
      expect(() => graph.addVertex(node2), throwsArgumentError);
      expect(graph.vertexCount, equals(1));
    });

    test('removeVertex removes vertex and incident edges', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 5.0);
      graph.addUndirectedEdge('B', 'C', 10.0);

      expect(graph.vertexCount, equals(3));
      expect(graph.edgeCount, equals(2));
      expect(graph.directedEdgeCount, equals(4));

      final removed = graph.removeVertex('B');
      expect(removed, isTrue);
      expect(graph.vertexCount, equals(2));
      expect(graph.containsVertex('B'), isFalse);
      expect(graph.getVertex('B'), isNull);
      expect(graph.getAdjacentEdges('A'), isEmpty);
      expect(graph.getAdjacentEdges('C'), isEmpty);
      expect(graph.directedEdgeCount, equals(0));
      expect(graph.edgeCount, equals(0));

      // Removing already non-existent vertex returns false
      expect(graph.removeVertex('B'), isFalse);
    });

    test('clear removes all vertices and edges', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.parkingSlot));
      graph.addUndirectedEdge('A', 'B', 3.0);

      expect(graph.vertexCount, equals(2));
      expect(graph.edgeCount, equals(1));

      graph.clear();
      expect(graph.isEmpty, isTrue);
      expect(graph.vertexCount, equals(0));
      expect(graph.edgeCount, equals(0));
      expect(graph.directedEdgeCount, equals(0));
    });
  });

  group('WeightedGraph - Edge Operations & Validation', () {
    late WeightedGraph graph;

    setUp(() {
      graph = WeightedGraph();
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.parkingSlot));
    });

    test('addUndirectedEdge creates bidirectional edges with equal weight', () {
      graph.addUndirectedEdge('A', 'B', 4.5);

      expect(graph.edgeCount, equals(1));
      expect(graph.undirectedEdgeCount, equals(1));
      expect(graph.directedEdgeCount, equals(2));
      expect(graph.hasEdge('A', 'B'), isTrue);
      expect(graph.hasEdge('B', 'A'), isTrue);

      final edgesA = graph.getAdjacentEdges('A');
      expect(edgesA.length, equals(1));
      expect(edgesA.first.sourceNodeId, equals('A'));
      expect(edgesA.first.targetNodeId, equals('B'));
      expect(edgesA.first.weight, equals(4.5));

      final edgesB = graph.getAdjacentEdges('B');
      expect(edgesB.length, equals(1));
      expect(edgesB.first.sourceNodeId, equals('B'));
      expect(edgesB.first.targetNodeId, equals('A'));
      expect(edgesB.first.weight, equals(4.5));
    });

    test('addDirectedEdge creates one-way edge', () {
      graph.addDirectedEdge('A', 'B', 3.0);

      expect(graph.hasEdge('A', 'B'), isTrue);
      expect(graph.hasEdge('B', 'A'), isFalse);
      expect(graph.directedEdgeCount, equals(1));
      expect(graph.getAdjacentEdges('A').length, equals(1));
      expect(graph.getAdjacentEdges('B'), isEmpty);
    });

    test('addEdge helper respects isBidirectional flag', () {
      graph.addEdge('A', 'B', 2.0, isBidirectional: true);
      expect(graph.hasEdge('A', 'B'), isTrue);
      expect(graph.hasEdge('B', 'A'), isTrue);

      graph.addEdge('B', 'C', 1.0, isBidirectional: false);
      expect(graph.hasEdge('B', 'C'), isTrue);
      expect(graph.hasEdge('C', 'B'), isFalse);
    });

    test('rejects edges with unknown endpoints', () {
      expect(() => graph.addUndirectedEdge('A', 'NON_EXISTENT', 5.0), throwsArgumentError);
      expect(() => graph.addUndirectedEdge('NON_EXISTENT', 'B', 5.0), throwsArgumentError);
      expect(() => graph.addDirectedEdge('A', 'UNKNOWN', 5.0), throwsArgumentError);
    });

    test('rejects self-loops', () {
      expect(() => graph.addUndirectedEdge('A', 'A', 5.0), throwsArgumentError);
      expect(() => graph.addDirectedEdge('B', 'B', 5.0), throwsArgumentError);
      expect(
        () => GraphEdge(sourceNodeId: 'A', targetNodeId: 'A', weight: 1.0),
        throwsArgumentError,
      );
    });

    test('rejects negative, NaN, and infinite weights', () {
      expect(() => graph.addUndirectedEdge('A', 'B', -1.0), throwsArgumentError);
      expect(() => graph.addUndirectedEdge('A', 'B', double.nan), throwsArgumentError);
      expect(() => graph.addUndirectedEdge('A', 'B', double.infinity), throwsArgumentError);
      expect(() => graph.addUndirectedEdge('A', 'B', double.negativeInfinity), throwsArgumentError);

      expect(() => graph.addDirectedEdge('A', 'B', -0.5), throwsArgumentError);
      expect(() => graph.addDirectedEdge('A', 'B', double.nan), throwsArgumentError);
      expect(() => graph.addDirectedEdge('A', 'B', double.infinity), throwsArgumentError);
    });

    test('rejects duplicate edges between same vertices', () {
      graph.addUndirectedEdge('A', 'B', 4.0);
      expect(() => graph.addUndirectedEdge('A', 'B', 5.0), throwsArgumentError);
      expect(() => graph.addUndirectedEdge('B', 'A', 4.0), throwsArgumentError);
      expect(() => graph.addDirectedEdge('A', 'B', 2.0), throwsArgumentError);
    });

    test('removeEdge removes bidirectional and directed edges correctly', () {
      graph.addUndirectedEdge('A', 'B', 3.0);
      graph.addDirectedEdge('B', 'C', 2.0);

      expect(graph.removeEdge('A', 'B', isBidirectional: true), isTrue);
      expect(graph.hasEdge('A', 'B'), isFalse);
      expect(graph.hasEdge('B', 'A'), isFalse);

      expect(graph.removeEdge('B', 'C', isBidirectional: false), isTrue);
      expect(graph.hasEdge('B', 'C'), isFalse);

      // Removing non-existent edge
      expect(graph.removeEdge('A', 'C'), isFalse);
    });

    test('getAdjacentEdges returns unmodifiable collection', () {
      graph.addUndirectedEdge('A', 'B', 2.0);
      final edges = graph.getAdjacentEdges('A');
      expect(
        () => edges.add(GraphEdge(sourceNodeId: 'A', targetNodeId: 'C', weight: 1.0)),
        throwsUnsupportedError,
      );
    });

    test('getAdjacentEdges throws ArgumentError for unknown vertex', () {
      expect(() => graph.getAdjacentEdges('NON_EXISTENT'), throwsArgumentError);
    });

    test('validateConsistency passes on valid graph', () {
      graph.addUndirectedEdge('A', 'B', 2.0);
      graph.addUndirectedEdge('B', 'C', 3.0);
      expect(graph.validateConsistency(), isTrue);
    });
  });

  group('GraphNode and GraphEdge Value Objects', () {
    test('GraphNode validates input and checks equality', () {
      expect(
        () => GraphNode(id: '', type: GraphNodeType.entrance),
        throwsArgumentError,
      );
      expect(
        () => GraphNode(id: 'A', type: GraphNodeType.entrance, floor: 0),
        throwsArgumentError,
      );
      expect(
        () => GraphNode(id: 'A', type: GraphNodeType.entrance, x: double.nan),
        throwsArgumentError,
      );

      final node1 = GraphNode(id: 'N1', type: GraphNodeType.entrance, x: 2.0, y: 8.0);
      final node2 = GraphNode(id: 'N1', type: GraphNodeType.entrance, x: 2.0, y: 8.0);
      final node3 = GraphNode(id: 'N2', type: GraphNodeType.parkingSlot);

      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
      expect(node1, isNot(equals(node3)));
      expect(node1.toString(), contains('N1'));
    });

    test('GraphEdge validates input and checks equality', () {
      expect(
        () => GraphEdge(sourceNodeId: '', targetNodeId: 'B', weight: 1.0),
        throwsArgumentError,
      );
      expect(
        () => GraphEdge(sourceNodeId: 'A', targetNodeId: '', weight: 1.0),
        throwsArgumentError,
      );

      final edge1 = GraphEdge(sourceNodeId: 'A', targetNodeId: 'B', weight: 4.0);
      final edge2 = GraphEdge(sourceNodeId: 'A', targetNodeId: 'B', weight: 4.0);
      final edge3 = GraphEdge(sourceNodeId: 'A', targetNodeId: 'B', weight: 5.0);

      expect(edge1, equals(edge2));
      expect(edge1.hashCode, equals(edge2.hashCode));
      expect(edge1, isNot(equals(edge3)));
      expect(edge1.destinationNodeId, equals('B'));
      expect(edge1.toString(), contains('A -> B'));
    });
  });
}
