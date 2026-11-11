# SmartPark — Intelligent Parking Management System

SmartPark is an academic demonstration project demonstrating how foundational Computer Science Data Structures and Algorithms (DSA) solve real-world problems in parking facility management, slot recommendation, conflict-free scheduling, and spatial pathfinding.

SmartPark Prototype V1 is implemented as a **frontend-only Flutter application** in pure Dart. The prototype runs with hardcoded local facility data and in-memory application state. There is no remote backend, external database, Firebase, or external state-management package.

---

## Project Objectives

1. **Fast Slot Lookup ($O(1)$)**: Provide instant search, retrieval, and status queries for parking bays without linear array scans.
2. **Intelligent Slot Recommendations ($O(k \log n)$)**: Surface the top-$N$ nearest available parking bays based on driving distance from the facility entrance.
3. **Conflict-Free Reservations ($O(\log n)$)**: Detect and prevent overlapping booking intervals in real time before confirmation.
4. **Optimized Spatial Navigation ($O((V + E) \log V)$)**: Compute the shortest traversable route and generate turn-by-turn waypoint navigation across the parking facility.

---

## Four Custom DSA Implementations

All four core algorithms are implemented manually from first principles in pure Dart (`frontend/lib/dsa/`) without relying on built-in collections (`dart:collection`, `Map`, `SplayTreeMap`) or third-party algorithmic packages:

### 1. Custom Generic HashMap (`CustomHashMap<K, V>`)
- **Algorithmic Design**: Fixed bucket array with separate chaining via singly-linked collision nodes (`HashNode<K, V>`). Computes non-negative 31-bit hash codes (`key.hashCode & 0x7FFFFFFF`) and automatically doubles bucket capacity when load factor reaches 0.75.
- **Complexity**: $O(1)$ average search, insertion, and deletion.
- **Application Integration**: Used by `ParkingSlotService` (`frontend/lib/services/parking_slot_service.dart`) to index all 20 physical bays by `slotCode` for instantaneous lookup. Also used internally by `WeightedGraph` to store vertex registries and adjacency lists.

### 2. Custom Min-Heap (`CustomMinHeap<T>`)
- **Algorithmic Design**: Complete binary tree mapped to a 0-indexed contiguous dynamic array (`List<T>`). Supports $O(\log n)$ sift-up (`insert`) and sift-down (`extractMin`), and builds heaps in $O(n)$ time via Floyd's bottom-up heapification (`buildHeap`).
- **Complexity**: $O(\log n)$ insertion and extraction; $O(1)$ peek; $O(n)$ construction.
- **Application Integration**:
  - Powers Dijkstra's algorithm as the priority queue for vertex relaxation.
  - Used by `ParkingRecommendationService` (`frontend/lib/services/parking_recommendation_service.dart`) to rank candidate parking bays by distance from the entrance and extract the top-$N$ nearest bays.

### 3. AVL-Augmented Interval Tree (`CustomIntervalTree`)
- **Algorithmic Design**: Self-balancing binary search tree ordered by interval start time, balanced using standard AVL rotations (LL, RR, LR, RL). Each node is augmented with `maxEnd`, the maximum reservation end time across its subtree. Enforces half-open interval semantics $[t_{\text{start}}, t_{\text{end}})$ where touching boundaries (e.g. 10:00–11:00 and 11:00–12:00) do NOT overlap.
- **Complexity**: $O(\log n)$ insertion, deletion, and overlap search; $O(k \log n)$ to collect $k$ overlapping reservations.
- **Application Integration**: Used by `BookingConflictService` (`frontend/lib/services/booking_conflict_service.dart`) to detect temporal conflicts in real time on the same slot, filtering out non-blocking statuses (`cancelled`, `completed`).

### 4. Custom Weighted Graph + Dijkstra (`WeightedGraph`, `Dijkstra`)
- **Algorithmic Design**: Undirected/directed graph using an adjacency list structure backed by `CustomHashMap`. Dijkstra's algorithm utilizes the custom `CustomMinHeap` with lazy duplicate relaxation, skipping stale entries, early termination upon reaching the destination, and backtrack path reconstruction with cycle detection.
- **Complexity**: $O((V + E) \log V)$ time bound; $O(V + E)$ auxiliary space.
- **Application Integration**: Used by `ParkingNavigationService` (`frontend/lib/services/parking_navigation_service.dart`) to calculate shortest paths and travel distances in meters from the entrance (`NODE_ENTRANCE`) to any parking bay. Path results are rendered on canvas via `FacilityRoutePainter`.

---

## Main Application Features

### 1. Dashboard (`DashboardScreen`)
- **Dynamic Metrics Grid**: Real-time summary counts (Total Slots: 20, Available: 12, Occupied: 4, Reserved: 2, Maintenance: 2) derived dynamically from the service layer.
- **Algorithmic Recommendation Highlight**: Prominently highlights the optimal available parking bay computed via Dijkstra shortest path and Min-Heap extraction.
- **Quick Actions**: One-tap navigation to all application modules.
- **Data Reset**: App bar action restoring in-memory application state back to clean baseline defaults.

### 2. Parking Slots (`ParkingSlotsScreen`)
- **Physical Facility Layout**: 38.0m $\times$ 16.0m layout conforming to `docs/PARKING_FACILITY_DESIGN.md` (Row A North: P01–P10, Central Aisle with Entrance and 10 Waypoints, Row B South: P11–P20).
- **Interactive Inspection**: Tapping any slot opens a modal bottom sheet displaying coordinates, navigation vertex ID, operational state, and a shortcut to reserve available bays.
- **Search & Filter**: Combined bay search and status dropdown; non-matching bays are dimmed (opacity 0.25) to preserve physical orientation while highlighting matches.
- **Responsive Viewport**: Horizontally scrollable diagram preventing clipping or pixel overflow across all device sizes.

### 3. Bookings & Reservations (`BookingsScreen`, `CreateBookingScreen`)
- **Reservation Management**: Filterable list of active and historical reservations with status badges (Confirmed, Active, Completed, Cancelled).
- **Cancellation**: One-tap cancellation with confirmation dialog; automatically releases reserved bays back to `available` if no remaining blocking bookings exist.
- **Interactive Reservation Form**: Complete creation workflow with slot selector, date picker, start/end time pickers, and customer details.
- **Real-Time Interval Tree Validation**: Live feedback banner alerting users to availability, past-time warnings, invalid time ordering, or overlapping booking conflicts.

### 4. Facility Navigation (`FacilityNavigationScreen`)
- **Shortest-Path Pathfinding**: Computes optimal driving routes from the facility entrance (`NODE_ENTRANCE`) to any destination bay via Dijkstra's algorithm.
- **Custom Route Painter (`FacilityRoutePainter`)**: Renders all 30 facility graph links in subtle slate and overlays the active shortest path in bold blue with directional arrows positioned in layout gaps.
- **Turn-by-Turn Waypoint Sequence**: Displays complete hop-by-hop breakdown showing origin, intermediate aisle waypoints with segment travel distances, and final arrival bay.
- **Multiple Selection Modes**: Direct bay selection by tapping the layout diagram, dropdown picker, or quick shortcut chips.

---

## Architecture Overview

SmartPark follows a decoupled, multi-tier architectural pattern:

```text
┌────────────────────────────────────────────────────────┐
│                      Presentation                      │
│   Dashboard  •  Parking Slots  •  Bookings  •  Nav     │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    State Management                    │
│   SmartParkScope (InheritedNotifier)                   │
│   SmartParkController (ChangeNotifier)                 │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                Application Service Layer               │
│   SmartParkDsaService (Facade)                         │
│   ├── ParkingSlotService                               │
│   ├── BookingConflictService                           │
│   ├── ParkingNavigationService                         │
│   └── ParkingRecommendationService                     │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                  Custom Pure Dart DSA                  │
│   CustomHashMap  •  CustomMinHeap                      │
│   CustomIntervalTree  •  WeightedGraph + Dijkstra      │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                   Domain Models & Data                 │
│   ParkingSlot  •  Booking  •  GraphNode  •  GraphEdge  │
│   SmartParkLocalData (20 Canonical Bays & Samples)     │
└────────────────────────────────────────────────────────┘
```

Detailed architectural specifications, data flows, and design rationale can be found in:
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — System architecture, service coordination, and component data flows.
- [`docs/PARKING_FACILITY_DESIGN.md`](docs/PARKING_FACILITY_DESIGN.md) — Physical facility geometry, coordinates, and topological layout.
- [`docs/DSA_DESIGN.md`](docs/DSA_DESIGN.md) — Algorithmic design, invariants, and complexity proofs.

---

## Technology Stack

- **Framework**: Flutter (3.13.7+)
- **Language**: Dart (3.13.7+)
- **Design System**: Material 3
- **State Management**: Native Flutter (`ChangeNotifier` + `InheritedNotifier`)
- **Dependencies**: Zero external functional dependencies (only `flutter` SDK, `cupertino_icons`, `flutter_test`, and `flutter_lints`).

---

## Project Structure

```text
SmartPark/
├── README.md                          # Project documentation and execution instructions
├── docs/
│   ├── ARCHITECTURE.md                # System architecture specification
│   ├── DSA_DESIGN.md                  # Data structures and algorithms specification
│   ├── PARKING_FACILITY_DESIGN.md     # Facility geometry and coordinate layout
│   ├── API_DOCUMENTATION.md           # Proposed future REST API specification
│   └── DATABASE_DESIGN.md             # Proposed future database entity design
│
└── frontend/
    ├── pubspec.yaml                   # Flutter package specification
    ├── analysis_options.yaml          # Static analysis and lint configurations
    ├── lib/
    │   ├── main.dart                  # Application entry point
    │   ├── app.dart                   # MaterialApp root widget
    │   ├── core/theme/                # Material 3 theme definitions
    │   ├── data/local/                # SmartParkLocalData (canonical bays & sample bookings)
    │   ├── dsa/                       # Pure Dart custom DSA implementations (NO UI code)
    │   │   ├── hashmap/               # CustomHashMap and HashNode
    │   │   ├── min_heap/              # CustomMinHeap and ParkingSlotCandidate
    │   │   ├── interval_tree/         # CustomIntervalTree and IntervalTreeNode
    │   │   └── graph/                 # WeightedGraph, Dijkstra, and ParkingGraphFactory
    │   ├── models/                    # ParkingSlot and Booking domain models
    │   ├── services/                  # Application services and SmartParkController
    │   ├── widgets/                   # SmartParkScope state injection
    │   └── features/                  # UI screens and presentation widgets
    │       ├── dashboard/             # DashboardScreen and metrics widgets
    │       ├── parking/               # ParkingSlotsScreen and facility layout
    │       ├── bookings/              # BookingsScreen, CreateBookingScreen, and time selector
    │       └── navigation/            # FacilityNavigationScreen, painter, and route card
    │
    └── test/                          # Automated test suite (300+ tests)
        ├── dsa/                       # Dedicated unit tests for all 4 custom DSAs
        ├── services/                  # Service coordination and workflow integration tests
        ├── models/                    # Model invariant and serialization tests
        ├── features/                  # Screen and widget integration tests
        └── data/                      # Local data specification tests
```

---

## Prerequisites

- **Flutter SDK**: Version 3.13.7 or newer
- **Dart SDK**: Version 3.13.7 or newer
- An active device, emulator, or desktop browser / window (Chrome, Windows, Android, iOS)

Verify your environment by running:
```powershell
flutter doctor
```

---

## Installation, Execution, and Verification

Navigate into the `frontend` directory:

```powershell
cd frontend
```

### 1. Install Dependencies
```powershell
flutter pub get
```

### 2. Run the Application
```powershell
flutter run
```

### 3. Run Automated Tests
Execute the complete test suite:
```powershell
flutter test
```

### 4. Run Static Code Analysis
Verify that there are zero lint issues, warnings, or compilation errors:
```powershell
flutter analyze
```

---

## Prototype Scope & Academic Boundaries

- **In-Memory Prototype**: SmartPark Prototype V1 runs completely in-memory inside the Flutter runtime. All slot states, reservations, and calculated paths operate in RAM.
- **State Reset**: Application state resets cleanly to baseline defaults on app restart or by tapping the reset action in the top app bar.
- **Future Backend Scope**: `docs/API_DOCUMENTATION.md` and `docs/DATABASE_DESIGN.md` outline architectural designs for a future Spring Boot backend and relational database (PostgreSQL/MySQL), which are intentionally deferred to future versions.
