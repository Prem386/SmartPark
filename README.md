# SmartPark – Intelligent Parking Management System Using Data Structures and Algorithms

SmartPark is a student-level academic project designed to demonstrate the practical application of four foundational Data Structures and Algorithms (DSA) within an intelligent parking management system.

---

## Project Objectives

The primary goal of SmartPark is to demonstrate how algorithmic concepts solve real-world problems in parking allocation, conflict detection, path navigation, and fast data retrieval:

1. **Intelligent Slot Recommendation**: Efficiently assign optimal parking spots based on proximity and priority.
2. **Conflict-Free Reservation**: Prevent overlapping bookings across parking time intervals.
3. **Optimized Navigation**: Compute shortest walking or driving paths to allocated slots.
4. **Fast Slot Lookup**: Provide instant retrieval and indexing of parking slots and vehicle states.

---

## Four Core DSA Requirements

All four algorithms will be implemented manually in Dart:

1. **Custom Min-Heap**: Intelligent parking slot recommendations (prioritizing slots by distance/cost criteria).
2. **Custom Interval Tree**: Conflict detection to prevent overlapping parking reservations over time intervals.
3. **Graph + Dijkstra's Algorithm**: Finding the shortest path from entrance/current location to assigned parking slots.
4. **Custom HashMap**: Efficient parking slot searching, indexing, and constant-time retrieval.

---

## Technology Stack

### Frontend (Current)
- **Framework**: Flutter
- **Language**: Dart
- **Initial Target Platform**: Android
- **Package Name**: `smartpark_app`

### Backend (Pending Initialization)
- **Language**: Java
- **Framework**: Spring Boot
- **Communication**: REST APIs (JSON)
- *Status: Not yet initialized.*

### Database (Pending Finalization)
- *Status: Under consideration (MySQL, PostgreSQL, or SQLite). Pending final decision.*

---

## Project Structure

```text
SmartPark/
│
├── frontend/
│   ├── android/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── other standard Flutter files
│
├── docs/
│
├── .gitignore
└── README.md
```

---

## Development Status

- **Initialization**: Flutter project scaffolded directly under `frontend/` with package `smartpark_app`.
- **Backend & Database**: Pending initialization and finalization; no backend code or database schemas created yet.
- **Application Modules & DSA**: No application features (dashboards, reservation screens, DSA code) have been implemented yet; design will proceed collaboratively before implementation.

