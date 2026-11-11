import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Reusable widget for selecting booking date, start time, and end time.
///
/// // ponytail: standard Flutter showDatePicker & showTimePicker; no external pickers
class BookingTimeSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  const BookingTimeSelector({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(TimeOfDay? tod) {
    if (tod == null) return '--:--';
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate ?? now;
    final first = now.subtract(const Duration(days: 30));
    final last = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final initial = startTime ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onStartTimeChanged(picked);
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final initial = endTime ??
        (startTime != null
            ? TimeOfDay(hour: (startTime!.hour + 1) % 24, minute: startTime!.minute)
            : const TimeOfDay(hour: 11, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onEndTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selector Row
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: const Icon(Icons.calendar_month, color: AppTheme.primaryBlue),
            title: const Text(
              'Reservation Date',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            subtitle: Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            trailing: OutlinedButton(
              onPressed: () => _pickDate(context),
              child: const Text('Change Date'),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Time Range Selectors (Start & End)
        Row(
          children: [
            Expanded(
              child: _TimeCard(
                label: 'Start Time',
                timeText: _formatTime(startTime),
                icon: Icons.play_arrow_outlined,
                onTap: () => _pickStartTime(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeCard(
                label: 'End Time',
                timeText: _formatTime(endTime),
                icon: Icons.stop_outlined,
                onTap: () => _pickEndTime(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String timeText;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeCard({
    required this.label,
    required this.timeText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to pick',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

