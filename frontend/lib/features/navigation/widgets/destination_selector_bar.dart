import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import '../../parking/widgets/parking_status_legend.dart';

/// Destination selector bar providing dropdown selection and quick access chips
/// for parking bays P01 to P20.
///
/// // ponytail: standard DropdownButtonFormField + Wrap chips; 0 complex pickers
class DestinationSelectorBar extends StatelessWidget {
  /// All 20 parking slots in the facility.
  final List<ParkingSlot> allSlots;

  /// Currently selected slot code, or null.
  final String? selectedSlotCode;

  /// Callback when a new slot code is selected.
  final ValueChanged<String?> onSlotChanged;

  /// Optional recommended slot code for quick shortcut.
  final String? recommendedSlotCode;

  const DestinationSelectorBar({
    super.key,
    required this.allSlots,
    required this.selectedSlotCode,
    required this.onSlotChanged,
    this.recommendedSlotCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row label & quick hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.directions_car, size: 16, color: AppTheme.primaryBlue),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Select Destination Bay',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedSlotCode != null)
                  TextButton.icon(
                    onPressed: () => onSlotChanged(null),
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Dropdown selector
            DropdownButtonFormField<String>(
              key: ValueKey('destination_slot_dropdown_${selectedSlotCode ?? "none"}'),
              initialValue: selectedSlotCode,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                hintText: 'Choose a parking bay (P01 – P20)...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.local_parking, color: AppTheme.primaryBlue, size: 20),
              ),
              items: allSlots.map((slot) {
                return DropdownMenuItem<String>(
                  key: Key('dropdown_item_${slot.slotCode}'),
                  value: slot.slotCode,
                  child: Row(
                    children: [
                      Text(
                        'Bay ${slot.slotCode}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '(${slot.row.displayName} • ${slot.status.displayName})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onSlotChanged,
            ),
            const SizedBox(height: 10),

            // Quick select shortcut chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Quick:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (recommendedSlotCode != null)
                  ActionChip(
                    avatar: const Icon(Icons.star, size: 12, color: Colors.amber),
                    label: Text(
                      'Optimal: $recommendedSlotCode',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSlotChanged(recommendedSlotCode),
                  ),
                _buildQuickChip('P01', 'P01'),
                _buildQuickChip('P04', 'P04'),
                _buildQuickChip('P10', 'P10'),
                _buildQuickChip('P11', 'P11'),
                _buildQuickChip('P15', 'P15'),
                _buildQuickChip('P20', 'P20'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String code) {
    final isSelected = selectedSlotCode == code;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onSlotChanged(code),
    );
  }
}
