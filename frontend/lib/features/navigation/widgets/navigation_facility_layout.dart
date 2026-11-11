import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/parking_slot.dart';
import '../../../services/parking_navigation_service.dart';
import '../../parking/widgets/parking_slot_tile.dart';
import 'facility_route_painter.dart';

/// Interactive facility layout widget rendering the 38m x 16m single-floor layout
/// with active Dijkstra route visualization and direct bay selection.
///
/// Features:
/// - 31 facility vertices (1 Entrance, 10 Waypoints, 20 Bays)
/// - 30 traversable connections painted via [FacilityRoutePainter]
/// - Active shortest path highlighted in primary blue with directional travel arrows
/// - Visual start/finish indicators
/// - Direct tap selection for bays P01-P20
///
/// // ponytail: composited Stack with FacilityRoutePainter; reuses ParkingSlotTile; 0 external map dependencies
class NavigationFacilityLayout extends StatelessWidget {
  /// All 10 Row A bays (P01 to P10).
  final List<ParkingSlot> rowASlots;

  /// All 10 Row B bays (P11 to P20).
  final List<ParkingSlot> rowBSlots;

  /// Currently selected destination parking bay code (e.g. 'P04'), or null.
  final String? selectedSlotCode;

  /// Active computed Dijkstra shortest path route, or null.
  final NavigationRoute? activeRoute;

  /// Callback dispatched when any parking bay is tapped.
  final ValueChanged<String> onSlotSelected;

  const NavigationFacilityLayout({
    super.key,
    required this.rowASlots,
    required this.rowBSlots,
    required this.selectedSlotCode,
    required this.activeRoute,
    required this.onSlotSelected,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row A Header & Map Legend
            _buildMapHeader(context),
            const SizedBox(height: 8),

            // Horizontally Scrollable Interactive Map
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: FacilityRoutePainter.diagramWidth,
                height: FacilityRoutePainter.diagramHeight,
                child: Stack(
                  children: [
                    // Layer 1: Vector rendering of the 30 connections and Dijkstra shortest route
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FacilityRoutePainter(route: activeRoute),
                      ),
                    ),

                    // Layer 2: Interactive Nodes & Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // West Entrance Column
                        _buildWestEntranceColumn(),
                        const SizedBox(width: 16),

                        // 10 Opposing Bay Columns (P01-P10 North, W01-W10 Aisle, P11-P20 South)
                        for (int i = 0; i < 10; i++) ...[
                          _buildBayPairColumn(i),
                          if (i < 9) const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Row B Header
            _buildRowHeader(
              title: 'ROW B (SOUTH)',
              subtitle: 'Bays P11 – P20 • Y = 2.5m',
              icon: Icons.south,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRowHeader(
          title: 'ROW A (NORTH)',
          subtitle: 'Bays P01 – P10 • Y = 13.5m',
          icon: Icons.north,
        ),
        const SizedBox(height: 6),
        // Mini visual legend
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildLegendItem(
              color: const Color(0xFFCBD5E1),
              label: 'Facility Link',
              isLine: true,
            ),
            _buildLegendItem(
              color: AppTheme.primaryBlue,
              label: 'Calculated Route',
              isLine: true,
            ),
            _buildLegendItem(
              color: const Color(0xFF10B981),
              label: 'Entrance (Start)',
            ),
            _buildLegendItem(
              color: AppTheme.primaryBlue,
              label: 'Destination',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isLine = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRowHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.primaryBlue),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWestEntranceColumn() {
    final isRouteActive = activeRoute != null && activeRoute!.hasPath;

    return Column(
      children: [
        // Upper wall buffer
        Container(
          width: 82,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              'FACILITY\nWALL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Central Aisle Entrance Gate
        Container(
          width: 82,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: isRouteActive ? const Color(0xFF059669) : AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (isRouteActive ? const Color(0xFF059669) : AppTheme.primaryBlue)
                    .withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRouteActive ? Icons.play_circle_fill : Icons.login,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isRouteActive ? 'START' : 'ENTRY',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'X=2.0m',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isRouteActive
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Lower wall buffer
        Container(
          width: 82,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              'FACILITY\nWALL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBayPairColumn(int index) {
    final slotA = index < rowASlots.length ? rowASlots[index] : null;
    final slotB = index < rowBSlots.length ? rowBSlots[index] : null;

    final waypointNum = (index + 1).toString().padLeft(2, '0');
    final waypointNodeId = 'NODE_W$waypointNum';
    final waypointX = (6.0 + (index * 3.0)).toStringAsFixed(1);

    // Check if this waypoint is traversed by the active route
    final isWaypointOnRoute =
        activeRoute != null && activeRoute!.hasPath && activeRoute!.path.contains(waypointNodeId);
    final routeStepIndex = isWaypointOnRoute
        ? activeRoute!.path.indexOf(waypointNodeId)
        : -1;

    return Column(
      children: [
        // Row A Bay (North)
        if (slotA != null)
          _buildInteractiveSlotTile(slotA)
        else
          const SizedBox(width: 86, height: 104),
        const SizedBox(height: 20),

        // Central Driving Aisle Waypoint Section
        _buildWaypointWidget(
          waypointNum: waypointNum,
          waypointX: waypointX,
          isOnRoute: isWaypointOnRoute,
          stepIndex: routeStepIndex,
        ),
        const SizedBox(height: 20),

        // Row B Bay (South)
        if (slotB != null)
          _buildInteractiveSlotTile(slotB)
        else
          const SizedBox(width: 86, height: 104),
      ],
    );
  }

  Widget _buildInteractiveSlotTile(ParkingSlot slot) {
    final isSelected = selectedSlotCode == slot.slotCode;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ParkingSlotTile(
          slot: slot,
          isSelected: isSelected,
          isDimmed: false,
          onTap: () => onSlotSelected(slot.slotCode),
        ),
        if (isSelected)
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Text(
                  'TARGET',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWaypointWidget({
    required String waypointNum,
    required String waypointX,
    required bool isOnRoute,
    required int stepIndex,
  }) {
    return Container(
      width: 86,
      height: 52,
      decoration: BoxDecoration(
        color: isOnRoute ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOnRoute ? AppTheme.primaryBlue : Colors.amber.shade300,
          width: isOnRoute ? 2.0 : 1.5,
        ),
        boxShadow: isOnRoute
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOnRoute) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '#$stepIndex',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                'W$waypointNum',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isOnRoute ? AppTheme.primaryBlue : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'X=${waypointX}m',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isOnRoute ? AppTheme.primaryBlue : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
