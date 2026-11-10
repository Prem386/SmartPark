# SmartPark — Parking Facility Design Specification

## 1. Document Information

### 1.1 Metadata
- **Document Title**: SmartPark — Parking Facility Design Specification
- **Revision**: 2.1.0
- **Document Status**: Proposed Facility Design (Phase 2.1)
- **Target Audience**: Academic Reviewers, Viva Examiners, System Designers, Developers

### 1.2 Scope and Purpose
This document provides the definitive physical, spatial, and topological specification for the initial SmartPark prototype facility. It establishes the physical reference layout used by the four custom Dart Data Structures and Algorithms (DSA) described in `docs/DSA_DESIGN.md`.

---

## 2. Design Overview

### 2.1 Prototype Context
SmartPark is an intelligent parking management system designed as an academic demonstration of custom data structures implemented in Dart. The prototype requires a concrete, bounded facility model that is mathematically verifiable, technically realistic, and straightforward to explain during a project defense.

### 2.2 Core Facility Concept
The facility consists of a single surface level accommodating exactly 20 parking slots arranged in two parallel rows of 10 slots each. A central driving aisle runs between the rows from West to East. Vehicles enter and exit through a single gate at the West boundary. The layout establishes a simple spine-and-ribs tree topology, guaranteeing a unique traversable route from the entrance to every parking bay.

---

## 3. Facility Parameters

### 3.1 Physical and Spatial Dimensions
All dimensions and distances are provisional prototype assumptions chosen for software modeling, not surveyed real-world engineering measurements:
- **Facility Footprint**: 38.0 meters (length, X-axis) by 16.0 meters (width, Y-axis).
- **Total Capacity**: Exactly 20 parking slots.
- **Floor Level**: Single level (Floor 1). Vertical transit structures (ramps, elevators, stairs) are excluded.
- **Row Configuration**: Two opposing rows of 10 slots each (Row A on the North side, Row B on the South side).
- **Slot Dimensions**: 2.5 meters wide by 5.0 meters deep, oriented perpendicular (90 degrees) to the central aisle.
- **Slot Spacing**: 3.0 meters center-to-center between adjacent slots in the same row.
- **Central Driving Aisle**: 6.0 meters wide, spanning from $Y = 5.0\text{ m}$ to $Y = 11.0\text{ m}$, with its centerline at $Y = 8.0\text{ m}$.
- **Entrance Location**: Located on the West boundary at coordinates $(X = 2.0\text{ m}, Y = 8.0\text{ m})$.

### 3.2 Operational Boundaries
- **Vehicle Movement**: The 6.0-meter aisle accommodates two-way maneuvering, enabling vehicles to travel Eastward to their allocated slot and return Westward to exit.
- **Uniform Classification**: All 20 bays are classified as `STANDARD`. Specialized bays (EV charging, accessible/disabled, compact) are excluded from the initial prototype.
- **Pricing and Billing Scope**: Pricing models, hourly rates, payment gateways, and billing workflows are excluded from this initial design phase.

---

## 4. Physical Layout

### 4.1 Top-Down ASCII Diagram

```text
+=============================================================================================+
|                                  SMARTPARK PROTOTYPE FACILITY                               |
|                         Provisional Dimensions: 38.0m x 16.0m (Floor 1)                     |
+=============================================================================================+
  Y=16.0m
         +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
         | P01 | P02 | P03 | P04 | P05 | P06 | P07 | P08 | P09 | P10 |  <- ROW A (North)
  Y=11.0m+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
         |                                                           |
  Y=8.0m [ENT]===W01===W02===W03===W04===W05===W06===W07===W08===W09===W10  <- CENTRAL DRIVING AISLE
         |                                                           |
  Y=5.0m +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
         | P11 | P12 | P13 | P14 | P15 | P16 | P17 | P18 | P19 | P20 |  <- ROW B (South)
  Y=0.0m +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
        X=2.0 X=6.0 X=9.0 X=12.0 X=15.0 X=18.0 X=21.0 X=24.0 X=27.0 X=30.0 X=33.0   X=38.0m
```

### 4.2 Coordinate System Specification
- **Origin $(0.0, 0.0)$**: South-West corner of the facility boundary.
- **X-axis**: Extends Eastward from 0.0 meters to 38.0 meters.
- **Y-axis**: Extends Northward from 0.0 meters to 16.0 meters.
- **Row A Bay Centers**: Positioned along $Y = 13.5\text{ m}$, spanning $Y = 11.0\text{ m}$ to $16.0\text{ m}$.
- **Driving Aisle Centerline**: Positioned along $Y = 8.0\text{ m}$, spanning $Y = 5.0\text{ m}$ to $11.0\text{ m}$.
- **Row B Bay Centers**: Positioned along $Y = 2.5\text{ m}$, spanning $Y = 0.0\text{ m}$ to $5.0\text{ m}$.
- **Entrance Waypoint**: Positioned at $(X = 2.0\text{ m}, Y = 8.0\text{ m})$.
- **Aisle Waypoints $W01$–$W10$**: Positioned along $Y = 8.0\text{ m}$ at uniform 3.0-meter intervals:
  $$X(W_i) = 6.0 + 3.0 \cdot (i - 1) \quad \text{for } i \in [1, 10]$$
  Specifically: $W01 = (6.0, 8.0)$, $W02 = (9.0, 8.0)$, $W03 = (12.0, 8.0)$, $W04 = (15.0, 8.0)$, $W05 = (18.0, 8.0)$, $W06 = (21.0, 8.0)$, $W07 = (24.0, 8.0)$, $W08 = (27.0, 8.0)$, $W09 = (30.0, 8.0)$, and $W10 = (33.0, 8.0)$.

---

## 5. Parking Slot Specification

### 5.1 Slot Naming and Row Mapping
- **Slot Identifier Syntax**: The letter `P` followed by two zero-padded decimal digits (`P01` to `P20`).
- **Row Mapping**:
  - `P01` through `P10` designate Row A bays (North side), ordered West to East.
  - `P11` through `P20` designate Row B bays (South side), ordered West to East.
- **Opposing Bay Pairs**: Each pair $(P_i, P_{i+10})$ sits on opposite sides of the central aisle directly aligned with waypoint $W_i$ for $i \in [1, 10]$.
- **Slot Type**: Every bay is `STANDARD`.
- **Default State**: Every bay initializes with status `AVAILABLE`.
- **Pricing Scope**: No hourly rates, billing attributes, or payment fields exist on any slot record.

### 5.2 Complete Slot Inventory Table

| Slot ID | Row | Position in Row | Center Coordinates | Floor | Associated Waypoint | Navigation Node ID | Slot Type | Default Status |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **P01** | Row A (North) | 1 | $(6.0, 13.5)$ | 1 | `NODE_W01` | `NODE_P01` | STANDARD | AVAILABLE |
| **P02** | Row A (North) | 2 | $(9.0, 13.5)$ | 1 | `NODE_W02` | `NODE_P02` | STANDARD | AVAILABLE |
| **P03** | Row A (North) | 3 | $(12.0, 13.5)$ | 1 | `NODE_W03` | `NODE_P03` | STANDARD | AVAILABLE |
| **P04** | Row A (North) | 4 | $(15.0, 13.5)$ | 1 | `NODE_W04` | `NODE_P04` | STANDARD | AVAILABLE |
| **P05** | Row A (North) | 5 | $(18.0, 13.5)$ | 1 | `NODE_W05` | `NODE_P05` | STANDARD | AVAILABLE |
| **P06** | Row A (North) | 6 | $(21.0, 13.5)$ | 1 | `NODE_W06` | `NODE_P06` | STANDARD | AVAILABLE |
| **P07** | Row A (North) | 7 | $(24.0, 13.5)$ | 1 | `NODE_W07` | `NODE_P07` | STANDARD | AVAILABLE |
| **P08** | Row A (North) | 8 | $(27.0, 13.5)$ | 1 | `NODE_W08` | `NODE_P08` | STANDARD | AVAILABLE |
| **P09** | Row A (North) | 9 | $(30.0, 13.5)$ | 1 | `NODE_W09` | `NODE_P09` | STANDARD | AVAILABLE |
| **P10** | Row A (North) | 10 | $(33.0, 13.5)$ | 1 | `NODE_W10` | `NODE_P10` | STANDARD | AVAILABLE |
| **P11** | Row B (South) | 1 | $(6.0, 2.5)$ | 1 | `NODE_W01` | `NODE_P11` | STANDARD | AVAILABLE |
| **P12** | Row B (South) | 2 | $(9.0, 2.5)$ | 1 | `NODE_W02` | `NODE_P12` | STANDARD | AVAILABLE |
| **P13** | Row B (South) | 3 | $(12.0, 2.5)$ | 1 | `NODE_W03` | `NODE_P13` | STANDARD | AVAILABLE |
| **P14** | Row B (South) | 4 | $(15.0, 2.5)$ | 1 | `NODE_W04` | `NODE_P14` | STANDARD | AVAILABLE |
| **P15** | Row B (South) | 5 | $(18.0, 2.5)$ | 1 | `NODE_W05` | `NODE_P15` | STANDARD | AVAILABLE |
| **P16** | Row B (South) | 6 | $(21.0, 2.5)$ | 1 | `NODE_W06` | `NODE_P16` | STANDARD | AVAILABLE |
| **P17** | Row B (South) | 7 | $(24.0, 2.5)$ | 1 | `NODE_W07` | `NODE_P17` | STANDARD | AVAILABLE |
| **P18** | Row B (South) | 8 | $(27.0, 2.5)$ | 1 | `NODE_W08` | `NODE_P18` | STANDARD | AVAILABLE |
| **P19** | Row B (South) | 9 | $(30.0, 2.5)$ | 1 | `NODE_W09` | `NODE_P19` | STANDARD | AVAILABLE |
| **P20** | Row B (South) | 10 | $(33.0, 2.5)$ | 1 | `NODE_W10` | `NODE_P20` | STANDARD | AVAILABLE |

---

## 6. Graph Model

### 6.1 Vertices and Edge Definitions
The facility is modeled as a connected, weighted undirected graph $G = (V, E)$:
- **Vertices ($V$, $|V| = 31$)**:
  - `NODE_ENTRANCE`: Entry gate waypoint at $(2.0, 8.0)$.
  - `NODE_W01` through `NODE_W10`: 10 decision waypoints along the aisle centerline at $Y = 8.0\text{ m}$.
  - `NODE_P01` through `NODE_P20`: 20 target slot bay nodes placed at bay center coordinates.
- **Edges ($E$, $|E| = 30$ undirected edges / 60 directed adjacency list entries)**:
  - Traversable pathways connecting contiguous spatial nodes. All links are bidirectional (`isBidirectional = true`).

### 6.2 Edge Weight Derivations
Edge weights represent non-negative Euclidean distances in meters along drivable centerlines:
1. **Entrance to First Waypoint** (1 link):
   $$\text{dist}(\text{NODE\_ENTRANCE}, \text{NODE\_W01}) = 6.0 - 2.0 = 4.0\text{ meters}$$
2. **Consecutive Aisle Waypoints** (9 links):
   $$\text{dist}(\text{NODE\_W}_i, \text{NODE\_W}_{i+1}) = 9.0 - 6.0 = 3.0\text{ meters} \quad \text{for } i \in [1, 9]$$
3. **Aisle Waypoint to Row A Slot** (10 links):
   $$\text{dist}(\text{NODE\_W}_i, \text{NODE\_P}_i) = 13.5 - 8.0 = 5.5\text{ meters} \quad \text{for } i \in [1, 10]$$
4. **Aisle Waypoint to Row B Slot** (10 links):
   $$\text{dist}(\text{NODE\_W}_i, \text{NODE\_P}_{i+10}) = 8.0 - 2.5 = 5.5\text{ meters} \quad \text{for } i \in [1, 10]$$

Total undirected edge count: $1 + 9 + 10 + 10 = 30$ edges.

### 6.3 Adjacency List Representation
The static topology is serialized as an adjacency list consumed by the Flutter application's custom graph structure:

```json
{
  "floor": 1,
  "nodes": [
    { "id": "NODE_ENTRANCE", "label": "Main Entrance", "x": 2.0, "y": 8.0, "floor": 1, "nodeType": "ENTRANCE" },
    { "id": "NODE_W01", "label": "Aisle Waypoint 1", "x": 6.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W02", "label": "Aisle Waypoint 2", "x": 9.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W03", "label": "Aisle Waypoint 3", "x": 12.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W04", "label": "Aisle Waypoint 4", "x": 15.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W05", "label": "Aisle Waypoint 5", "x": 18.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W06", "label": "Aisle Waypoint 6", "x": 21.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W07", "label": "Aisle Waypoint 7", "x": 24.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W08", "label": "Aisle Waypoint 8", "x": 27.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W09", "label": "Aisle Waypoint 9", "x": 30.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_W10", "label": "Aisle Waypoint 10", "x": 33.0, "y": 8.0, "floor": 1, "nodeType": "AISLE_WAYPOINT" },
    { "id": "NODE_P01", "label": "Slot P01 (Row A)", "x": 6.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P02", "label": "Slot P02 (Row A)", "x": 9.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P03", "label": "Slot P03 (Row A)", "x": 12.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P04", "label": "Slot P04 (Row A)", "x": 15.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P05", "label": "Slot P05 (Row A)", "x": 18.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P06", "label": "Slot P06 (Row A)", "x": 21.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P07", "label": "Slot P07 (Row A)", "x": 24.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P08", "label": "Slot P08 (Row A)", "x": 27.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P09", "label": "Slot P09 (Row A)", "x": 30.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P10", "label": "Slot P10 (Row A)", "x": 33.0, "y": 13.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P11", "label": "Slot P11 (Row B)", "x": 6.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P12", "label": "Slot P12 (Row B)", "x": 9.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P13", "label": "Slot P13 (Row B)", "x": 12.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P14", "label": "Slot P14 (Row B)", "x": 15.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P15", "label": "Slot P15 (Row B)", "x": 18.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P16", "label": "Slot P16 (Row B)", "x": 21.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P17", "label": "Slot P17 (Row B)", "x": 24.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P18", "label": "Slot P18 (Row B)", "x": 27.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P19", "label": "Slot P19 (Row B)", "x": 30.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" },
    { "id": "NODE_P20", "label": "Slot P20 (Row B)", "x": 33.0, "y": 2.5, "floor": 1, "nodeType": "PARKING_SLOT" }
  ],
  "edges": [
    { "id": "E_ENT_W01", "sourceNodeId": "NODE_ENTRANCE", "targetNodeId": "NODE_W01", "weight": 4.0, "isBidirectional": true },
    { "id": "E_W01_W02", "sourceNodeId": "NODE_W01", "targetNodeId": "NODE_W02", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W02_W03", "sourceNodeId": "NODE_W02", "targetNodeId": "NODE_W03", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W03_W04", "sourceNodeId": "NODE_W03", "targetNodeId": "NODE_W04", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W04_W05", "sourceNodeId": "NODE_W04", "targetNodeId": "NODE_W05", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W05_W06", "sourceNodeId": "NODE_W05", "targetNodeId": "NODE_W06", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W06_W07", "sourceNodeId": "NODE_W06", "targetNodeId": "NODE_W07", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W07_W08", "sourceNodeId": "NODE_W07", "targetNodeId": "NODE_W08", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W08_W09", "sourceNodeId": "NODE_W08", "targetNodeId": "NODE_W09", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W09_W10", "sourceNodeId": "NODE_W09", "targetNodeId": "NODE_W10", "weight": 3.0, "isBidirectional": true },
    { "id": "E_W01_P01", "sourceNodeId": "NODE_W01", "targetNodeId": "NODE_P01", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W02_P02", "sourceNodeId": "NODE_W02", "targetNodeId": "NODE_P02", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W03_P03", "sourceNodeId": "NODE_W03", "targetNodeId": "NODE_P03", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W04_P04", "sourceNodeId": "NODE_W04", "targetNodeId": "NODE_P04", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W05_P05", "sourceNodeId": "NODE_W05", "targetNodeId": "NODE_P05", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W06_P06", "sourceNodeId": "NODE_W06", "targetNodeId": "NODE_P06", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W07_P07", "sourceNodeId": "NODE_W07", "targetNodeId": "NODE_P07", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W08_P08", "sourceNodeId": "NODE_W08", "targetNodeId": "NODE_P08", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W09_P09", "sourceNodeId": "NODE_W09", "targetNodeId": "NODE_P09", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W10_P10", "sourceNodeId": "NODE_W10", "targetNodeId": "NODE_P10", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W01_P11", "sourceNodeId": "NODE_W01", "targetNodeId": "NODE_P11", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W02_P12", "sourceNodeId": "NODE_W02", "targetNodeId": "NODE_P12", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W03_P13", "sourceNodeId": "NODE_W03", "targetNodeId": "NODE_P13", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W04_P14", "sourceNodeId": "NODE_W04", "targetNodeId": "NODE_P14", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W05_P15", "sourceNodeId": "NODE_W05", "targetNodeId": "NODE_P15", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W06_P16", "sourceNodeId": "NODE_W06", "targetNodeId": "NODE_P16", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W07_P17", "sourceNodeId": "NODE_W07", "targetNodeId": "NODE_P17", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W08_P18", "sourceNodeId": "NODE_W08", "targetNodeId": "NODE_P18", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W09_P19", "sourceNodeId": "NODE_W09", "targetNodeId": "NODE_P19", "weight": 5.5, "isBidirectional": true },
    { "id": "E_W10_P20", "sourceNodeId": "NODE_W10", "targetNodeId": "NODE_P20", "weight": 5.5, "isBidirectional": true }
  ]
}
```

### 6.4 Dijkstra Shortest-Path Route Calculations
Route distances from the entrance to any slot $P_i$ (Row A) or $P_{i+10}$ (Row B) follow the exact closed-form relation:
$$d(\text{ENTRANCE}, P_k) = 4.0 + 3.0 \cdot (i - 1) + 5.5 = 9.5 + 3.0 \cdot (i - 1)\text{ meters} \quad \text{for } i \in [1, 10]$$

#### Verification 1: Route to Slot `P04` ($i = 4$)
- **Node Sequence**: `NODE_ENTRANCE` $\rightarrow$ `NODE_W01` $\rightarrow$ `NODE_W02` $\rightarrow$ `NODE_W03` $\rightarrow$ `NODE_W04` $\rightarrow$ `NODE_P04`.
- **Distance Sum**: $4.0\text{ m} + 3.0\text{ m} + 3.0\text{ m} + 3.0\text{ m} + 5.5\text{ m} = \mathbf{18.5\text{ meters}}$.

#### Verification 2: Route to Slot `P08` ($i = 8$)
- **Node Sequence**: `NODE_ENTRANCE` $\rightarrow$ `NODE_W01` $\rightarrow$ `NODE_W02` $\rightarrow$ `NODE_W03` $\rightarrow$ `NODE_W04` $\rightarrow$ `NODE_W05` $\rightarrow$ `NODE_W06` $\rightarrow$ `NODE_W07` $\rightarrow$ `NODE_W08` $\rightarrow$ `NODE_P08`.
- **Distance Sum**: $4.0\text{ m} + (7 \times 3.0\text{ m}) + 5.5\text{ m} = 4.0\text{ m} + 21.0\text{ m} + 5.5\text{ m} = \mathbf{30.5\text{ meters}}$.

### 6.5 Tree Topology Characteristics and Dijkstra Role
- **Spine-and-Ribs Tree Topology**: The graph forms an acyclic tree consisting of a linear aisle backbone and 20 leaf slot bays. There are no cycles, alternative driving lanes, or competing paths. Exactly one simple path exists between the entrance and any given slot.
- **Role of Dijkstra's Algorithm**: Although path calculation on a tree does not require complex routing decisions, Dijkstra is deliberately implemented to:
  1. Fulfill the academic project curriculum requirement demonstrating Dijkstra on a custom graph using a custom min-heap priority queue.
  2. Ensure the Flutter `NavigationService` remains topologically generalizable. When multi-aisle grids or looped facilities are introduced in future phases, the algorithm will find optimal paths without code changes.

---

## 7. DSA Integration

### 7.1 Custom HashMap (Slot State Lookup)
- **Key**: Slot code string (`"P01"` to `"P20"`).
- **Value**: `ParkingSlot` domain object (`id`, `slotCode`, `row`, `floorNumber`, `slotType`, `status`, `navigationNodeId`, `isActive`).
- **Purpose**: Provides instantaneous in-memory retrieval of parking slot states.
- **Expected Complexity**: $O(1)$ average-time lookup, insertion, and update, governed by hash distribution and bucket collision handling (separate chaining).

### 7.2 Custom Min-Heap (Slot Recommendation & Priority Queue)
- **Recommendation Engine Role**:
  - Surfaces optimal parking bay suggestions based on distance.
  - **Eligibility Filter**: Only slots that are currently available (`status == AVAILABLE` and without conflicting bookings) are inserted into the recommendation heap.
  - **Ranking Metric**: Shortest travel distance from the entrance:
    $$\text{Score}(\text{Slot}) = \text{Distance}(\text{NODE\_ENTRANCE}, \text{Slot})$$
  - **Deterministic Tie-Breaking**: Opposing slots at the same waypoint share identical distances (e.g., $P01$ and $P11$ both at $9.5\text{ m}$). Ties are resolved deterministically using alphanumeric slot-code sorting (`P01` before `P11`, `P02` before `P12`).
- **Dijkstra Priority Queue Role**:
  - Reused by Dijkstra's algorithm to store unvisited nodes as `(nodeId, tentativeDistance)`.
  - Continuously extracts the minimum-distance unvisited node in $O(\log V)$ time.

### 7.3 Custom Interval Tree (Booking Conflict Detection)
- **Unit of Storage**: Each node in the tree represents exactly one booking interval for a specific parking slot.
- **Per-Slot Scoping**: Conflict checks are scoped exclusively to the requested parking slot. Intervals are never evaluated across distinct bays.
- **Node Structure**: Stores `start`, `end`, `bookingId`, `slotId`, and augmented `maxEnd` (the maximum `end` timestamp in the subtree).
- **Half-Open Interval Convention**:
  - Bookings are modeled as $[t_{\text{start}}, t_{\text{end}})$.
  - Two intervals $[s_A, e_A)$ and $[s_B, e_B)$ overlap if and only if:
    $$s_A < e_B \quad \text{and} \quad s_B < e_A$$
  - Adjacent bookings (e.g., $[10:00, 11:00)$ and $[11:00, 12:00)$) do not overlap, correctly permitting back-to-back reservations without false conflicts.
- **Balancing Considerations & Proposed AVL Improvement**:
  - *Phase 1 Baseline (Unbalanced BST)*: The initial design describes an unbalanced augmented BST. In real-world booking systems, reservations frequently arrive in chronological order, which causes an unbalanced BST to degenerate into an $O(N)$ linear chain, degrading search to $O(N)$.
  - *Proposed AVL Balancing (Pending Approval)*: Augmenting the tree with AVL rotations maintains height balance $|h_{\text{left}} - h_{\text{right}}| \le 1$, strictly bounding height to $O(\log N)$. This guarantees $O(\log N)$ worst-case insertion, deletion, and single overlap queries.
  - *Rotation Maintenance*: During AVL rotations, `maxEnd` must be recalculated bottom-up:
    $$\text{node.maxEnd} = \max(\text{node.end}, \text{node.left?.maxEnd}, \text{node.right?.maxEnd})$$
  - *Status*: AVL-balancing is a proposed design enhancement currently pending formal approval.
- **Client vs. Server Authority**:
  - The client-side Interval Tree operates strictly to provide instant optimistic feedback in the UI.
  - The Spring Boot backend and database transactions remain the sole authoritative source of truth for conflict validation and concurrency control.

### 7.4 Graph and Dijkstra's Algorithm (Wayfinding)
- **Navigation Execution**: Computes the shortest traversable path from `NODE_ENTRANCE` to the user's allocated parking bay.
- **Structural vs. Runtime Separation**:
  - The *Adjacency List* represents the static spatial map topology.
  - The *Min-Heap Priority Queue* manages dynamic runtime state during Dijkstra relaxation.
- **UI Output**: Emits the ordered sequence of waypoint coordinates to the Flutter canvas for visual path rendering.

---

## 8. Assumptions and Limitations

### 8.1 Working Assumptions
1. **Conceptual Dimensions**: All dimensions ($38\text{ m} \times 16\text{ m}$), bay widths ($2.5\text{ m}$), and edge distances are provisional prototype assumptions for software modeling, not surveyed civil engineering measurements.
2. **Single Level**: All 20 bays and driving lanes reside on Floor 1. No vertical travel is modeled.
3. **Flat Surface**: Edge weights represent 2D Euclidean distances along driving centerlines with zero vertical grade.
4. **Perpendicular Parking**: All bays are arranged at 90-degree angles relative to the driving aisle.
5. **Bidirectional Aisle**: The 6.0-meter central aisle permits two-way vehicle movement for ingress, parking maneuvers, and egress.
6. **Exclusion of Pricing**: Pricing, hourly rates, and billing features are excluded from the initial prototype scope.

### 8.2 Technical Limitations
1. **Single Access Gate**: The facility features only one entrance/exit zone at the West boundary.
2. **Homogeneous Slots**: All slots are `STANDARD` type. Specialized vehicle bays are not supported.
3. **No Hardware Sensors**: Slot availability is determined solely by software reservation records, not physical IoT hardware.
4. **No Competing Routes**: The spine-and-ribs tree topology provides exactly one path per slot; Dijkstra does not evaluate competing alternative paths in this initial layout.

---

## 9. Future Scalability

1. **Additional Parking Bays**: Additional bays can be added to Row A and Row B by extending the driving aisle Eastward and adding waypoints $W11$, $W12$, etc., without altering the algorithmic structures.
2. **Additional Rows and Aisles**: The graph model can incorporate transverse connector aisles and secondary longitudinal aisles (e.g., Row C, Row D) by adding grid waypoint nodes and cross-aisle edges.
3. **Multiple Entrances and Exits**: A dedicated East exit can convert the central aisle into a unidirectional flow (`isBidirectional = false`). Dijkstra effortlessly supports multiple gates by configuring `startNodeId`.
4. **Advanced Recommendation Criteria**: The Min-Heap scoring metric can be expanded to multi-factor evaluation incorporating user preferences, vehicle size, and walking distances.
5. **Multi-Floor Navigation**: Ramps or elevator nodes can connect Floor 1 waypoints to additional floor levels, with edge weights reflecting vertical transit costs.

---

## 10. Open Decisions Requiring Approval

### 10.1 Pending Decisions Table

| # | Decision Item | Proposed Direction | Alternative Considered | Status |
| :-: | :--- | :--- | :--- | :---: |
| **1** | **Interval Tree AVL Balancing** | Implement AVL height-balancing on `CustomIntervalTree` with rotation-aware `maxEnd` maintenance to strictly guarantee $O(\log N)$ performance. | Retain unbalanced BST from Phase 1, accepting $O(N)$ chronological degradation. | **Pending Approval** |
| **2** | **Booking Interval Convention** | Adopt half-open intervals $[t_{\text{start}}, t_{\text{end}})$ to permit contiguous bookings without false conflicts. | Closed intervals $[t_{\text{start}}, t_{\text{end}}]$ requiring explicit minute buffers. | **Pending Approval** |
| **3** | **Min-Heap Tie-Breaking** | Break equidistant slot ties deterministically using alphanumeric slot-code ordering (`P01` before `P11`). | Arbitrary insertion-order tie-breaking or random selection. | **Pending Approval** |
| **4** | **Slot Code Notation** | Use zero-padded two-digit identifiers `P01` to `P20` across all facility models. | Row-prefixed notation `A01`–`A10` and `B01`–`B10`. | **Pending Approval** |
| **5** | **Bidirectional Aisle Traffic** | Use bidirectional edges on the central aisle so vehicles enter and exit via the single West gate without turnaround loop nodes. | Unidirectional driving with a dedicated turnaround loop node at waypoint $W10$. | **Pending Approval** |
| **6** | **Exclusion of Pricing and Billing** | Exclude all pricing, hourly rates, and billing logic from the initial prototype scope. | Introduce flat or tiered hourly rates ($/hr). | **Pending Approval** |

### 10.2 Cross-Document Alignment Notes
The facility design identifies minor inconsistencies in existing Phase 1 documents to be reconciled in future phases:
- `docs/API_DOCUMENTATION.md` (§4.1): Sample response shows `totalFloors: 3`, `totalSlots: 50`. To be updated to 1 floor, 20 slots during Phase 2 backend seed configuration.
- `docs/API_DOCUMENTATION.md` (§2.1, 4.2) & `docs/DATABASE_DESIGN.md` (§3.2, 3.4): Use placeholder codes (`"A-101"`, `"GATE_NORTH"`). To be reconciled to `P01`–`P20` and `NODE_ENTRANCE`, `NODE_W01`–`NODE_W10`, `NODE_P01`–`NODE_P20`.
- `docs/DSA_DESIGN.md` (§4.2): Specifies an unbalanced augmented BST. To be updated if the proposed AVL-balanced Interval Tree (Decision 1) is formally approved.
