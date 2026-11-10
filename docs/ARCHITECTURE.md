# SmartPark – System Architecture Specification

> **Document Status**: Proposed Architecture (Phase 1: Architecture Foundation)  
> **Target Audience**: Academic Reviewers, System Designers, Developers  
> **Revision**: 1.0.0

---

## 1. Overall Client-Server Architecture

SmartPark follows a decoupled, multi-tier client-server architecture designed for an academic Intelligent Parking Management System. The architecture cleanly isolates user interaction, client-side algorithmic processing, authoritative backend business logic, and persistent storage.

```
+-----------------------------------------------------------------------+
|                           CLIENT TIER                                 |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |                 Flutter Mobile App (Dart)                       |  |
|  |  +---------------------+  +----------------------------------+  |  |
|  |  |   UI / Presentation |  |      Application Services        |  |  |
|  |  |  (Screens, Widgets) |  | (SlotService, NavigationService) |  |  |
|  |  +----------+----------+  +-----------------+----------------+  |  |
|  |             |                               |                   |  |
|  |             v                               v                   |  |
|  |  +-----------------------------------------------------------+  |  |
|  |  |              Algorithmic Core (Custom Dart DSA)           |  |  |
|  |  |  * Custom HashMap        * Custom Min-Heap                |  |  |
|  |  |  * Custom Interval Tree  * Graph + Dijkstra               |  |  |
|  |  +-----------------------------------------------------------+  |  |
|  |                                 |                               |  |
|  |                                 v                               |  |
|  |  +-----------------------------------------------------------+  |  |
|  |  |         API Client Layer (HTTP / REST / DTOs)             |  |  |
|  |  +------------------------------+----------------------------+  |  |
|  +---------------------------------|-------------------------------+  |
+------------------------------------|----------------------------------+
                                     |
                                     | HTTPS / REST (JSON)
                                     v
+-----------------------------------------------------------------------+
|                           SERVER TIER                                 |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |             Spring Boot Application (Java)                      |  |
|  |  +-----------------------------------------------------------+  |  |
|  |  |      REST Controllers (/api/slots, /api/bookings, etc.)   |  |  |
|  |  +------------------------------+----------------------------+  |  |
|  |                                 v                               |  |
|  |  +-----------------------------------------------------------+  |  |
|  |  |       Service Layer (Validation & Business Logic)         |  |  |
|  |  |      * Authoritative Reservation Conflict Validation      |  |  |
|  |  |      * Transaction Management & Concurrency Control       |  |  |
|  |  +------------------------------+----------------------------+  |  |
|  |                                 v                               |  |
|  |  +-----------------------------------------------------------+  |  |
|  |  |        Data Access Layer (Repositories / ORM)             |  |  |
|  |  +------------------------------+----------------------------+  |  |
|  +---------------------------------|-------------------------------+  |
+------------------------------------|----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                          DATABASE TIER                                |
|                                                                       |
|    Persistent Storage (Authoritative Source of Truth)                 |
|    * Users, ParkingSlots, Bookings, NavigationNodes, NavigationEdges  |
+-----------------------------------------------------------------------+
```

---

## 2. Component Responsibilities

### 2.1 Flutter (Mobile Client) Responsibilities
- **Presentation & Interaction**: Render parking bay maps, slot availability statuses, reservation pickers, and turn-by-turn navigation paths.
- **Client Session Management**: Store user session tokens, local preferences, and active booking identifiers.
- **Local State Coordination**: Mediate data flow between API client responses, custom DSA instances, and UI widgets without tight coupling.
- **Instantaneous Feedback**: Utilize client-side DSA instances to provide zero-latency search, conflict warnings, and path previews before network round-trips.

### 2.2 Dart DSA Core Responsibilities
All four algorithmic structures must be implemented manually in pure Dart without relying on built-in collection replacements (such as Dart's standard `Map` or package-based heaps):
1. **Custom HashMap**:
   - Provide $O(1)$ average-time lookup, insertion, and retrieval of parking slot states by slot ID or slot number.
   - Maintain an indexed in-memory cache of currently loaded parking slots.
2. **Custom Min-Heap**:
   - Priority queue used for intelligent slot recommendations (ranking slots by composite cost/distance metric).
   - Reusable priority queue powering Dijkstra's algorithm for shortest-path node selection.
3. **Custom Interval Tree**:
   - Augment binary search tree structure to store existing reservation time intervals `[start, end]`.
   - Provide $O(\log n)$ average-time conflict detection on the client side to give immediate user warnings during booking time selection.
4. **Graph + Dijkstra's Algorithm**:
   - Model the parking facility (entry gates, aisles, parking spots, stairs, elevators) as a weighted graph.
   - Compute the shortest obstacle-free path from the selected entrance/current position to the designated parking slot.

### 2.3 Spring Boot (Backend) Responsibilities
- **Authoritative Business Logic**: Act as the single source of truth for all business operations.
- **Server-Side Conflict Validation**: Independently validate booking requests against persisted database records to prevent double bookings, race conditions, and client tampering.
- **Transaction & Concurrency Management**: Handle concurrent reservation attempts using database locks or transactional isolation levels.
- **RESTful Endpoints**: Expose standardized JSON endpoints for slot queries, reservation workflows, and facility layout metadata.
- **Security & Authorization**: Validate user authentication credentials and permissions.

### 2.4 Database Responsibilities
- **Persistent Authoritative Record**: Maintain durable state across application restarts and server scaling.
- **Referential Integrity**: Guarantee foreign key integrity between Users, Bookings, ParkingSlots, and Navigation entities.
- **ACID Guarantees**: Prevent partial reservation commits and guarantee consistency under concurrent slot booking operations.

---

## 3. Frontend-Backend Communication

### 3.1 Protocol and Data Exchange
- **Protocol**: HTTP/1.1 or HTTP/2 over TLS (HTTPS).
- **Format**: JSON payloads for all requests and responses.
- **Statelessness**: REST principles apply; each client request contains necessary authentication tokens and parameters.

### 3.2 Decoupling Principles
- **Separation of Concerns**: API communication is completely isolated in `lib/services/api/` (or dedicated client classes).
- **Data Transfer Objects (DTOs)**: Raw JSON maps are deserialized into typed model instances inside `lib/models/`. Application services and DSA data structures consume domain models, never raw JSON maps.
- **Optimistic Validation vs. Authoritative Settlement**:
  - The Flutter client runs local DSA checks (e.g., Interval Tree conflict query) for instant UI feedback.
  - The final reservation request is transmitted to Spring Boot via `POST /api/bookings`.
  - Spring Boot executes authoritative database checks. Only when the backend returns `201 Created` is the booking treated as confirmed. If a conflict occurs on the backend, a `409 Conflict` response instructs Flutter to reconcile its local state.

---

## 4. Proposed Directory Structure

```text
SmartPark/
├── .gitignore
├── README.md
├── docs/
│   ├── ARCHITECTURE.md          # Overall system architecture & data flow
│   ├── DSA_DESIGN.md            # In-depth algorithmic designs (4 custom DSAs)
│   ├── DATABASE_DESIGN.md       # Entity designs and data dictionary
│   └── API_DOCUMENTATION.md     # REST API contracts
│
├── frontend/                    # Flutter Mobile Application
│   ├── android/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart            # Flutter entry point
│   │   ├── models/              # Domain models and DTOs (Slot, Booking, User, Node, Edge)
│   │   ├── dsa/                 # Pure Dart algorithmic implementations (NO UI code)
│   │   │   ├── hashmap/         # Custom HashMap implementation & bucket nodes
│   │   │   ├── min_heap/        # Custom Min-Heap implementation (generic, reusable)
│   │   │   ├── interval_tree/   # Custom Interval Tree implementation for time intervals
│   │   │   └── graph/           # Graph representation & Dijkstra pathfinding
│   │   ├── services/            # Application logic, API client, local coordinators
│   │   ├── screens/             # UI screens (Home, Slot Picker, Booking, Navigation)
│   │   ├── widgets/             # Reusable UI presentation widgets
│   │   └── utils/               # Constants, formatters, logging helpers
│   │
│   └── test/                    # Automated Test Suite
│       ├── widget_test.dart     # Standard widget smoke test
│       └── dsa/                 # Dedicated unit tests for manual algorithms
│           ├── hashmap/         # HashMap collision, rehashing, CRUD tests
│           ├── min_heap/        # Min-Heap invariant, extractMin, sorting tests
│           ├── interval_tree/   # Interval overlap, insertion, edge-case tests
│           └── graph/           # Dijkstra shortest path, unreachable node tests
│
└── backend/                     # Future Spring Boot Application (Pending Initialization)
    ├── src/
    │   ├── main/
    │   │   ├── java/com/smartpark/
    │   │   │   ├── controllers/ # REST Controllers
    │   │   │   ├── services/    # Business services and validation
    │   │   │   ├── models/      # JPA / Database Entities
    │   │   │   └── repositories/# Spring Data Repositories
    │   │   └── resources/
    │   │       └── application.yml
    │   └── test/
    └── pom.xml / build.gradle
```

---

## 5. End-to-End Component Data Flow

### Flow 1: Slot Status Retrieval and Fast Lookup
1. User opens the application or selects a parking floor.
2. `SlotService` invokes `ApiClient.getSlots()`.
3. `ApiClient` issues `GET /api/slots` to Spring Boot.
4. Spring Boot queries the database, serializes `ParkingSlot` entities into JSON, and returns `200 OK`.
5. `SlotService` deserializes JSON into `List<ParkingSlot>`.
6. `SlotService` populates a client-side instance of `CustomHashMap<String, ParkingSlot>`.
7. UI components perform immediate $O(1)$ lookups by `slotId` or search query without incurring repeated list traversals or network calls.

### Flow 2: Intelligent Slot Recommendation
1. User requests an optimal parking slot recommendation (specifying preferences such as distance, handicap access, or EV charging).
2. `RecommendationService` gathers available slots from the `CustomHashMap`.
3. For each candidate slot, a dynamic priority score is computed:
   $$\text{Score} = w_{\text{dist}} \cdot \text{Distance} + w_{\text{cost}} \cdot \text{Cost} + \text{Penalty}$$
4. Each slot is inserted into the generic `CustomMinHeap<ScoredSlot>`.
5. The top $K$ optimal slots are extracted via `extractMin()` in $O(K \log N)$ time.
6. The UI displays the ranked recommendation list to the user.

### Flow 3: Conflict-Free Reservation Workflow
1. User selects a slot and specifies desired start and end times: $[t_{\text{start}}, t_{\text{end}}]$.
2. `BookingService` loads active bookings for that slot into a `CustomIntervalTree`.
3. `CustomIntervalTree.queryOverlap(start, end)` executes in $O(\log N)$ average time:
   - If an overlap is detected, the UI instantly alerts the user and prevents form submission.
   - If no local overlap is found, user confirms the booking.
4. `BookingService` dispatches `POST /api/bookings` with payload `{ slotId, startTime, endTime }`.
5. Spring Boot receives the request and opens a transactional boundary:
   - Server queries the database for overlapping bookings on the target slot.
   - If a conflict is discovered (e.g., concurrent reservation from another client), backend returns `409 Conflict`.
   - If valid, Spring Boot persists the booking, commits the transaction, and returns `201 Created`.
6. Flutter client receives `201 Created`, inserts the new interval into `CustomIntervalTree`, and renders confirmation.

### Flow 4: Shortest-Path Facility Navigation
1. User requests directions from a designated facility entrance to their allocated parking slot.
2. `NavigationService` retrieves the layout graph (cached locally or fetched via `GET /api/layout/graph`).
3. `NavigationService` builds a `Graph` instance comprised of `NavigationNode` and `NavigationEdge` objects.
4. `DijkstraAlgorithm` is executed from `sourceNodeId` to `destinationNodeId`:
   - It utilizes the reusable `CustomMinHeap` as its priority queue to continuously extract the unvisited node with minimum tentative distance.
5. Once the destination is settled, the predecessor links are backtracked to construct `NavigationPath`.
6. The sequence of node coordinates $(x_i, y_i)$ is passed to the UI for visual overlay on the parking floor plan.

---

## 6. Architecture Constraints and Rules

1. **Strict Separation of Concerns**: Algorithmic files in `lib/dsa/` must have zero dependencies on Flutter framework packages (`flutter/material.dart`, widgets, UI state). They must remain standalone, testable Dart code.
2. **API and Service Decoupling**: Flutter UI widgets must never invoke HTTP clients directly; all remote operations pass through service coordinators.
3. **No Algorithmic Shortcuts**: Native collections (`dart:collection`, `Map`, `SplayTreeMap`) cannot replace the four required manual DSA implementations.
4. **Backend Authority**: The frontend performs optimistic checks for responsive user experience, but the Spring Boot backend and its persistent database remain the absolute authority for state mutations.

