import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../dsa/graph/weighted_graph.dart';
import '../../../models/parking_slot.dart';
import '../../../services/parking_navigation_service.dart';

/// Card presenting calculated Dijkstra shortest path metrics, turn-by-turn
/// waypoint sequence, and navigation controls.
///
/// // ponytail: clean summary metrics + breadcrumb list; direct distance readout from NavigationRoute
class NavigationRouteCard extends StatelessWidget {
  /// The active calculated route, or null if no destination is selected.
  final NavigationRoute? route;

  /// Physical slot object for the destination, or null if unknown.
  final ParkingSlot? destinationSlot;

  /// Selected slot code string.
  final String? selectedSlotCode;

  /// Underlying facility graph for resolving edge segment distances and labels.
  final WeightedGraph graph;

  /// Callback when user clears the route.
  final VoidCallback onClearRoute;

  const NavigationRouteCard({
    super.key,
    required this.route,
    required this.destinationSlot,
    required this.selectedSlotCode,
    required this.graph,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSlotCode == null) {
      return _buildEmptyState(context);
    }

    final activeRoute = route;
    if (activeRoute == null) {
      return _buildInvalidState(context);
    }

    if (!activeRoute.hasPath) {
      return _buildUnreachableState(context);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Route Destination & Clear Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.alt_route,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination: Bay ${destinationSlot?.slotCode ?? selectedSlotCode}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              destinationSlot != null
                                  ? '${destinationSlot!.row.displayName} • Floor ${destinationSlot!.floorNumber}'
                                  : 'Calculated Shortest Path',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onClearRoute,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Metrics Row
            _buildMetricsRow(context, activeRoute),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Ordered Turn-by-Turn Waypoint Sequence
            Text(
              'Waypoint Navigation Sequence (${activeRoute.path.length} vertices)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            _buildWaypointSequence(context, activeRoute),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, NavigationRoute route) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            label: 'Total Distance',
            value: '${route.distance.toStringAsFixed(1)}m',
            icon: Icons.straighten,
            color: AppTheme.primaryBlue,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildMetricItem(
            label: 'Total Hops',
            value: '${route.path.length > 1 ? route.path.length - 1 : 0} links',
            icon: Icons.timeline,
            color: const Color(0xFF0284C7),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildMetricItem(
            label: 'Origin Gate',
            value: 'Entrance (2.0m)',
            icon: Icons.login,
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointSequence(BuildContext context, NavigationRoute route) {
    return Column(
      children: [
        for (int i = 0; i < route.path.length; i++) ...[
          _buildStepRow(i, route.path[i], route),
          if (i < route.path.length - 1)
            _buildConnectorIndicator(i, route),
        ],
      ],
    );
  }

  Widget _buildStepRow(int index, String nodeId, NavigationRoute route) {
    final isOrigin = index == 0;
    final isDestination = index == route.path.length - 1;

    final vertex = graph.getVertex(nodeId);
    final label = vertex?.label ?? nodeId;

    Color stepColor;
    IconData stepIcon;

    if (isOrigin) {
      stepColor = const Color(0xFF059669);
      stepIcon = Icons.play_circle_fill;
    } else if (isDestination) {
      stepColor = AppTheme.primaryBlue;
      stepIcon = Icons.location_on;
    } else {
      stepColor = const Color(0xFF0284C7);
      stepIcon = Icons.adjust;
    }

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: stepColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 1.5),
          ),
          child: Center(
            child: Icon(stepIcon, size: 13, color: stepColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOrigin
                    ? 'Start at $label'
                    : isDestination
                        ? 'Arrive at $label'
                        : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isOrigin || isDestination) ? FontWeight.bold : FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              if (vertex?.x != null && vertex?.y != null)
                Text(
                  'Facility Coordinates: (${vertex!.x!.toStringAsFixed(1)}m, ${vertex.y!.toStringAsFixed(1)}m)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Node $nodeId',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorIndicator(int fromIndex, NavigationRoute route) {
    final fromNode = route.path[fromIndex];
    final toNode = route.path[fromIndex + 1];

    // Query segment distance directly from authoritative graph
    double? segmentWeight;
    try {
      final adjacent = graph.getAdjacentEdges(fromNode);
      for (final edge in adjacent) {
        if (edge.targetNodeId == toNode) {
          segmentWeight = edge.weight;
          break;
        }
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(left: 11),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 18,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 14),
          if (segmentWeight != null)
            Text(
              '↓ Traversing segment: ${segmentWeight.toStringAsFixed(1)}m',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.touch_app, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No Destination Selected',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a parking bay from the layout above or use the selector to calculate the shortest path from the entrance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidState(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFECACA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invalid Destination: $selectedSlotCode',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'The requested bay does not exist in the authoritative facility graph.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onClearRoute,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreachableState(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bay $selectedSlotCode Unreachable',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dijkstra pathfinding found no traversable path from the facility entrance to this bay.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onClearRoute,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

