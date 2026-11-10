# SmartPark – Database Entity Design

> **Document Status**: Proposed Entity Design (Phase 1: Architecture Foundation)  
> **Database Engine Status**: Unfinalized (Evaluating PostgreSQL, MySQL, and SQLite)  
> **Implementation Note**: SQL DDL scripts, migration scripts, and DBMS-specific configurations are deferred to Phase 2.

---

## 1. Overview & Architectural Role

The database serves as the **authoritative persistent source of truth** for SmartPark. While the Flutter mobile frontend maintains transient, in-memory custom data structures (Custom HashMap, Custom Interval Tree, Custom Min-Heap, and Navigation Graph) to deliver instantaneous user feedback, all reservations, slot assignments, and user records must be authoritatively committed to and validated by the backend database managed through Spring Boot.

---

## 2. Proposed Database Entities

The system defines five primary domain entities:
1. `User`
2. `ParkingSlot`
3. `Booking`
4. `NavigationNode`
5. `NavigationEdge`

```
+--------------------+        1        * +--------------------+
|        User        |-------------------|      Booking       |
+--------------------+                   +--------------------+
| id (PK)            |                   | id (PK)            |
| username           |                   | user_id (FK)       |
| email              |                   | slot_id (FK)       |
| phone_number       |                   | start_time         |
| vehicle_number     |                   | end_time           |
| role               |                   | status             |
| created_at         |                   | total_cost         |
+--------------------+                   | created_at         |
                                         +--------------------+
                                                   | *
                                                   |
                                                   | 1
+--------------------+        1        1 +--------------------+
|   NavigationNode   |-------------------|    ParkingSlot     |
+--------------------+ (optional 0..1)   +--------------------+
| id (PK)            |                   | id (PK)            |
| node_code          |                   | slot_code          |
| label              |                   | floor_number       |
| x_coord            |                   | slot_type          |
| y_coord            |                   | status             |
| floor_number       |                   | base_hourly_rate   |
| node_type          |                   | navigation_node_id |
| is_active          |                   | is_active          |
+--------------------+                   +--------------------+
        | 1
        |
        | *
+--------------------+
|   NavigationEdge   |
+--------------------+
| id (PK)            |
| source_node_id(FK) |
| target_node_id(FK) |
| weight_distance    |
| is_bidirectional   |
| is_accessible      |
+--------------------+
```

---

## 3. Detailed Entity Specifications

### 3.1 Entity: `User`
Represents an individual utilizing or administering the parking facility.

| Attribute | Logical Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | PRIMARY KEY | Unique user identifier. |
| `username` | VARCHAR(50) | NOT NULL, UNIQUE | User login name. |
| `email` | VARCHAR(100) | NOT NULL, UNIQUE | Email address for booking receipts. |
| `password_hash` | VARCHAR(255) | NOT NULL | Salted cryptographic password hash. |
| `phone_number` | VARCHAR(20) | NULLABLE | Contact telephone number. |
| `vehicle_number`| VARCHAR(20) | NOT NULL | Default license plate (e.g., "KA-01-AB-1234"). |
| `role` | VARCHAR(20) | NOT NULL | Authorization role (`ROLE_USER`, `ROLE_ADMIN`). |
| `created_at` | TIMESTAMP | NOT NULL | Account creation timestamp. |
| `updated_at` | TIMESTAMP | NOT NULL | Last profile update timestamp. |

### 3.2 Entity: `ParkingSlot`
Represents a physical parking bay in the parking lot.

| Attribute | Logical Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | PRIMARY KEY | Unique slot record ID. |
| `slot_code` | VARCHAR(20) | NOT NULL, UNIQUE | Identifiable physical bay code (e.g., "A-101"). |
| `floor_number` | INTEGER | NOT NULL | Floor index (-1 for basement, 1 for ground, etc.). |
| `slot_type` | VARCHAR(20) | NOT NULL | Category: `STANDARD`, `COMPACT`, `HANDICAP`, `EV_CHARGING`. |
| `status` | VARCHAR(20) | NOT NULL | Current state: `AVAILABLE`, `OCCUPIED`, `RESERVED`, `MAINTENANCE`. |
| `base_hourly_rate` | DECIMAL(10,2) | NOT NULL | Hourly billing cost in local currency. |
| `navigation_node_id`| UUID / BIGINT | NULLABLE, FK | Reference to spatial node representing this bay on the navigation map. |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Soft-delete / availability toggle. |

### 3.3 Entity: `Booking`
Represents a time-bound parking reservation made by a user for a specific parking bay.

| Attribute | Logical Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | PRIMARY KEY | Unique booking identifier. |
| `user_id` | UUID / BIGINT | NOT NULL, FK $\rightarrow$ User | The customer who owns this booking. |
| `slot_id` | UUID / BIGINT | NOT NULL, FK $\rightarrow$ ParkingSlot | The allocated parking slot. |
| `start_time` | TIMESTAMP | NOT NULL | Reserved interval start time. |
| `end_time` | TIMESTAMP | NOT NULL | Reserved interval end time (`end_time > start_time`). |
| `status` | VARCHAR(20) | NOT NULL | State: `CONFIRMED`, `ACTIVE`, `COMPLETED`, `CANCELLED`. |
| `total_cost` | DECIMAL(10,2) | NOT NULL | Calculated reservation fee. |
| `vehicle_number`| VARCHAR(20) | NOT NULL | Vehicle registered for this session. |
| `created_at` | TIMESTAMP | NOT NULL | Booking timestamp. |
| `updated_at` | TIMESTAMP | NOT NULL | Modification timestamp. |

> **Authoritative Server Validation Rule**:  
> A new booking $[t_{\text{start}}, t_{\text{end}}]$ for `slot_id` is only valid if no existing booking with `status IN ('CONFIRMED', 'ACTIVE')` satisfies:  
> $$\text{existing.start\_time} < t_{\text{end}} \quad \text{AND} \quad \text{existing.end\_time} > t_{\text{start}}$$  
> Spring Boot enforces this check inside a transactional boundary to prevent double bookings.

### 3.4 Entity: `NavigationNode`
Represents a topological waypoint on the facility layout for pathfinding.

| Attribute | Logical Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | PRIMARY KEY | Unique node identifier. |
| `node_code` | VARCHAR(50) | NOT NULL, UNIQUE | Canonical string identifier (e.g., `"GATE_NORTH"`, `"AISLE_1_2"`). |
| `label` | VARCHAR(100) | NOT NULL | Friendly display name. |
| `x_coord` | DOUBLE PRECISION | NOT NULL | Spatial X coordinate on floor map. |
| `y_coord` | DOUBLE PRECISION | NOT NULL | Spatial Y coordinate on floor map. |
| `floor_number` | INTEGER | NOT NULL | Associated floor level. |
| `node_type` | VARCHAR(30) | NOT NULL | Type: `ENTRANCE`, `EXIT`, `AISLE_WAYPOINT`, `PARKING_SLOT`, `ELEVATOR`, `STAIRCASE`. |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Node availability flag. |

### 3.5 Entity: `NavigationEdge`
Represents a traversable link or pathway connecting two navigation nodes.

| Attribute | Logical Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID / BIGINT | PRIMARY KEY | Unique edge identifier. |
| `source_node_id`| UUID / BIGINT | NOT NULL, FK $\rightarrow$ NavigationNode | Starting waypoint. |
| `target_node_id`| UUID / BIGINT | NOT NULL, FK $\rightarrow$ NavigationNode | Destination waypoint. |
| `weight_distance`| DOUBLE PRECISION | NOT NULL | Physical distance in meters (must be $> 0$). |
| `is_bidirectional`| BOOLEAN | NOT NULL, DEFAULT TRUE | Indicates if edge is two-way. |
| `is_accessible` | BOOLEAN | NOT NULL, DEFAULT TRUE | Suitable for wheelchair/disabled access. |

---

## 4. Proposed Relationships & Cardinality

1. **User $\rightarrow$ Booking** (`1 : N`):
   - A single user may create multiple historical or active bookings.
   - Each booking belongs to exactly one registered user.
2. **ParkingSlot $\rightarrow$ Booking** (`1 : N`):
   - A parking slot has multiple chronological bookings over time.
   - Any valid booking is linked to exactly one parking slot.
3. **ParkingSlot $\rightarrow$ NavigationNode** (`0..1 : 1`):
   - An active parking slot may link to a navigation node marking its geographical bay location.
4. **NavigationNode $\rightarrow$ NavigationEdge** (`1 : N`):
   - A waypoint acts as the `source_node` or `target_node` across multiple directional or bidirectional edges.

---

## 5. Candidate Database Engines Under Consideration

| Database Engine | Pros for Student / Academic Scope | Cons / Trade-offs | Decision Status |
| :--- | :--- | :--- | :--- |
| **PostgreSQL** | Native geometric / GIS data types, enterprise concurrency, robust interval checks | Higher local installation and setup overhead | Candidate |
| **MySQL / MariaDB** | Widely taught in academic courses, straightforward Spring Data JPA pairing | Less native support for advanced interval exclusion constraints | Candidate |
| **SQLite / H2** | Zero installation, embedded in-memory mode ideal for rapid local demonstration and automated grading | Not suitable for multi-instance production deployment | Candidate (Dev / Testing) |

---

## 6. Pending Database Decisions

1. Final relational engine selection (PostgreSQL vs MySQL vs SQLite/H2 for prototyping).
2. Key generation strategy (`UUIDv4` vs sequential `BIGINT` auto-increment).
3. ORM framework configuration (Spring Data JPA with Hibernate vs lightweight JDBC).
4. Timestamp time-zone standardization (enforcing UTC across all tables).

