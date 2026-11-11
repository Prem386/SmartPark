# SmartPark – Data Structures & Algorithms Specification

> **Document Status**: Proposed Design (Pending Implementation in Phase 2)  
> **Target Scope**: Four Manual Dart DSA Implementations for Student-Level Academic Demonstration  
> **Status Tagging**: All algorithms described herein are **PROPOSED DESIGNS** and subject to refinement prior to coding.

---

## 1. Algorithmic Overview & Architectural Boundaries

SmartPark demonstrates how foundational computer science data structures and algorithms solve concrete challenges in smart parking systems:
1. **Custom HashMap**: Direct key-based indexing for instantaneous slot lookups ($O(1)$ average).
2. **Custom Min-Heap**: Priority queue for ranking slot recommendations and powering Dijkstra's algorithm.
3. **Custom Interval Tree**: Augmented balanced search tree for detecting overlapping booking time intervals ($O(\log n)$ average).
4. **Graph + Dijkstra's Algorithm**: Weighted graph traversal computing shortest driving or walking paths to allocated spots.

### Boundary Rules
- **Pure Dart**: Algorithmic classes in `lib/dsa/` must not import `package:flutter/...`.
- **No Native Shortcuts**: Dart's built-in `Map`, `Set`, `SplayTreeMap`, or external heap packages are strictly forbidden as substitutes for the core manual structures.
- **Student-Level Clarity**: Implementations prioritize readability, mathematical correctness, edge-case resilience, and standard algorithmic textbook conventions.

---

## 2. Algorithm 1: Custom HashMap (Parking Slot Searching)

### 2.1 Purpose
The Custom HashMap provides an in-memory key-value associative store to index `ParkingSlot` objects by unique identifiers (e.g., `slotId` such as `"A-101"`, `"B-204"`, or vehicle registration numbers). It allows constant-time $O(1)$ average search, insertion, and deletion operations, avoiding linear $O(n)$ array scans whenever a user or system component queries slot status.

### 2.2 Data Representation
The proposed design uses **Separate Chaining** for collision resolution:
- **`HashMapEntry<K, V>`**:
  - `final K key`: The search key.
  - `V value`: The associated payload.
  - `final int hash`: Cached 32-bit hash value for fast comparisons.
  - `HashMapEntry<K, V>? next`: Reference to next entry in the same bucket collision chain.
- **`CustomHashMap<K, V>`**:
  - `List<HashMapEntry<K, V>?> _buckets`: Fixed-size array of bucket heads.
  - `int _size`: Total number of active key-value pairs.
  - `int _capacity`: Current number of buckets (initial default: 16).
  - `final double _loadFactor`: Threshold triggering resize and rehash (default: 0.75).

### 2.3 Main Operations
- `void put(K key, V value)`:
  1. Computes index: `int bucketIndex = (key.hashCode & 0x7FFFFFFF) % _capacity`.
  2. Traverses bucket chain at `bucketIndex`. If key already exists (via `==`), updates value and returns.
  3. If key does not exist, appends or prepends a new `HashMapEntry`.
  4. Increments `_size`. If `_size / _capacity >= _loadFactor`, invokes `_rehash()`.
- `V? get(K key)`:
  1. Computes bucket index.
  2. Traverses linked chain, comparing `hash` and `key == existingKey`.
  3. Returns `value` if found; otherwise `null`.
- `V? remove(K key)`:
  1. Locates bucket index.
  2. Unlinks target node from the bucket list.
  3. Decrements `_size` and returns removed value; returns `null` if not found.
- `bool containsKey(K key)`: Checks if a non-null entry matches `key`.
- `void _rehash()`:
  1. Doubles bucket capacity: `_capacity = _capacity * 2`.
  2. Allocates new empty bucket list.
  3. Recomputes bucket indices for all existing entries and moves nodes to the new array.
- `int get size`: Returns active count.
- `bool get isEmpty`: Returns `_size == 0`.

### 2.4 Expected Inputs and Outputs
- `put("A-101", ParkingSlot(...))` $\rightarrow$ Inserts/updates slot. Output: `void`.
- `get("A-101")` $\rightarrow$ Input: `String`. Output: `ParkingSlot?` (or `null` if unmapped).
- `remove("A-101")` $\rightarrow$ Input: `String`. Output: `ParkingSlot?` (the removed instance).

### 2.5 Application Integration
- Located in `frontend/lib/dsa/hashmap/`.
- Consumed by `SlotService` to cache remote slot lists received from `GET /api/slots`.
- Enables instantaneous search bar lookups and slot selection in the parking lot map widget without network latency.

### 2.6 Expected Time and Space Complexity
| Operation | Average Case | Worst Case (Severe Collisions) |
| :--- | :--- | :--- |
| **Search (`get`)** | $O(1)$ | $O(n)$ |
| **Insert (`put`)** | $O(1)$ amortized | $O(n)$ during rehash |
| **Delete (`remove`)** | $O(1)$ | $O(n)$ |
| **Space Complexity** | $O(n + m)$ ($n$ entries, $m$ buckets) | $O(n + m)$ |

### 2.7 Testing Requirements (`test/dsa/hashmap/`)
- Empty map lookup returns `null`.
- Single key-value insertion, verification, and update with identical key.
- Hash collision test: Keys engineered to produce identical bucket indices reside in the same bucket chain and are retrievable independently.
- Rehash trigger test: Insert elements exceeding `_loadFactor * _capacity` and assert size, capacity doubling, and full data retention.
- Deletion tests: Remove head node, middle node, tail node in a collision chain, and non-existent key.

---

## 3. Algorithm 2: Custom Min-Heap (Slot Recommendation & Priority Queue)

### 3.1 Purpose
The Custom Min-Heap maintains the minimum-heap invariant to efficiently extract items with minimum priority values. In SmartPark, it serves a dual role:
1. **Parking Slot Recommendations**: Sorts and surfaces optimal parking slots based on a composite cost/distance metric.
2. **Dijkstra Priority Queue**: Acts as the underlying priority queue for unvisited graph node relaxation during shortest-path computation.

### 3.2 Data Representation
A 0-indexed binary heap backed by a dynamic array (`List<T>`):
- **`CustomMinHeap<T>`**:
  - `List<T> _elements`: Contiguous array holding heap elements.
  - `final int Function(T a, T b) _comparator`: Comparison function returning negative if $a < b$, 0 if $a == b$, positive if $a > b$.
- **Indexing Formulas (0-indexed)**:
  - Parent index of $i$: `parent(i) = (i - 1) ~/ 2`
  - Left child of $i$: `leftChild(i) = 2 * i + 1`
  - Right child of $i$: `rightChild(i) = 2 * i + 2`

### 3.3 Main Operations
- `void insert(T item)`:
  1. Appends `item` to end of `_elements`.
  2. Calls `_heapifyUp(_elements.length - 1)`.
- `T? extractMin()`:
  1. If empty, returns `null` (or throws `StateError`).
  2. Root element (`_elements[0]`) is the minimum item.
  3. Moves last element of `_elements` to index 0, removes last element.
  4. Calls `_heapifyDown(0)` to restore min-heap invariant.
  5. Returns extracted root.
- `T? peek()`: Returns `_elements[0]` without removing it, or `null` if empty.
- `void _heapifyUp(int index)`:
  - While `index > 0` and `_comparator(_elements[index], _elements[parent(index)]) < 0`:
    - Swaps `_elements[index]` with parent.
    - Updates `index = parent(index)`.
- `void _heapifyDown(int index)`:
  - Repeatedly finds smallest between `index`, `leftChild`, and `rightChild`.
  - If smallest is not `index`, swaps `_elements[index]` with smallest child and continues down.
- `int get size`: Returns `_elements.length`.
- `bool get isEmpty`: Returns `_elements.isEmpty`.

### 3.4 Expected Inputs and Outputs
- `insert(ScoredSlot(slot: A1, score: 12.4))` $\rightarrow$ Adds to heap. Output: `void`.
- `extractMin()` $\rightarrow$ Output: `ScoredSlot` with the lowest score.
- For Dijkstra: `insert(DijkstraNode(nodeId: "N1", distance: 5.0))` $\rightarrow$ Extracts lowest distance node.

### 3.5 Application Integration
- Located in `frontend/lib/dsa/min_heap/`.
- Used by `RecommendationService` to produce the top-$K$ recommended slots for users.
- Reused by `Graph` pathfinder in `frontend/lib/dsa/graph/` to implement Dijkstra's algorithm.

### 3.6 Expected Time and Space Complexity
| Operation | Time Complexity | Auxiliary Space |
| :--- | :--- | :--- |
| **`insert`** | $O(\log n)$ | $O(1)$ |
| **`extractMin`** | $O(\log n)$ | $O(1)$ |
| **`peek`** | $O(1)$ | $O(1)$ |
| **`buildHeap` (heapify all)** | $O(n)$ | $O(1)$ |
| **Total Space** | $O(n)$ | Contiguous array |

### 3.7 Testing Requirements (`test/dsa/min_heap/`)
- Empty heap extraction and peek behavior.
- Invariant validation: Insert elements in descending order; verify `extractMin()` yields strictly ascending sorted sequence.
- Duplicate priority elements: Validate stability and correct min extraction.
- Stress test: Insert 500 items, verify min-heap property after each extraction.

---

## 4. Algorithm 3: Custom Interval Tree (Reservation Conflict Detection)

### 4.1 Purpose
The Custom Interval Tree stores time intervals representing reservations `[startTime, endTime]` for parking slots. It allows $O(\log n)$ query time to determine if a prospective reservation overlaps with any existing booking on that slot, preventing double bookings on the client before network submission.

### 4.2 Data Representation
An Augmented Binary Search Tree where each node represents a booking interval:
- **`Interval`**:
  - `final DateTime start`: Interval start timestamp.
  - `final DateTime end`: Interval end timestamp (invariant: `start < end`).
  - `final String bookingId`: Unique booking reference.
- **`IntervalTreeNode`**:
  - `Interval interval`: Stored interval.
  - `DateTime maxEnd`: The maximum `end` timestamp in the subtree rooted at this node.
  - `IntervalTreeNode? left`: Left subtree (intervals with `start < this.interval.start`).
  - `IntervalTreeNode? right`: Right subtree (intervals with `start >= this.interval.start`).
- **`CustomIntervalTree`**:
  - `IntervalTreeNode? _root`: Root of the tree.
  - `int _count`: Number of intervals stored.

### 4.3 Main Operations
- `void insert(Interval interval)`:
  1. Recursively inserts node as in standard BST ordered by `start`.
  2. On unwind, updates node's `maxEnd`:
     $$\text{node.maxEnd} = \max(\text{node.interval.end}, \text{node.left?.maxEnd}, \text{node.right?.maxEnd})$$
- `bool hasOverlap(Interval query)`: Returns `true` if any existing interval overlaps `query`.
  - Definition of overlap between $[s_1, e_1]$ and $[s_2, e_2]$:
    $$s_1 < e_2 \quad \text{and} \quad s_2 < e_1$$
- `Interval? searchFirstOverlap(Interval query)`:
  1. Starts at `_root`.
  2. If current node overlaps `query`, returns `current.interval`.
  3. If `left != null` and `left.maxEnd > query.start`:
     - Explores `left` subtree.
  4. Else:
     - Explores `right` subtree.
  5. Returns `null` if no intersection is found.
- `List<Interval> queryAllOverlaps(Interval query)`: Returns all intersecting bookings.
- `bool remove(String bookingId)`: Deletes an interval by ID and recalculates `maxEnd` along the search path.

### 4.4 Expected Inputs and Outputs
- `insert(Interval(10:00, 12:00, id: "B1"))` $\rightarrow$ Inserts interval into tree.
- `hasOverlap(Interval(11:30, 13:00))` $\rightarrow$ Input: Target interval. Output: `true` (conflicts with B1).
- `hasOverlap(Interval(12:00, 14:00))` $\rightarrow$ Input: Non-overlapping contiguous interval. Output: `false` (touching endpoints are permitted).

### 4.5 Application Integration
- Located in `frontend/lib/dsa/interval_tree/`.
- Managed inside `BookingService`.
- When a user views a parking slot and selects reservation hours, the frontend checks local reservations using `CustomIntervalTree`.
- Displays real-time warning indicators ("Selected slot has an active reservation during this window") before the user taps "Confirm Booking".

### 4.6 Expected Time and Space Complexity
| Operation | Average Case (Balanced BST) | Worst Case (Degenerate BST) |
| :--- | :--- | :--- |
| **`insert`** | $O(\log n)$ | $O(n)$ |
| **`searchOverlap`** | $O(\log n)$ | $O(n)$ |
| **`queryAllOverlaps`** | $O(k \log n)$ ($k$ matches) | $O(n)$ |
| **Space Complexity** | $O(n)$ | $O(n)$ |

> *Note on Balancing*: In this proposed student-level design, a standard augmented BST with recomputed `maxEnd` is specified. If unbalanced insertion causes performance degradation, AVL height-balancing rotation logic will be introduced.

### 4.7 Testing Requirements (`test/dsa/interval_tree/`)
- Empty tree query returns no overlap.
- Identical interval insertion and detection.
- Partially overlapping intervals (query starts before and ends inside; query starts inside and ends after).
- Enclosed intervals (query completely inside; query completely enclosing existing).
- Boundary edge case: Contiguous intervals where `query.start == existing.end` (must report NO conflict).
- Disjoint intervals before and after existing nodes.
- Multiple interval overlap collection.

---

## 5. Algorithm 4: Weighted Graph + Dijkstra (Shortest-Path Navigation)

### 5.1 Purpose
Models the spatial layout of the parking facility as an undirected/directed weighted graph. Uses Dijkstra's algorithm to compute the shortest driving and walking paths from an entrance node or current user position to an assigned parking bay node, providing turn-by-turn coordinate navigation and route distances for recommendation ranking.

### 5.2 Data Representation
An **Adjacency List** representation implemented from first principles:
- **`GraphNodeType` (Enum)**:
  - `entrance`: Facility vehicle/pedestrian access point.
  - `aisleWaypoint`: Central aisle decision and transit point.
  - `parkingSlot`: Physical parking bay destination.
- **`GraphNode`**:
  - `final String id`: Canonical vertex identifier (e.g., `'NODE_ENTRANCE'`, `'NODE_W01'`, `'NODE_P01'`).
  - `final GraphNodeType type`: Semantic role of the node.
  - `final String label`: Human-readable label (e.g., `'Main Entrance'`, `'Aisle Waypoint 1'`).
  - `final double? x`: Physical X coordinate in meters from West boundary.
  - `final double? y`: Physical Y coordinate in meters from South boundary.
  - `final int floor`: Facility floor level (defaults to 1).
- **`GraphEdge`**:
  - `final String sourceNodeId`: Origin vertex ID.
  - `final String targetNodeId`: Destination vertex ID (`destinationNodeId` alias).
  - `final double weight`: Physical travel distance in meters (invariant: non-negative and finite).
- **`WeightedGraph`**:
  - `final CustomHashMap<String, GraphNode> _vertices`: Vertex lookup table backed by Phase 2.3 `CustomHashMap`.
  - `final CustomHashMap<String, List<GraphEdge>> _adjacency`: Adjacency list storing outgoing edges for each vertex.
  - Tracks `vertexCount`, `edgeCount` (undirected), `undirectedEdgeCount`, and `directedEdgeCount`.
- **`DijkstraQueueEntry`**:
  - `final String vertexId`: Identifier of vertex awaiting settlement.
  - `final double tentativeDistance`: Current shortest tentative path distance from source.
  - Implements `Comparable<DijkstraQueueEntry>` to prioritize minimum tentative distance; ties broken deterministically by `vertexId`.
- **`DijkstraResult`**:
  - Immutable result capturing `source`, `destination`, `distance`, `path`, `hasPath`, `allDistances`, and `predecessors`.
  - Defensive unmodifiable views; returns `distance = null`, `hasPath = false`, and `path = []` for unreachable nodes.

### 5.3 Main Operations
- `void addVertex(GraphNode vertex)`:
  - Registers vertex in `_vertices` and initializes its empty edge list in `_adjacency`.
  - Rejects duplicate vertex IDs with `ArgumentError`.
- `void addUndirectedEdge(String u, String v, double weight)`:
  - Validates endpoints, non-negative finite weight, and absence of self-loops.
  - Inserts symmetric directed entries `u -> v` and `v -> u`.
  - Rejects existing duplicate edges.
- `void addDirectedEdge(String sourceId, String targetId, double weight)`:
  - Inserts single directed edge `sourceId -> targetId`.
- `bool removeVertex(String id)`:
  - Removes vertex, its outgoing edges, and all incoming edges from other vertices.
- `bool removeEdge(String u, String v, {bool isBidirectional = true})`:
  - Unlinks edge entries; decrements edge counters.
- `List<GraphEdge> getAdjacentEdges(String vertexId)`:
  - Returns `List.unmodifiable` view of edges leaving `vertexId`.
- `bool validateConsistency()`:
  - Verifies endpoint existence, weight non-negativity, absence of self-loops, and absence of duplicate edges.
- `DijkstraResult Dijkstra.findShortestPath(WeightedGraph graph, String source, String destination)`:
  1. Validates presence of `source` and `destination`.
  2. If `source == destination`, immediately returns distance `0.0` and path `[source]`.
  3. Initializes `distances[source] = 0.0`, `predecessors[source] = null`.
  4. Inserts `DijkstraQueueEntry(source, 0.0)` into `CustomMinHeap`.
  5. While heap is not empty:
     - Extracts minimum entry: `current = minHeap.extractMin()!`.
     - Skips stale entry if `current.tentativeDistance > distances[current.vertexId]`.
     - Early exit: If `current.vertexId == destination`, halts search.
     - For each outgoing edge `current -> neighbor`:
       - Calculates `altDistance = current.tentativeDistance + edge.weight`.
       - If `altDistance < (distances[neighbor] ?? infinity)`:
         - Updates `distances[neighbor] = altDistance`.
         - Records `predecessors[neighbor] = current.vertexId`.
         - Inserts new `DijkstraQueueEntry(neighbor, altDistance)` into `CustomMinHeap`.
  6. Reconstructs ordered path backwards from `destination` to `source` via `predecessors`.
  7. If destination was never reached, returns `DijkstraResult.unreachable(...)`.
- `DijkstraResult Dijkstra.computeAllShortestPaths(WeightedGraph graph, String source)`:
  - Relaxes all reachable vertices until the heap is empty, producing distance and predecessor maps to all reachable nodes.

### 5.4 SmartPark Facility Graph Integration
Constructed via `ParkingGraphFactory.createFacilityGraph()` per `docs/PARKING_FACILITY_DESIGN.md`:
- **Vertices ($|V| = 31$)**:
  - 1 Entrance: `NODE_ENTRANCE` at $(2.0, 8.0)$.
  - 10 Aisle Waypoints: `NODE_W01` to `NODE_W10` at $Y = 8.0\text{ m}$, $X = 6.0 + 3.0 \cdot (i - 1)\text{ m}$.
  - 20 Parking Slots:
    - Row A (North): `NODE_P01` to `NODE_P10` at $Y = 13.5\text{ m}$, $X = 6.0 + 3.0 \cdot (i - 1)\text{ m}$.
    - Row B (South): `NODE_P11` to `NODE_P20` at $Y = 2.5\text{ m}$, $X = 6.0 + 3.0 \cdot (i - 1)\text{ m}$.
- **Edges ($|E| = 30$ undirected / 60 directed entries)**:
  - 1 Entrance link: `NODE_ENTRANCE` $\leftrightarrow$ `NODE_W01` ($4.0\text{ m}$).
  - 9 Aisle backbone links: `NODE_W`$_i \leftrightarrow \text{NODE\_W}_{i+1}$ ($3.0\text{ m}$ each).
  - 10 Row A slot links: `NODE_W`$_i \leftrightarrow \text{NODE\_P}_i$ ($5.5\text{ m}$ each).
  - 10 Row B slot links: `NODE_W`$_i \leftrightarrow \text{NODE\_P}_{i+10}$ ($5.5\text{ m}$ each).
- **Closed-Form Distance Formula**:
  $$d(\text{NODE\_ENTRANCE}, P_k) = 4.0 + 3.0 \cdot (i - 1) + 5.5 = 9.5 + 3.0 \cdot (i - 1)\text{ meters} \quad \text{for } i \in [1, 10]$$
- **Candidate Ranking Integration**:
  - `ParkingGraphFactory.buildCandidates(...)` executes Dijkstra once from `NODE_ENTRANCE`, pairs each eligible `ParkingSlot` with its exact route distance, and emits `ParkingSlotCandidate` instances directly into `CustomMinHeap<ParkingSlotCandidate>`.

### 5.5 Expected Time and Space Complexity
| Operation / Metric | Time Complexity | Auxiliary Space | Description |
| :--- | :--- | :--- | :--- |
| **`addVertex`** | $O(1)$ amortized | $O(1)$ | Backed by `CustomHashMap` insertion |
| **`addUndirectedEdge`** | $O(1)$ amortized | $O(1)$ | Adjacency list append in both directions |
| **`getAdjacentEdges`** | $O(\text{deg}(v))$ | $O(\text{deg}(v))$ | Unmodifiable view of outgoing edges |
| **`containsVertex` / `getVertex`** | $O(1)$ average | $O(1)$ | Key lookup in `CustomHashMap` |
| **`removeVertex`** | $O(V + \text{deg}(v))$ | $O(1)$ | Cleans incident links and registry |
| **`removeEdge`** | $O(\text{deg}(u) + \text{deg}(v))$ | $O(1)$ | Scans adjacency lists of endpoints |
| **`validateConsistency`** | $O(V + E)$ | $O(V + E)$ | Complete graph invariant verification |
| **Dijkstra Shortest Path** | $O((V + E) \log V)$ | $O(V + E)$ | Priority queue with lazy duplicate entries |
| **Total Graph Storage** | — | $O(V + E)$ | $V$ vertices and $2E$ directed edge entries |

#### In-Depth Dijkstra Complexity Analysis
- **Lazy Duplicate Entries**: When an edge is relaxed to a smaller tentative distance, a new `DijkstraQueueEntry` is inserted into `CustomMinHeap`. Since vertices are not re-keyed in place, the heap may temporarily contain multiple entries for the same vertex.
- **Heap Insertions**: At most $1$ initial insertion + at most $E$ successful relaxations $\le E + 1$ total insertions. Each insertion takes $O(\log |Q|) \le O(\log (E + 1)) = O(\log V^2) = O(\log V)$ time.
- **Heap Extractions**: At most $E + 1$ total extractions. Exactly $V$ extractions finalize the true shortest distance (or fewer under destination early-exit); at most $E - V + 1$ extractions pop stale entries and are discarded in $O(1)$ after comparison with `distances[vertexId]`.
- **Edge Traversals**: Each outgoing edge is scanned only when its source vertex is settled, incurring $\sum_{v \in V} \text{outdeg}(v) = 2E$ traversals total.
- **Combined Time Bound**: $O(V \log V + E \log V) = \mathbf{O((V + E) \log V)}$.
- **Space Bound**: `distances` map stores $\le V$ entries, `predecessors` map stores $\le V$ entries, and the `CustomMinHeap` stores $\le E + 1$ entries, giving $\mathbf{O(V + E)}$ auxiliary space.

### 5.6 Testing Summary (`test/dsa/graph/`)
- **`weighted_graph_test.dart`**: Empty graph behavior, duplicate vertex rejection, bidirectional edge creation, one-way edges, unknown endpoint rejection, self-loop rejection, negative/infinite/NaN weight rejection, duplicate edge prevention, edge/vertex removal, unmodifiable collection views, consistency validation.
- **`dijkstra_test.dart`**: Line graphs, diamond topology branch selection, source equals destination, unreachable destinations, unknown endpoint errors, zero-weight transitions, cycles, stale queue entry suppression, equal-weight tie-breaking, all-destinations computation, immutability guards.
- **`parking_graph_factory_test.dart`**: Exactly 31 vertices, exactly 30 undirected edges, canonical vertex IDs, 3.0m aisle backbone, 5.5m slot connections, reachability of all 20 bays, closed-form distance verification, Verification 1 (P04: 18.5m) & Verification 2 (P08: 30.5m), closest bay (P11: 9.5m), furthest bay (P20: 36.5m), node ID mapping, and `CustomMinHeap<ParkingSlotCandidate>` recommendation queue integration.

---

## 6. Algorithmic Decisions Ledger

| Algorithm | Decision Status | Current Choice | Alternatives Considered | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **HashMap** | Implemented (Phase 2.3) | Separate Chaining with LinkedList buckets | Open Addressing (Linear Probing) | Separate chaining is simpler to implement and delete elements from in a student project without clustering artifacts. |
| **Min-Heap** | Implemented (Phase 2.4) | Contiguous Dynamic Array (0-indexed) | Pointer-based binary tree | Array-based binary heap offers $O(1)$ index calculations, zero pointer overhead, and cache locality. |
| **Interval Tree**| Implemented (Phase 2.5) | Augmented AVL-Balanced Tree (ordered by `start`, augmented with `maxEnd`) | Unbalanced BST / Segment Tree | AVL height-balancing guarantees $O(\log n)$ worst-case insertion, deletion, and overlap queries under chronological bookings. |
| **Graph + Dijkstra** | Implemented (Phase 2.6) | Adjacency List (CustomHashMap) + Dijkstra with CustomMinHeap | Adjacency Matrix / Bellman-Ford | Adjacency list is optimal for sparse spatial parking maps ($E \ll V^2$); non-negative distances favor Dijkstra over Bellman-Ford. CustomMinHeap integration reuses existing project DSA. |

