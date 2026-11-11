import 'package:flutter/foundation.dart';

import '../data/local/smartpark_local_data.dart';
import '../models/booking.dart';
import '../models/parking_slot.dart';
import 'booking_conflict_service.dart';
import 'parking_navigation_service.dart';
import 'parking_recommendation_service.dart';
import 'parking_slot_service.dart';
import 'smartpark_dsa_service.dart';

/// Central reactive state controller for the SmartPark application.
///
/// Wraps [SmartParkDsaService] and exposes state to UI via [ChangeNotifier].
/// Uses native Flutter primitives (ChangeNotifier + InheritedNotifier)
/// for zero external dependencies.
///
/// // ponytail: standard library / native ChangeNotifier; no Riverpod, no Bloc, no third-party bloat
class SmartParkController extends ChangeNotifier {
  SmartParkDsaService _dsaService;

  SmartParkController({SmartParkDsaService? dsaService})
      : _dsaService = dsaService ?? SmartParkLocalData.initializeServices();

  /// The underlying unified DSA facade.
  SmartParkDsaService get dsaService => _dsaService;

  /// Underlying slot registry service.
  ParkingSlotService get slotService => _dsaService.slotService;

  /// Underlying booking conflict service.
  BookingConflictService get bookingService => _dsaService.bookingService;

  /// Underlying facility navigation service.
  ParkingNavigationService get navigationService => _dsaService.navigationService;

  /// Underlying recommendation priority service.
  ParkingRecommendationService get recommendationService =>
      _dsaService.recommendationService;

  // --- Dynamic Dashboard Metrics ---

  /// Total number of parking slots in the facility.
  int get totalSlots => slotService.slotCount;

  /// Number of active and immediately available slots.
  int get availableSlots =>
      slotService.getAllSlots().where((s) => s.isAvailable).length;

  /// Number of currently occupied slots.
  int get occupiedSlots =>
      slotService.getAllSlots().where((s) => s.status == SlotStatus.occupied).length;

  /// Number of currently reserved slots.
  int get reservedSlots =>
      slotService.getAllSlots().where((s) => s.status == SlotStatus.reserved).length;

  /// Number of slots under maintenance or inactive.
  int get maintenanceSlots => slotService
      .getAllSlots()
      .where((s) => s.status == SlotStatus.maintenance || !s.isActive)
      .length;

  // --- Reactive Mutations ---

  /// Updates the status of an existing slot and notifies UI listeners.
  void updateSlotStatus(
    String slotCode,
    SlotStatus status, {
    bool? isActive,
  }) {
    final existing = slotService.getSlot(slotCode);
    if (existing == null) {
      throw ArgumentError('Slot $slotCode not found.');
    }
    final updated = existing.copyWith(
      status: status,
      isActive: isActive ?? (status != SlotStatus.maintenance),
    );
    slotService.updateSlot(updated);
    notifyListeners();
  }

  /// Reserves a slot with [booking] after conflict check and notifies UI listeners.
  void bookSlot(Booking booking) {
    _dsaService.bookSlot(booking);
    // Reflect reservation status on slot if available
    final slot = slotService.getSlot(booking.slotId);
    if (slot != null && slot.status == SlotStatus.available) {
      slotService.updateSlot(slot.copyWith(status: SlotStatus.reserved));
    }
    notifyListeners();
  }

  /// Returns all bookings currently indexed in the application state.
  List<Booking> get allBookings => _dsaService.getAllBookings();

  /// Cancels an existing booking, updates the reservation index, and notifies UI listeners.
  Booking cancelBooking(String bookingId) {
    final cancelled = _dsaService.cancelBooking(bookingId);

    // If slot was reserved and has no remaining blocking bookings, restore to available
    final slot = slotService.getSlot(cancelled.slotId);
    if (slot != null && slot.status == SlotStatus.reserved) {
      final hasOtherBlocking = bookingService.getAllBookings().any(
            (b) =>
                b.slotId == cancelled.slotId &&
                BookingConflictService.isBlockingStatus(b.status),
          );
      if (!hasOtherBlocking) {
        slotService.updateSlot(slot.copyWith(status: SlotStatus.available));
      }
    }

    notifyListeners();
    return cancelled;
  }

  /// Generates the next sequential booking identifier (e.g. 'B05').
  String generateNextBookingId() {
    int maxId = 0;
    for (final booking in bookingService.getAllBookings()) {
      final match = RegExp(r'^B(\d+)$').firstMatch(booking.id);
      if (match != null) {
        final val = int.tryParse(match.group(1)!);
        if (val != null && val > maxId) {
          maxId = val;
        }
      }
    }
    return 'B${(maxId + 1).toString().padLeft(2, '0')}';
  }

  /// Resets in-memory application state back to clean hardcoded initial data.
  void resetToDefaults() {
    _dsaService = SmartParkLocalData.initializeServices();
    notifyListeners();
  }
}

