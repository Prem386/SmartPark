import '../../dsa/graph/parking_graph_factory.dart';
import '../../models/booking.dart';
import '../../models/parking_slot.dart';
import '../../services/booking_conflict_service.dart';
import '../../services/parking_navigation_service.dart';
import '../../services/parking_recommendation_service.dart';
import '../../services/parking_slot_service.dart';
import '../../services/smartpark_dsa_service.dart';

/// Centralized hardcoded local data source for the SmartPark prototype.
///
/// Follows:
/// - Facility layout: `docs/PARKING_FACILITY_DESIGN.md` (Revision 2.1.0)
/// - Facility graph: [ParkingGraphFactory]
/// - Capacity: Exactly 20 parking bays (Row A: P01-P10, Row B: P11-P20)
/// - Sample bookings: Realistic mix of statuses and valid time intervals
///
/// // ponytail: single hardcoded source of truth; no DB, no backend, resets on restart
class SmartParkLocalData {
  const SmartParkLocalData._();

  /// Reference date anchor used for sample bookings.
  static final DateTime referenceDate = DateTime(2026, 11, 11);

  /// Authoritative collection of 20 physical parking bays.
  ///
  /// Status distribution:
  /// - 12 Available (P01, P03, P05, P06, P08, P09, P11, P12, P14, P16, P17, P19)
  /// - 4 Occupied (P02, P07, P13, P18)
  /// - 2 Reserved (P04, P15)
  /// - 2 Maintenance (P10, P20)
  static List<ParkingSlot> createInitialSlots() {
    return <ParkingSlot>[
      // Row A (North, Y = 13.5m)
      ParkingSlot(
        id: 'P01',
        slotCode: 'P01',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(1),
        x: 6.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P02',
        slotCode: 'P02',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        navigationNodeId: ParkingGraphFactory.slotNodeId(2),
        x: 9.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P03',
        slotCode: 'P03',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(3),
        x: 12.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P04',
        slotCode: 'P04',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.reserved,
        navigationNodeId: ParkingGraphFactory.slotNodeId(4),
        x: 15.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P05',
        slotCode: 'P05',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(5),
        x: 18.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P06',
        slotCode: 'P06',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(6),
        x: 21.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P07',
        slotCode: 'P07',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        navigationNodeId: ParkingGraphFactory.slotNodeId(7),
        x: 24.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P08',
        slotCode: 'P08',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(8),
        x: 27.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P09',
        slotCode: 'P09',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(9),
        x: 30.0,
        y: 13.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P10',
        slotCode: 'P10',
        row: SlotRow.a,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.maintenance,
        navigationNodeId: ParkingGraphFactory.slotNodeId(10),
        x: 33.0,
        y: 13.5,
        isActive: false,
      ),

      // Row B (South, Y = 2.5m)
      ParkingSlot(
        id: 'P11',
        slotCode: 'P11',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(11),
        x: 6.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P12',
        slotCode: 'P12',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(12),
        x: 9.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P13',
        slotCode: 'P13',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        navigationNodeId: ParkingGraphFactory.slotNodeId(13),
        x: 12.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P14',
        slotCode: 'P14',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(14),
        x: 15.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P15',
        slotCode: 'P15',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.reserved,
        navigationNodeId: ParkingGraphFactory.slotNodeId(15),
        x: 18.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P16',
        slotCode: 'P16',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(16),
        x: 21.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P17',
        slotCode: 'P17',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(17),
        x: 24.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P18',
        slotCode: 'P18',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.occupied,
        navigationNodeId: ParkingGraphFactory.slotNodeId(18),
        x: 27.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P19',
        slotCode: 'P19',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.available,
        navigationNodeId: ParkingGraphFactory.slotNodeId(19),
        x: 30.0,
        y: 2.5,
        isActive: true,
      ),
      ParkingSlot(
        id: 'P20',
        slotCode: 'P20',
        row: SlotRow.b,
        floorNumber: 1,
        slotType: SlotType.standard,
        status: SlotStatus.maintenance,
        navigationNodeId: ParkingGraphFactory.slotNodeId(20),
        x: 33.0,
        y: 2.5,
        isActive: false,
      ),
    ];
  }

  /// Initial sample bookings demonstrating all 4 supported lifecycle statuses.
  ///
  /// Statuses:
  /// - `confirmed` (blocking): B01 on P04 (14:00 - 16:00)
  /// - `active` (blocking): B02 on P15 (10:00 - 12:00)
  /// - `completed` (non-blocking): B03 on P01 (08:00 - 09:30)
  /// - `cancelled` (non-blocking): B04 on P03 (13:00 - 15:00)
  static List<Booking> createInitialBookings() {
    return <Booking>[
      Booking(
        id: 'B01',
        slotId: 'P04',
        startTime: DateTime(2026, 11, 11, 14, 0),
        endTime: DateTime(2026, 11, 11, 16, 0),
        status: BookingStatus.confirmed,
        userId: 'USER_101',
        vehicleNumber: 'KA-01-AB-1001',
        createdAt: DateTime(2026, 11, 11, 8, 30),
      ),
      Booking(
        id: 'B02',
        slotId: 'P15',
        startTime: DateTime(2026, 11, 11, 10, 0),
        endTime: DateTime(2026, 11, 11, 12, 0),
        status: BookingStatus.active,
        userId: 'USER_102',
        vehicleNumber: 'KA-02-CD-2002',
        createdAt: DateTime(2026, 11, 11, 9, 0),
      ),
      Booking(
        id: 'B03',
        slotId: 'P01',
        startTime: DateTime(2026, 11, 11, 8, 0),
        endTime: DateTime(2026, 11, 11, 9, 30),
        status: BookingStatus.completed,
        userId: 'USER_103',
        vehicleNumber: 'KA-03-EF-3003',
        createdAt: DateTime(2026, 11, 10, 20, 0),
      ),
      Booking(
        id: 'B04',
        slotId: 'P03',
        startTime: DateTime(2026, 11, 11, 13, 0),
        endTime: DateTime(2026, 11, 11, 15, 0),
        status: BookingStatus.cancelled,
        userId: 'USER_104',
        vehicleNumber: 'KA-04-GH-4004',
        createdAt: DateTime(2026, 11, 11, 7, 0),
      ),
    ];
  }

  /// Initializes and returns the cohesive [SmartParkDsaService] populated with local data.
  static SmartParkDsaService initializeServices() {
    // 1. Initialize slot registry with 20 bays
    final slotService = ParkingSlotService(createInitialSlots());

    // 2. Initialize booking conflict service with sample bookings
    final bookingService = BookingConflictService(createInitialBookings());

    // 3. Initialize facility navigation service with authoritative graph
    final navigationService = ParkingNavigationService(
      graph: ParkingGraphFactory.createFacilityGraph(),
    );

    // 4. Initialize recommendation service wired to slot & navigation services
    final recommendationService = ParkingRecommendationService(
      slotService: slotService,
      navigationService: navigationService,
    );

    // 5. Build facade
    return SmartParkDsaService(
      slotService: slotService,
      bookingService: bookingService,
      navigationService: navigationService,
      recommendationService: recommendationService,
    );
  }
}

