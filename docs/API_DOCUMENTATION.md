# SmartPark – REST API Specification

> **Document Status**: Proposed API Contract (Phase 1: Architecture Foundation)  
> **Backend Implementation Status**: Pending Spring Boot Initialization (Phase 2)  
> **Base URL (Local Dev)**: `http://localhost:8080/api`  
> **Data Interchange**: `application/json`

---

## 1. Overview & General Conventions

This document defines the proposed RESTful API contracts between the Flutter mobile application (client) and the Spring Boot backend server.

### Standard Response Codes
- `200 OK`: Request succeeded; response payload contains requested entity/list.
- `201 Created`: Resource successfully created (e.g., booking confirmation).
- `400 Bad Request`: Malformed syntax, invalid parameters, or failed validation.
- `404 Not Found`: Target resource does not exist.
- `409 Conflict`: Business rule violation (e.g., reservation time overlap on requested slot).
- `500 Internal Server Error`: Unhandled backend exception.

### Standard Error Response Format
```json
{
  "timestamp": "2026-11-10T14:30:00Z",
  "status": 409,
  "error": "Conflict",
  "message": "The selected slot is already booked for the requested interval.",
  "path": "/api/bookings"
}
```

---

## 2. Parking Slot Endpoints

### 2.1 `GET /api/slots`
- **Purpose**: Retrieve a comprehensive list of all parking slots in the facility.
- **Contract Status**: Proposed
- **Query Parameters**:
  - `floor` *(optional, integer)*: Filter by floor level (e.g., `?floor=1`).
  - `type` *(optional, string)*: Filter by type (`STANDARD`, `EV_CHARGING`, `HANDICAP`).
- **Response**: `200 OK`
```json
[
  {
    "id": "slot-001",
    "slotCode": "A-101",
    "floorNumber": 1,
    "slotType": "STANDARD",
    "status": "AVAILABLE",
    "baseHourlyRate": 5.00,
    "navigationNodeId": "NODE_A101",
    "isActive": true
  },
  {
    "id": "slot-002",
    "slotCode": "A-102",
    "floorNumber": 1,
    "slotType": "EV_CHARGING",
    "status": "OCCUPIED",
    "baseHourlyRate": 7.50,
    "navigationNodeId": "NODE_A102",
    "isActive": true
  }
]
```

---

### 2.2 `GET /api/slots/{id}`
- **Purpose**: Retrieve detailed information for a specific parking bay.
- **Contract Status**: Proposed
- **Path Parameters**:
  - `id` *(required, string)*: Unique identifier of the parking slot.
- **Responses**:
  - `200 OK`: Slot located.
  - `404 Not Found`: Slot not found.
```json
{
  "id": "slot-001",
  "slotCode": "A-101",
  "floorNumber": 1,
  "slotType": "STANDARD",
  "status": "AVAILABLE",
  "baseHourlyRate": 5.00,
  "navigationNodeId": "NODE_A101",
  "isActive": true
}
```

---

### 2.3 `GET /api/slots/available`
- **Purpose**: Query slots that are currently unreserved or available across a future time window.
- **Contract Status**: Proposed
- **Query Parameters**:
  - `startTime` *(optional, ISO-8601 string)*: Start of reservation window.
  - `endTime` *(optional, ISO-8601 string)*: End of reservation window.
  - `slotType` *(optional, string)*: Preferred slot category.
- **Response**: `200 OK`
```json
[
  {
    "id": "slot-001",
    "slotCode": "A-101",
    "floorNumber": 1,
    "slotType": "STANDARD",
    "status": "AVAILABLE",
    "baseHourlyRate": 5.00,
    "navigationNodeId": "NODE_A101"
  }
]
```

---

## 3. Booking & Reservation Endpoints

### 3.1 `POST /api/bookings`
- **Purpose**: Submit a new parking bay reservation.
- **Contract Status**: Proposed
- **Request Headers**:
  - `Content-Type: application/json`
  - `Authorization: Bearer <token>` *(when authentication is active)*
- **Request Body**:
```json
{
  "userId": "usr-1001",
  "slotId": "slot-001",
  "startTime": "2026-11-10T15:00:00Z",
  "endTime": "2026-11-10T17:00:00Z",
  "vehicleNumber": "KA-01-AB-1234"
}
```
- **Responses**:
  - `201 Created`: Booking accepted and persisted.
  - `400 Bad Request`: Invalid times (e.g. `startTime >= endTime` or in the past).
  - `404 Not Found`: User or Slot ID does not exist.
  - `409 Conflict`: Target slot is already booked during this time interval.
```json
{
  "id": "bk-901",
  "userId": "usr-1001",
  "slotId": "slot-001",
  "slotCode": "A-101",
  "startTime": "2026-11-10T15:00:00Z",
  "endTime": "2026-11-10T17:00:00Z",
  "vehicleNumber": "KA-01-AB-1234",
  "status": "CONFIRMED",
  "totalCost": 10.00,
  "createdAt": "2026-11-10T14:32:00Z"
}
```

---

### 3.2 `GET /api/bookings`
- **Purpose**: Retrieve a list of bookings, optionally filtered by user or active status.
- **Contract Status**: Proposed
- **Query Parameters**:
  - `userId` *(optional, string)*: Filter by customer.
  - `status` *(optional, string)*: Filter by state (`CONFIRMED`, `ACTIVE`, `COMPLETED`, `CANCELLED`).
- **Response**: `200 OK`
```json
[
  {
    "id": "bk-901",
    "userId": "usr-1001",
    "slotId": "slot-001",
    "slotCode": "A-101",
    "startTime": "2026-11-10T15:00:00Z",
    "endTime": "2026-11-10T17:00:00Z",
    "status": "CONFIRMED",
    "totalCost": 10.00
  }
]
```

---

### 3.3 `GET /api/bookings/{id}`
- **Purpose**: Retrieve details of an individual booking.
- **Contract Status**: Proposed
- **Path Parameters**:
  - `id` *(required, string)*: Booking ID.
- **Responses**:
  - `200 OK`: Booking found.
  - `404 Not Found`: Booking ID does not exist.
```json
{
  "id": "bk-901",
  "userId": "usr-1001",
  "slotId": "slot-001",
  "slotCode": "A-101",
  "startTime": "2026-11-10T15:00:00Z",
  "endTime": "2026-11-10T17:00:00Z",
  "vehicleNumber": "KA-01-AB-1234",
  "status": "CONFIRMED",
  "totalCost": 10.00,
  "createdAt": "2026-11-10T14:32:00Z",
  "updatedAt": "2026-11-10T14:32:00Z"
}
```

---

### 3.4 `DELETE /api/bookings/{id}`
- **Purpose**: Cancel an existing reservation.
- **Contract Status**: Proposed
- **Path Parameters**:
  - `id` *(required, string)*: Booking ID to cancel.
- **Responses**:
  - `200 OK`: Booking successfully marked cancelled.
  - `400 Bad Request`: Booking already past or non-cancellable.
  - `404 Not Found`: Booking ID not found.
```json
{
  "id": "bk-901",
  "status": "CANCELLED",
  "message": "Booking was successfully cancelled."
}
```

---

## 4. Facility Layout & Navigation Graph Endpoints

### 4.1 `GET /api/layout`
- **Purpose**: Retrieve high-level visual floor plan metadata and boundary dimensions for map rendering.
- **Contract Status**: Proposed
- **Query Parameters**:
  - `floor` *(optional, integer)*: Floor number.
- **Response**: `200 OK`
```json
{
  "facilityName": "SmartPark Academic Facility",
  "totalFloors": 3,
  "floors": [
    {
      "floorNumber": 1,
      "width": 1000.0,
      "height": 600.0,
      "totalSlots": 50,
      "entranceGate": "GATE_NORTH"
    }
  ]
}
```

---

### 4.2 `GET /api/layout/graph`
- **Purpose**: Retrieve complete topological graph data (nodes and edges) consumed by the Flutter client's custom Graph and Dijkstra pathfinding engine.
- **Contract Status**: Proposed
- **Query Parameters**:
  - `floor` *(optional, integer)*: Filter graph elements by floor.
- **Response**: `200 OK`
```json
{
  "floor": 1,
  "nodes": [
    {
      "id": "GATE_NORTH",
      "label": "North Gate Entrance",
      "x": 50.0,
      "y": 10.0,
      "floor": 1,
      "nodeType": "ENTRANCE"
    },
    {
      "id": "AISLE_1",
      "label": "Main Aisle Waypoint 1",
      "x": 50.0,
      "y": 100.0,
      "floor": 1,
      "nodeType": "AISLE"
    },
    {
      "id": "NODE_A101",
      "label": "Slot A-101 Waypoint",
      "x": 80.0,
      "y": 100.0,
      "floor": 1,
      "nodeType": "SLOT"
    }
  ],
  "edges": [
    {
      "id": "EDGE_01",
      "sourceNodeId": "GATE_NORTH",
      "targetNodeId": "AISLE_1",
      "weight": 90.0,
      "isBidirectional": true
    },
    {
      "id": "EDGE_02",
      "sourceNodeId": "AISLE_1",
      "targetNodeId": "NODE_A101",
      "weight": 30.0,
      "isBidirectional": true
    }
  ]
}
```

---

## 5. Summary of Proposed Contracts

| Method | Endpoint | Description | Primary Status Code |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/slots` | List all parking slots | `200 OK` |
| `GET` | `/api/slots/{id}` | Get specific slot details | `200 OK` / `404 Not Found` |
| `GET` | `/api/slots/available` | Query available slots across interval | `200 OK` |
| `POST` | `/api/bookings` | Create new reservation | `201 Created` / `409 Conflict` |
| `GET` | `/api/bookings` | List active/historical bookings | `200 OK` |
| `GET` | `/api/bookings/{id}` | Get specific booking details | `200 OK` / `404 Not Found` |
| `DELETE` | `/api/bookings/{id}` | Cancel reservation | `200 OK` / `404 Not Found` |
| `GET` | `/api/layout` | Get facility and floor dimensions | `200 OK` |
| `GET` | `/api/layout/graph` | Get topological navigation graph | `200 OK` |

