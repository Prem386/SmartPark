import '../dsa/min_heap/parking_slot_candidate.dart';
import '../models/booking.dart';
import '../models/parking_slot.dart';
import 'booking_conflict_service.dart';
import 'parking_navigation_service.dart';
import 'parking_recommendation_service.dart';
import 'parking_slot_service.dart';

/// Lightweight facade / orchestrator unifying all four SmartPark DSA services.
///
/// Coordinates:
/// - [ParkingSlotService] (Custom HashMap)
/// - [BookingConflictService] (Custom Interval Tree)
/// - [ParkingNavigationService] (Custom Weighted Graph + Dijkstra)
/// - [ParkingRecommendationService] (Custom Min-Heap + Dijkstra)
///
/// // ponytail: pure coordination facade; zero framework dependencies, zero duplicate state
class SmartParkDsaService {
  final ParkingSlotService slotService;
  final BookingConflictService bookingService;
  final ParkingNavigationService navigationService;
  final ParkingRecommendationService recommendationService;

  SmartParkDsaService._({
    required this.slotService,
    required this.bookingService,
    required this.navigationService,
    required this.recommendationService,
  });

  /// Creates a unified [SmartParkDsaService] with coordinated underlying services.
  ///
  /// Any omitted services are initialized with default standard configurations,
  /// with [recommendationService] automatically bound to [slotService] and [navigationService].
  factory SmartParkDsaService({
    ParkingSlotService? slotService,
    BookingConflictService? bookingService,
    ParkingNavigationService? navigationService,
    ParkingRecommendationService? recommendationService,
  }) {
    final resolvedSlotService = slotService ?? ParkingSlotService();
    final resolvedNavigationService =
        navigationService ?? ParkingNavigationService();
    final resolvedBookingService =
        bookingService ?? BookingConflictService();
    final resolvedRecommendationService = recommendationService ??
        ParkingRecommendationService(
          slotService: resolvedSlotService,
          navigationService: resolvedNavigationService,
        );

    return SmartParkDsaService._(
      slotService: resolvedSlotService,
      bookingService: resolvedBookingService,
      navigationService: resolvedNavigationService,
      recommendationService: resolvedRecommendationService,
    );
  }

  /// Bulk-registers a collection of parking slots into the facility.
  void registerSlots(Iterable<ParkingSlot> slots) {
    for (final slot in slots) {
      slotService.registerOrUpdate(slot);
    }
  }

  /// Finds a parking bay by its physical [slotCode] (e.g. 'P01').
  ParkingSlot? findSlot(String slotCode) {
    return slotService.getSlot(slotCode);
  }

  /// Retrieves optimal parking slot recommendations ranked by proximity to facility entrance.
  List<ParkingSlotCandidate> getRecommendations({int? limit}) {
    return recommendationService.getRecommendations(limit: limit);
  }

  /// Computes the shortest driving/walking path to a parking bay.
  ///
  /// Looks up [slotCode] in the registry to verify coordinates and attributes.
  NavigationRoute? findRouteToSlot(
    String slotCode, {
    String? fromNodeId,
  }) {
    final slot = slotService.getSlot(slotCode);
    if (slot != null) {
      return navigationService.getRouteToSlot(
        slot,
        fromNodeId: fromNodeId ?? navigationService.entranceNodeId,
      );
    }
    return navigationService.getRouteToSlotCode(
      slotCode,
      fromNodeId: fromNodeId ?? navigationService.entranceNodeId,
    );
  }

  /// Checks whether a prospective booking conflicts with existing reservations.
  bool checkBookingConflict(Booking booking) {
    return bookingService.isBookingInConflict(booking);
  }

  /// Checks whether a time window on [slotId] has conflicting reservations.
  bool checkTimeConflict(String slotId, DateTime startTime, DateTime endTime) {
    return bookingService.hasConflict(slotId, startTime, endTime);
  }

  /// Reserves a slot by adding [booking] after verifying absence of conflicts.
  ///
  /// Throws [BookingConflictException] if the slot is already booked for that window.
  void bookSlot(Booking booking) {
    bookingService.addBooking(booking);
  }
}

