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

---

## 7. Application Service Layer & DSA Integration (Phase 2.7)

Phase 2.7 introduces a cohesive application service layer under `frontend/lib/services/` that orchestrates the four manual DSA structures into domain workflows.

### 7.1 Service Responsibilities

| Service | Primary DSA | Key Operations | Architectural Scope |
| :--- | :--- | :--- | :--- |
| **`ParkingSlotService`** | `CustomHashMap<String, ParkingSlot>` | `registerSlot`, `updateSlot`, `getSlot`, `removeSlot`, `getAllSlots` | In-memory slot registry indexed strictly by physical `slotCode` ($O(1)$ average). Distinct from backend record `id`. |
| **`BookingConflictService`** | `CustomIntervalTree` (Augmented AVL) | `addBooking`, `hasConflict`, `getConflictingBookings`, `removeBooking`, `rebuildIndex` | Real-time temporal conflict detection ($O(\log n)$ average) using half-open intervals `[start, end)`. Enforces status filtering. |
| **`ParkingNavigationService`** | `WeightedGraph` + `Dijkstra` | `getRouteToSlot`, `getRouteToSlotCode`, `findRoute`, `getDistancesToAllSlots` | Spatial graph navigation and turn-by-turn path reconstruction from entrance or arbitrary waypoints. |
| **`ParkingRecommendationService`** | `CustomMinHeap<ParkingSlotCandidate>` + `Dijkstra` | `getRecommendations(limit)`, `getTopRecommendation` | Multi-DSA coordination: filters available slots, computes route distances, builds min-heap, extracts top-$N$ nearest bays. |
| **`SmartParkDsaService`** | Unified Facade (All 4 DSAs) | `findSlot`, `findRouteToSlot`, `checkBookingConflict`, `bookSlot`, `getRecommendations` | Lightweight orchestrator coordinating services with zero framework dependencies. |

### 7.2 Service Dependencies

```text
SmartParkDsaService (Facade)
├── ParkingSlotService (CustomHashMap)
├── BookingConflictService (CustomIntervalTree)
├── ParkingNavigationService (WeightedGraph + Dijkstra)
└── ParkingRecommendationService (CustomMinHeap + Dijkstra)
    ├── depends on ParkingSlotService (slot availability)
    └── depends on ParkingNavigationService (route distance)
```

### 7.3 Domain Workflows

1. **Parking Recommendation Workflow**:
   - `ParkingSlotService.getAllSlots()` retrieves current slot states.
   - Filters eligible bays using model property `slot.isAvailable` (`isActive == true && status == SlotStatus.available`).
   - `ParkingNavigationService.computeAllDistances(entranceNodeId)` calculates exact driving distances via single Dijkstra pass.
   - Pairs eligible and reachable slots into `ParkingSlotCandidate` instances.
   - Inserts candidates into `CustomMinHeap<ParkingSlotCandidate>` via Floyd's $O(n)$ bottom-up heapification.
   - Extracts top-$N$ candidates via `extractMin()`, breaking equal-distance ties deterministically by `slotCode` alphabetical order.

2. **Booking Conflict Validation Workflow**:
   - New reservation request `[startTime, endTime)` on `slotId` is checked against `CustomIntervalTree`.
   - Adheres to half-open interval semantics `[s1, e1)` vs `[s2, e2)`: conflict exists iff $s_1 < e_2 \land s_2 < e_1$.
   - Adjacent bookings (e.g., 10:00-11:00 and 11:00-12:00) share an endpoint and do NOT conflict.
   - **Status Filtering**: Only `CONFIRMED` and `ACTIVE` bookings cause conflicts. `COMPLETED` and `CANCELLED` bookings do not block slots.
   - Distinct slots never conflict even with identical time windows.

3. **Navigation Workflow**:
   - Accepts a `ParkingSlot` or `slotCode`.
   - Resolves canonical vertex ID (`slot.navigationNodeId` or `ParkingGraphFactory.slotCodeToNodeId(slotCode)`).
   - Executes `Dijkstra.findShortestPath` from `NODE_ENTRANCE` (or custom origin).
   - Returns immutable `NavigationRoute` containing distance in meters, node ID sequence, and reachability flag.

### 7.4 In-Memory Scope and Backend Boundaries

> [!IMPORTANT]
> **Client-Side Optimistic Validation vs. Authoritative Settlement**:  
> The client-side `BookingConflictService` and `CustomIntervalTree` provide zero-latency UI feedback, blocking invalid reservation attempts before network transmission. However, client memory is non-authoritative and transient. The authoritative single source of truth is the Spring Boot backend, which executes transactional database validation (`POST /api/bookings`) with locking to prevent double bookings across concurrent users.

---

## 8. Phase 3.0 — Frontend-Only Prototype Architecture

### 8.1 Critical Architecture Decision: Frontend-Only Prototype
SmartPark's initial prototype is explicitly implemented as a **frontend-only Flutter application**. Remote backend development, including Spring Boot REST APIs, database persistence layers (PostgreSQL / H2 / JPA), remote repositories, and authentication infrastructure, is deferred to a future version.

All application logic, data modeling, conflict detection, routing, and recommendation algorithms execute in-memory inside the Flutter runtime on top of the four custom DSA implementations from Phase 2.

### 8.2 Centralized Local Data Architecture (`SmartParkLocalData`)
Local data is centralized in `frontend/lib/data/local/smartpark_local_data.dart`:
- **Facility Layout**: Strictly conforms to `PARKING_FACILITY_DESIGN.md` (Revision 2.1.0).
  - 1 West entrance gate (`NODE_ENTRANCE`).
  - 10 Central driving aisle waypoints (`NODE_W01` through `NODE_W10`).
  - Exactly 20 parking bays: Row A North (`P01`–`P10`, $Y = 13.5\text{ m}$) and Row B South (`P11`–`P20`, $Y = 2.5\text{ m}$).
  - All vertices and 5.5m / 3.0m / 4.0m weighted edges are supplied directly by `ParkingGraphFactory.createFacilityGraph()`.
- **Status Distribution**: Realistic baseline distribution across 20 bays:
  - 12 Available: `P01`, `P03`, `P05`, `P06`, `P08`, `P09`, `P11`, `P12`, `P14`, `P16`, `P17`, `P19`.
  - 4 Occupied: `P02`, `P07`, `P13`, `P18`.
  - 2 Reserved: `P04`, `P15`.
  - 2 Maintenance: `P10`, `P20` (`isActive = false`).
- **Sample Bookings**: 4 representative bookings testing all model lifecycle statuses:
  - `confirmed` (blocking): `B01` on `P04` [14:00 – 16:00).
  - `active` (blocking): `B02` on `P15` [10:00 – 12:00).
  - `completed` (non-blocking): `B03` on `P01` [08:00 – 09:30).
  - `cancelled` (non-blocking): `B04` on `P03` [13:00 – 15:00).

### 8.3 Centralized Application Initialization
The application initialization sequence occurs at startup in `main.dart` / `SmartParkLocalData.initializeServices()`:
1. `SmartParkLocalData.createInitialSlots()` supplies the 20 prototype bays.
2. `ParkingSlotService` indexes slots into `CustomHashMap`.
3. `SmartParkLocalData.createInitialBookings()` populates `BookingConflictService` backed by `CustomIntervalTree`.
4. `ParkingNavigationService` builds the authoritative facility graph via `ParkingGraphFactory`.
5. `ParkingRecommendationService` links to the slot and navigation service instances.
6. `SmartParkDsaService` wraps all four services as an orchestrator facade.
7. `SmartParkController` binds the facade into a single reactive state holder.

### 8.4 Shared Service Architecture & State Management
- **Lightweight State Management**: SmartPark uses Flutter's native `ChangeNotifier` (`SmartParkController`) and `InheritedNotifier` (`SmartParkScope`), adhering to minimal dependency and platform-first architectural principles. No external state libraries (Riverpod, Bloc, MobX) are required.
- **Shared Singleton Controller**: `SmartParkScope` provides $O(1)$ subtree access via `SmartParkScope.of(context)`. All screens and widgets share the exact same underlying service instances, preventing split-brain state.
- **In-Memory Volatility**: Mutating slots or adding bookings updates the shared application state during a running session. State resets cleanly to default hardcoded data upon application restart or via the user-facing reset action.

### 8.5 UI-to-Service Interaction Rules
1. UI components interact exclusively through `SmartParkScope` and `SmartParkController` / `SmartParkDsaService`.
2. UI widgets never directly manipulate DSA structures or implement search/sorting algorithms.
3. Dashboard availability metrics (Total, Available, Occupied, Reserved, Maintenance) are computed dynamically from `slotService.getAllSlots()`, never hardcoded into UI presentation code.

---

## 9. Phase 3.1 — Parking Slots Interface & Interactive Facility View

### 9.1 Overview and Screen Navigation
Phase 3.1 introduces the dedicated parking facility exploration screen:
- **Location**: `frontend/lib/features/parking/parking_slots_screen.dart`
- **Dashboard Quick Action**: The dashboard's "Parking Slots" quick action tile triggers native Flutter route navigation (`Navigator.of(context).push(MaterialPageRoute(...))`) to `ParkingSlotsScreen`. Standard `AppBar` back navigation returns seamlessly to `DashboardScreen`.
- **Other Quick Actions**: "Bookings & Reservations" and "Facility Navigation" remain informational placeholders for Phases 3.2 and 3.3.

### 9.2 Physical Facility Layout Visualization
The facility view faithfully renders the topology defined in `PARKING_FACILITY_DESIGN.md` (Floor 1, 38.0m x 16.0m):
- **Row A (North, $Y = 13.5\text{ m}$)**: Displays bays `P01` through `P10` ordered West to East.
- **Central Driving Aisle ($Y = 8.0\text{ m}$)**: 6.0m wide driving lane with a West entrance indicator (`NODE_ENTRANCE`, $X = 2.0\text{ m}$) and 10 waypoint markers (`NODE_W01` through `NODE_W10`, $X = 6.0\text{ m} \dots 33.0\text{ m}$) aligned with each bay column.
- **Row B (South, $Y = 2.5\text{ m}$)**: Displays bays `P11` through `P20` ordered West to East.
- **Responsiveness**: Wrapped in a horizontal scroll view with smooth scrolling, ensuring high readability and 0px overflow on constrained mobile viewports.

### 9.3 CustomHashMap Service Integration
- **Direct $O(1)$ Keyed Lookup**: The UI retrieves individual slots via `controller.slotService.getSlot(slotCode)`, directly executing separate-chaining key lookup against the underlying `CustomHashMap`.
- **Zero Redundancy**: The presentation tier avoids local registries, duplicate collections, or duplicate business logic.
- **Reactivity**: Widgets subscribe to `SmartParkController` via `SmartParkScope`. Calling mutations like `controller.updateSlotStatus()` triggers subtree rebuilds with updated live metrics and bay states.

### 9.4 Search and Status Filtering Architecture
- **Filtering Logic**: Evaluates `slot.slotCode.contains(query.trim().toUpperCase())` combined with `selectedStatus == null || slot.status == selectedStatus`.
- **In-Place Highlighting**: Non-matching bays remain in the physical diagram but are dimmed (opacity 0.25, tap disabled), preserving physical orientation while emphasizing matching bays.
- **Empty State**: When 0 bays match across both rows, a dedicated empty state widget appears with a one-tap "Reset All Filters" action.
- **Non-Mutating**: Filtering strictly selects keys from the active view state; underlying service and model instances remain immutable during filtering.

### 9.5 Slot Inspection Details Modal
- **Interaction**: Tapping an active bay opens `ParkingSlotDetailsSheet` via modal bottom sheet.
- **Authoritative Data**: Displays slot code, status indicator, operational active state (`isActive`), coordinates ($X, Y\text{ m}$), navigation node ID (`navigationNodeId`), and an immediate availability banner (`isAvailable`).
- **Phase Boundary**: Booking workflow is intentionally excluded and deferred to Phase 3.2.




