import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/parking_navigation_service.dart';

/// Custom painter rendering the 30 physical connections and active Dijkstra shortest route.
///
/// Distinguishes:
/// - Normal facility connections (subtle slate lines)
/// - Calculated route edges (bold primary blue with directional travel arrows)
/// - Origin and destination terminal accents
///
/// // ponytail: direct canvas path rendering; deterministic coordinate math; 0 external vector packages
class FacilityRoutePainter extends CustomPainter {
  /// The active calculated route, or null if no route is active.
  final NavigationRoute? route;

  /// Total diagram width in logical pixels.
  static const double diagramWidth = 1102.0;

  /// Total diagram height in logical pixels.
  static const double diagramHeight = 300.0;

  /// Visual center Y of the gap between Row A bay tiles (bottom Y=104) and waypoints (top Y=124).
  static const double rowAGapCenterY = 114.0;

  /// Visual center Y of the gap between waypoints (bottom Y=176) and Row B bay tiles (top Y=196).
  static const double rowBGapCenterY = 186.0;

  const FacilityRoutePainter({this.route});

  /// Maps canonical graph vertex ID to canvas center coordinates.
  static Offset getNodeOffset(String nodeId) {
    if (nodeId == 'NODE_ENTRANCE') {
      return const Offset(41.0, 150.0);
    }

    final wMatch = RegExp(r'^NODE_W(\d+)$').firstMatch(nodeId);
    if (wMatch != null) {
      final idx = int.tryParse(wMatch.group(1)!);
      if (idx != null && idx >= 1 && idx <= 10) {
        return Offset(141.0 + (idx - 1) * 102.0, 150.0);
      }
    }

    final pMatch = RegExp(r'^NODE_P(\d+)$').firstMatch(nodeId);
    if (pMatch != null) {
      final num = int.tryParse(pMatch.group(1)!);
      if (num != null) {
        if (num >= 1 && num <= 10) {
          return Offset(141.0 + (num - 1) * 102.0, 52.0);
        } else if (num >= 11 && num <= 20) {
          return Offset(141.0 + (num - 11) * 102.0, 248.0);
        }
      }
    }

    return Offset.zero;
  }

  /// All 30 authoritative facility graph edges as undirected pairs.
  static const List<(String, String)> facilityEdges = [
    // Entrance to Waypoint 1 (4.0m)
    ('NODE_ENTRANCE', 'NODE_W01'),

    // 9 Aisle backbone segments (3.0m each)
    ('NODE_W01', 'NODE_W02'),
    ('NODE_W02', 'NODE_W03'),
    ('NODE_W03', 'NODE_W04'),
    ('NODE_W04', 'NODE_W05'),
    ('NODE_W05', 'NODE_W06'),
    ('NODE_W06', 'NODE_W07'),
    ('NODE_W07', 'NODE_W08'),
    ('NODE_W08', 'NODE_W09'),
    ('NODE_W09', 'NODE_W10'),

    // 10 Waypoint to Row A slot segments (5.5m each)
    ('NODE_W01', 'NODE_P01'),
    ('NODE_W02', 'NODE_P02'),
    ('NODE_W03', 'NODE_P03'),
    ('NODE_W04', 'NODE_P04'),
    ('NODE_W05', 'NODE_P05'),
    ('NODE_W06', 'NODE_P06'),
    ('NODE_W07', 'NODE_P07'),
    ('NODE_W08', 'NODE_P08'),
    ('NODE_W09', 'NODE_P09'),
    ('NODE_W10', 'NODE_P10'),

    // 10 Waypoint to Row B slot segments (5.5m each)
    ('NODE_W01', 'NODE_P11'),
    ('NODE_W02', 'NODE_P12'),
    ('NODE_W03', 'NODE_P13'),
    ('NODE_W04', 'NODE_P14'),
    ('NODE_W05', 'NODE_P15'),
    ('NODE_W06', 'NODE_P16'),
    ('NODE_W07', 'NODE_P17'),
    ('NODE_W08', 'NODE_P18'),
    ('NODE_W09', 'NODE_P19'),
    ('NODE_W10', 'NODE_P20'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final normalEdgePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routeEdgePaint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;

    // 1. Paint all 30 standard facility connections
    for (final edge in facilityEdges) {
      final p1 = getNodeOffset(edge.$1);
      final p2 = getNodeOffset(edge.$2);
      canvas.drawLine(p1, p2, normalEdgePaint);
    }

    // 2. Paint active Dijkstra shortest path if available
    final activeRoute = route;
    if (activeRoute != null && activeRoute.hasPath && activeRoute.path.length >= 2) {
      for (int i = 0; i < activeRoute.path.length - 1; i++) {
        final fromNode = activeRoute.path[i];
        final toNode = activeRoute.path[i + 1];
        final p1 = getNodeOffset(fromNode);
        final p2 = getNodeOffset(toNode);

        // Bold route stroke
        canvas.drawLine(p1, p2, routeEdgePaint);

        // Directional arrow at segment midpoint
        _drawDirectionalArrow(canvas, p1, p2, arrowPaint);
      }
    }
  }

  /// Computes the center position for a directional chevron along [from] -> [to].
  ///
  /// For vertical segments between aisle waypoints and parking bays, centers the chevron
  /// within the physical gap between cards rather than at the mathematical midpoint of node centers.
  static Offset calculateArrowPosition(Offset from, Offset to) {
    final dx = to.dx - from.dx;

    // Vertical segment between aisle waypoint and bay
    if (dx.abs() < 1.0) {
      if ((from.dy - 52.0).abs() < 1.0 || (to.dy - 52.0).abs() < 1.0) {
        // Link connecting to Row A (North)
        return Offset(from.dx, rowAGapCenterY);
      } else if ((from.dy - 248.0).abs() < 1.0 || (to.dy - 248.0).abs() < 1.0) {
        // Link connecting to Row B (South)
        return Offset(from.dx, rowBGapCenterY);
      }
    }

    // Default to geometric midpoint (horizontal aisle segments)
    return Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
  }

  void _drawDirectionalArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < 10) return;

    final angle = math.atan2(dy, dx);
    final mid = calculateArrowPosition(from, to);

    const arrowLength = 9.0;
    const arrowAngle = math.pi / 6; // 30 degrees

    final path = Path();
    path.moveTo(
      mid.dx + arrowLength * 0.5 * math.cos(angle),
      mid.dy + arrowLength * 0.5 * math.sin(angle),
    );
    path.lineTo(
      mid.dx - arrowLength * math.cos(angle - arrowAngle),
      mid.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    path.lineTo(
      mid.dx - (arrowLength * 0.5) * math.cos(angle),
      mid.dy - (arrowLength * 0.5) * math.sin(angle),
    );
    path.lineTo(
      mid.dx - arrowLength * math.cos(angle + arrowAngle),
      mid.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FacilityRoutePainter oldDelegate) {
    if (identical(route, oldDelegate.route)) return false;
    if (route == null || oldDelegate.route == null) return true;
    return route!.sourceNodeId != oldDelegate.route!.sourceNodeId ||
        route!.targetNodeId != oldDelegate.route!.targetNodeId ||
        route!.distance != oldDelegate.route!.distance ||
        route!.path != oldDelegate.route!.path;
  }
}

