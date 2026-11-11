import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import 'parking_status_legend.dart';

/// Search input and status filter chips for the parking facility view.
///
/// // ponytail: standard TextField and ChoiceChips; compact local filter controls
class ParkingFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final SlotStatus? selectedStatus;
  final ValueChanged<SlotStatus?> onStatusChanged;
  final int matchingCount;
  final int totalCount;

  const ParkingFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.matchingCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by bay code (e.g. P01, P15)',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: 'Clear Search',
                    onPressed: onClearSearch,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChoiceChip(
                label: 'All ($totalCount)',
                isSelected: selectedStatus == null,
                onSelected: () => onStatusChanged(null),
              ),
              const SizedBox(width: 8),
              ...SlotStatus.values.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildChoiceChip(
                    label: status.displayName,
                    icon: status.icon,
                    iconColor: status.color,
                    isSelected: selectedStatus == status,
                    onSelected: () => onStatusChanged(status),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Result Count Feedback
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $matchingCount of $totalCount bays',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (selectedStatus != null || searchController.text.isNotEmpty)
              InkWell(
                onTap: () {
                  onClearSearch();
                  onStatusChanged(null);
                },
                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? Colors.white : iconColor)
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.primaryDark,
      ),
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : const Color(0xFFCBD5E1),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      showCheckmark: false,
    );
  }
}

