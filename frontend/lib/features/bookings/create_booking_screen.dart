import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/smartpark_local_data.dart';
import '../../models/booking.dart';
import '../../models/parking_slot.dart';
import '../../services/smartpark_controller.dart';
import '../../widgets/smartpark_scope.dart';
import 'widgets/booking_time_selector.dart';

/// Screen allowing users to create a new parking reservation with real-time
/// AVL-Augmented Interval Tree conflict detection.
///
/// // ponytail: stateful form directly querying BookingConflictService; zero external packages
class CreateBookingScreen extends StatefulWidget {
  /// Optional slot code pre-selected from facility inspection.
  final String? initialSlotCode;

  /// Optional initial reservation date (defaults to [SmartParkLocalData.referenceDate]).
  final DateTime? initialDate;

  /// Optional time provider for deterministic testing of past-time validation.
  final DateTime Function()? currentTimeProvider;

  const CreateBookingScreen({
    super.key,
    this.initialSlotCode,
    this.initialDate,
    this.currentTimeProvider,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  String? _selectedSlotCode;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSlotCode = widget.initialSlotCode;
    // Anchor to initial date or facility demonstration reference date
    _selectedDate = widget.initialDate ?? SmartParkLocalData.referenceDate;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  DateTime _now() {
    if (widget.currentTimeProvider != null) {
      return widget.currentTimeProvider!();
    }
    final systemNow = DateTime.now();
    // When the selected date is on the facility demonstration reference date,
    // anchor the baseline comparison to 08:00 on the reference date so that
    // demonstration sample bookings and conflict detection remain functional
    // regardless of host device system clock.
    if (_selectedDate != null &&
        _selectedDate!.year == SmartParkLocalData.referenceDate.year &&
        _selectedDate!.month == SmartParkLocalData.referenceDate.month &&
        _selectedDate!.day == SmartParkLocalData.referenceDate.day) {
      return DateTime(
        SmartParkLocalData.referenceDate.year,
        SmartParkLocalData.referenceDate.month,
        SmartParkLocalData.referenceDate.day,
        8,
        0,
      );
    }
    return systemNow;
  }

  DateTime? get _startDateTime {
    if (_selectedDate == null || _startTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
  }

  DateTime? get _endDateTime {
    if (_selectedDate == null || _endTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
  }

  Duration? get _duration {
    final start = _startDateTime;
    final end = _endDateTime;
    if (start == null || end == null || !end.isAfter(start)) return null;
    return end.difference(start);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  void _onSlotSelected(String? slotCode, SmartParkController controller) {
    setState(() {
      _selectedSlotCode = slotCode;
    });
  }

  Future<void> _submitBooking(SmartParkController controller) async {
    if (_isSubmitting) return;

    // Validate form inputs
    if (_selectedSlotCode == null || _selectedSlotCode!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a parking slot.')),
      );
      return;
    }

    final slot = controller.slotService.getSlot(_selectedSlotCode!);
    if (slot == null ||
        !slot.isActive ||
        slot.status == SlotStatus.maintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Slot $_selectedSlotCode cannot be booked because it is under maintenance or inactive.',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a booking date.')),
      );
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time.')),
      );
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end time.')),
      );
      return;
    }

    final start = _startDateTime!;
    final end = _endDateTime!;

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a valid end time later than start time.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (start.isBefore(_now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking start time cannot be in the past.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Revalidate conflict immediately prior to insertion
    final conflicting = controller.bookingService.getConflictingBookings(
      _selectedSlotCode!,
      start,
      end,
    );
    if (conflicting.isNotEmpty) {
      final conflict = conflicting.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This slot is already booked during the selected time '
            '(${conflict.id}: ${_formatTime(conflict.startTime)} – ${_formatTime(conflict.endTime)}).',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newId = controller.generateNextBookingId();
      final newBooking = Booking(
        id: newId,
        slotId: _selectedSlotCode!,
        startTime: start,
        endTime: end,
        status: BookingStatus.confirmed,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim().isEmpty
            ? null
            : _vehicleNumberController.text.trim(),
        createdAt: _now(),
      );

      controller.bookSlot(newBooking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking confirmed successfully! Bay ${newBooking.slotId} reserved ($newId).',
            ),
            backgroundColor: AppTheme.statusAvailable,
          ),
        );
        Navigator.of(context).pop(newBooking);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = SmartParkScope.of(context);
    final allSlots = controller.slotService.getAllSlots();

    // Conflict evaluation
    final start = _startDateTime;
    final end = _endDateTime;
    final slotCode = _selectedSlotCode;
    final slot = slotCode != null
        ? controller.slotService.getSlot(slotCode)
        : null;

    final isSlotInactiveOrMaintenance =
        slot != null &&
        (!slot.isActive || slot.status == SlotStatus.maintenance);

    final isTimeOrderInvalid =
        start != null && end != null && !end.isAfter(start);
    final isStartTimePast = start != null && start.isBefore(_now());

    List<Booking> conflicts = [];
    bool hasIntervalConflict = false;

    if (slotCode != null &&
        start != null &&
        end != null &&
        !isTimeOrderInvalid &&
        !isStartTimePast &&
        !isSlotInactiveOrMaintenance) {
      conflicts = controller.bookingService.getConflictingBookings(
        slotCode,
        start,
        end,
      );
      hasIntervalConflict = conflicts.isNotEmpty;
    }

    final isFormReady =
        slotCode != null &&
        start != null &&
        end != null &&
        !isTimeOrderInvalid &&
        !isStartTimePast &&
        !isSlotInactiveOrMaintenance &&
        !hasIntervalConflict &&
        !_isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Reservation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Parking Slot Selection
                _buildSectionHeader(
                  title: '1. Select Parking Slot',
                  subtitle: 'Choose an operational parking bay for reservation',
                ),
                const SizedBox(height: 8),
                _buildSlotSelector(controller, allSlots),
                const SizedBox(height: 16),

                // Section 2: Date & Time Selection
                _buildSectionHeader(
                  title: '2. Select Date & Time',
                  subtitle: 'Intervals use half-open semantics [start, end)',
                ),
                const SizedBox(height: 8),
                BookingTimeSelector(
                  selectedDate: _selectedDate,
                  startTime: _startTime,
                  endTime: _endTime,
                  currentTimeProvider: widget.currentTimeProvider,
                  onDateChanged: (d) => setState(() => _selectedDate = d),
                  onStartTimeChanged: (t) => setState(() => _startTime = t),
                  onEndTimeChanged: (t) => setState(() => _endTime = t),
                ),
                const SizedBox(height: 16),

                // Section 3: Real-Time Conflict Detection Feedback
                _buildSectionHeader(
                  title: '3. Availability & Conflict Check',
                  subtitle:
                      'Evaluated in real time via custom AVL Interval Tree',
                ),
                const SizedBox(height: 8),
                _buildConflictFeedback(
                  slot: slot,
                  isSlotInactiveOrMaintenance: isSlotInactiveOrMaintenance,
                  isTimeOrderInvalid: isTimeOrderInvalid,
                  isStartTimePast: isStartTimePast,
                  hasIntervalConflict: hasIntervalConflict,
                  conflicts: conflicts,
                  start: start,
                  end: end,
                ),
                const SizedBox(height: 16),

                // Section 4: Optional Metadata (Customer & Vehicle)
                _buildSectionHeader(
                  title: '4. Vehicle & User Details (Optional)',
                  subtitle: 'Associate reservation with driver or vehicle',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'Customer / User ID',
                    hintText: 'e.g. USER_105',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Registration Number',
                    hintText: 'e.g. KA-05-MN-5005',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Section 5: Review & Confirmation
                if (slotCode != null &&
                    start != null &&
                    end != null &&
                    !isTimeOrderInvalid) ...[
                  _buildReviewCard(slotCode, start, end),
                  const SizedBox(height: 16),
                ],

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isFormReady
                        ? () => _submitBooking(controller)
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting
                          ? 'Confirming Reservation...'
                          : 'Confirm Booking',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSlotSelector(
    SmartParkController controller,
    List<ParkingSlot> allSlots,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSlotCode,
      decoration: const InputDecoration(
        labelText: 'Parking Bay',
        prefixIcon: Icon(Icons.local_parking),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select a parking bay'),
      items: allSlots.map((s) {
        final isMaintenance = !s.isActive || s.status == SlotStatus.maintenance;
        final statusDesc = isMaintenance
            ? 'Maintenance'
            : (s.status == SlotStatus.occupied
                  ? 'Occupied'
                  : (s.status == SlotStatus.reserved
                        ? 'Reserved'
                        : 'Available'));

        return DropdownMenuItem<String>(
          value: s.slotCode,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.slotCode} (${s.row.displayName})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isMaintenance ? Colors.grey : AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: isMaintenance
                      ? Colors.red.shade400
                      : (s.status == SlotStatus.available
                            ? AppTheme.statusAvailable
                            : Colors.amber.shade800),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) => _onSlotSelected(val, controller),
    );
  }

  Widget _buildConflictFeedback({
    required ParkingSlot? slot,
    required bool isSlotInactiveOrMaintenance,
    required bool isTimeOrderInvalid,
    required bool isStartTimePast,
    required bool hasIntervalConflict,
    required List<Booking> conflicts,
    required DateTime? start,
    required DateTime? end,
  }) {
    if (slot == null && start == null) {
      return _buildFeedbackBanner(
        message:
            'Select a parking slot and time interval to evaluate availability.',
        color: const Color(0xFFF1F5F9),
        textColor: Colors.grey.shade700,
        icon: Icons.info_outline,
      );
    }

    if (isSlotInactiveOrMaintenance) {
      return _buildFeedbackBanner(
        message:
            'Slot ${slot!.slotCode} is inactive or under maintenance and cannot be booked.',
        color: const Color(0xFFFEF2F2),
        textColor: const Color(0xFFDC2626),
        icon: Icons.error_outline,
      );
    }

    if (isTimeOrderInvalid) {
      return _buildFeedbackBanner(
        message: 'Please select a valid end time later than start time.',
        color: const Color(0xFFFEF2F2),
        textColor: const Color(0xFFDC2626),
        icon: Icons.warning_amber_rounded,
      );
    }

    if (isStartTimePast) {
      return _buildFeedbackBanner(
        message: 'Booking start time cannot be in the past.',
        color: const Color(0xFFFEF2F2),
        textColor: const Color(0xFFDC2626),
        icon: Icons.access_time_filled,
      );
    }

    if (hasIntervalConflict) {
      final conflict = conflicts.first;
      return _buildFeedbackBanner(
        message:
            'This slot is already booked during the selected time.\n'
            'Conflict: Booking ${conflict.id} (${_formatTime(conflict.startTime)} – ${_formatTime(conflict.endTime)}).',
        color: const Color(0xFFFEF2F2),
        textColor: const Color(0xFFDC2626),
        icon: Icons.cancel,
      );
    }

    if (slot != null && start != null && end != null) {
      final durationStr = _duration != null
          ? ' (${_formatDuration(_duration!)})'
          : '';
      return _buildFeedbackBanner(
        message: 'This slot is available for the selected time$durationStr.',
        color: const Color(0xFFF0FDF4),
        textColor: const Color(0xFF16A34A),
        icon: Icons.check_circle,
      );
    }

    return _buildFeedbackBanner(
      message: 'Choose both start and end times to run conflict detection.',
      color: const Color(0xFFF1F5F9),
      textColor: Colors.grey.shade700,
      icon: Icons.info_outline,
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String slotCode, DateTime start, DateTime end) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservation Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Allocated Slot:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Bay $slotCode',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time Window:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '${_formatTime(start)} – ${_formatTime(end)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Duration:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  _duration != null ? _formatDuration(_duration!) : 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
