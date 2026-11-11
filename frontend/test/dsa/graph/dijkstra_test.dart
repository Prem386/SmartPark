import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/graph/graph.dart';
import 'package:smartpark_app/dsa/min_heap/min_heap.dart';

void main() {
  group('Dijkstra Shortest Path Algorithm', () {
    late WeightedGraph graph;

    setUp(() {
      graph = WeightedGraph();
    });

    test('simple line graph finds correct shortest path and distance', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 4.0);
      graph.addUndirectedEdge('B', 'C', 5.5);

      final result = Dijkstra.findShortestPath(graph, 'A', 'C');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(9.5));
      expect(result.path, equals(['A', 'B', 'C']));
      expect(result.source, equals('A'));
      expect(result.destination, equals('C'));
    });

    test('chooses lower-cost path when multiple paths exist (diamond topology)', () {
      // Path 1: A -> B -> D (4 + 6 = 10)
      // Path 2: A -> C -> D (2 + 3 = 5)  <- should choose this
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'D', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 4.0);
      graph.addUndirectedEdge('B', 'D', 6.0);
      graph.addUndirectedEdge('A', 'C', 2.0);
      graph.addUndirectedEdge('C', 'D', 3.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'D');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(5.0));
      expect(result.path, equals(['A', 'C', 'D']));
    });

    test('source equals destination returns zero distance and single-element path', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addUndirectedEdge('A', 'B', 4.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'A');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(0.0));
      expect(result.path, equals(['A']));
      expect(result.allDistances['A'], equals(0.0));
    });

    test('unreachable destination returns hasPath false and null distance', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'ISOLATED', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 4.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'ISOLATED');

      expect(result.hasPath, isFalse);
      expect(result.distance, isNull);
      expect(result.path, isEmpty);
      expect(result.destination, equals('ISOLATED'));
      expect(result.toString(), contains('UNREACHABLE'));
    });

    test('throws ArgumentError for unknown source or destination', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.parkingSlot));
      graph.addUndirectedEdge('A', 'B', 4.0);

      expect(
        () => Dijkstra.findShortestPath(graph, 'UNKNOWN_SRC', 'B'),
        throwsArgumentError,
      );
      expect(
        () => Dijkstra.findShortestPath(graph, 'A', 'UNKNOWN_DEST'),
        throwsArgumentError,
      );
      expect(
        () => Dijkstra.computeAllShortestPaths(graph, 'UNKNOWN_SRC'),
        throwsArgumentError,
      );
    });

    test('handles zero-weight edges correctly', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 0.0);
      graph.addUndirectedEdge('B', 'C', 5.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'C');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(5.0));
      expect(result.path, equals(['A', 'B', 'C']));
    });

    test('handles graph with cycles without infinite looping', () {
      // Cycle: A - B - C - A
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'D', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 1.0);
      graph.addUndirectedEdge('B', 'C', 1.0);
      graph.addUndirectedEdge('C', 'A', 5.0); // Cycle edge
      graph.addUndirectedEdge('C', 'D', 2.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'D');

      expect(result.hasPath, isTrue);
      // Path: A -> B -> C -> D = 1 + 1 + 2 = 4 (better than A -> C -> D = 5 + 2 = 7)
      expect(result.distance, equals(4.0));
      expect(result.path, equals(['A', 'B', 'C', 'D']));
    });

    test('stale queue entry handling in lazy duplicate relaxation', () {
      // Node D gets pushed first with distance 10 via B, then relaxed to distance 3 via C
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'D', type: GraphNodeType.parkingSlot));
      graph.addVertex(GraphNode(id: 'E', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 10.0);
      graph.addUndirectedEdge('B', 'D', 1.0); // A->B->D = 11.0
      graph.addUndirectedEdge('A', 'C', 1.0);
      graph.addUndirectedEdge('C', 'D', 2.0); // A->C->D = 3.0 (replaces 11.0 in distances, but 11.0 remains stale in heap)
      graph.addUndirectedEdge('D', 'E', 4.0); // A->C->D->E = 7.0

      final result = Dijkstra.findShortestPath(graph, 'A', 'E');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(7.0));
      expect(result.path, equals(['A', 'C', 'D', 'E']));
    });

    test('multiple paths with equal weights use deterministic tie-breaking', () {
      // Path 1: A -> B -> D (3 + 3 = 6)
      // Path 2: A -> C -> D (3 + 3 = 6)
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'D', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 3.0);
      graph.addUndirectedEdge('A', 'C', 3.0);
      graph.addUndirectedEdge('B', 'D', 3.0);
      graph.addUndirectedEdge('C', 'D', 3.0);

      final result = Dijkstra.findShortestPath(graph, 'A', 'D');

      expect(result.hasPath, isTrue);
      expect(result.distance, equals(6.0));
      // DijkstraQueueEntry breaks ties by vertexId ('B' before 'C')
      expect(result.path, equals(['A', 'B', 'D']));
    });

    test('computeAllShortestPaths computes distances to all reachable vertices', () {
      graph.addVertex(GraphNode(id: 'A', type: GraphNodeType.entrance));
      graph.addVertex(GraphNode(id: 'B', type: GraphNodeType.aisleWaypoint));
      graph.addVertex(GraphNode(id: 'C', type: GraphNodeType.parkingSlot));
      graph.addVertex(GraphNode(id: 'UNREACHABLE', type: GraphNodeType.parkingSlot));

      graph.addUndirectedEdge('A', 'B', 2.0);
      graph.addUndirectedEdge('B', 'C', 3.5);

      final result = Dijkstra.computeAllShortestPaths(graph, 'A');

      expect(result.allDistances['A'], equals(0.0));
      expect(result.allDistances['B'], equals(2.0));
      expect(result.allDistances['C'], equals(5.5));
      expect(result.allDistances.containsKey('UNREACHABLE'), isFalse);

      expect(result.getPathTo('C'), equals(['A', 'B', 'C']));
      expect(result.getPathTo('UNREACHABLE'), isEmpty);
      expect(result.getDistanceTo('C'), equals(5.5));
      expect(result.getDistanceTo('UNREACHABLE'), isNull);
    });

    test('DijkstraQueueEntry priority ordering and equality', () {
      const e1 = DijkstraQueueEntry(vertexId: 'A', tentativeDistance: 5.0);
      const e2 = DijkstraQueueEntry(vertexId: 'B', tentativeDistance: 10.0);
      const e3 = DijkstraQueueEntry(vertexId: 'A', tentativeDistance: 5.0);
      const e4 = DijkstraQueueEntry(vertexId: 'B', tentativeDistance: 5.0);

      expect(e1.compareTo(e2), lessThan(0));
      expect(e2.compareTo(e1), greaterThan(0));
      // Tie breaker by vertexId: 'A' < 'B'
      expect(e1.compareTo(e4), lessThan(0));
      expect(e1, equals(e3));
      expect(e1.hashCode, equals(e3.hashCode));
      expect(e1.toString(), contains('tentative: 5.0m'));

      final heap = CustomMinHeap<DijkstraQueueEntry>();
      heap.insert(e2);
      heap.insert(e1);
      heap.insert(e4);

      expect(heap.extractMin(), equals(e1)); // dist 5.0, id 'A'
      expect(heap.extractMin(), equals(e4)); // dist 5.0, id 'B'
      expect(heap.extractMin(), equals(e2)); // dist 10.0, id 'B'
    });

    test('DijkstraResult immutability guards', () {
      final result = DijkstraResult.found(
        source: 'A',
        destination: 'B',
        distance: 4.0,
        path: ['A', 'B'],
        allDistances: {'A': 0.0, 'B': 4.0},
        predecessors: {'A': null, 'B': 'A'},
      );

      expect(() => result.path.add('C'), throwsUnsupportedError);
      expect(() => result.allDistances['C'] = 10.0, throwsUnsupportedError);
      expect(() => result.predecessors['C'] = 'B', throwsUnsupportedError);
      expect(result.toString(), contains('A -> B'));
    });
  });
}
