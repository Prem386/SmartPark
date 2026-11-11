import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/parking_slot.dart';
import '../../services/parking_navigation_service.dart';
import '../../widgets/smartpark_scope.dart';
import 'widgets/destination_selector_bar.dart';
import 'widgets/navigation_facility_layout.dart';
import 'widgets/navigation_route_card.dart';

/// Screen implementing Phase 3.3 Facility Navigation.
///
/// Demonstrates end-to-end integration of the custom [WeightedGraph] and [Dijkstra]
/// shortest-path algorithm:
/// - Visualizes the 38m x 16m single-floor facility topology
/// - Allows direct bay selection from layout or destination dropdown
/// - Calculates shortest route from facility entrance (`NODE_ENTRANCE`) to selected bay
/// - Renders highlighted route connections and waypoint sequence on canvas
/// - Displays authoritative calculated distance and turn-by-turn route breakdown
///
/// // ponytail: standard StatefulWidget querying ParkingNavigationService; 0 extra layers
class FacilityNavigationScreen extends StatefulWidget {
  /// Optional slot code to navigate to initially (e.g. 'P04').
  final String? initialSlotCode;

  const FacilityNavigationScreen({
    super.key,
    this.initialSlotCode,
  });

  @override
  State<FacilityNavigationScreen> createState() =>
      _FacilityNavigationScreenState();
}

class _FacilityNavigationScreenState extends State<FacilityNavigationScreen> {
  String? _selectedSlotCode;
  NavigationRoute? _currentRoute;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      if (widget.initialSlotCode != null) {
        final controller = SmartParkScope.of(context);
        _calculateRoute(widget.initialSlotCode!, controller.navigationService);
      }
    }
  }

  void _calculateRoute(String? slotCode, ParkingNavigationService navService, [ParkingSlot? slot]) {
    if (slotCode == null || slotCode.trim().isEmpty) {
      _clearRoute();
      return;
    }

    final cleanCode = slotCode.trim().toUpperCase();
    final targetSlot = slot ??
        SmartParkScope.of(context).slotService.getSlot(cleanCode);

    final route = targetSlot != null
        ? navService.getRouteToSlot(targetSlot)
        : navService.getRouteToSlotCode(cleanCode);

    setState(() {
      _selectedSlotCode = cleanCode;
      _currentRoute = route;
    });
  }

  void _clearRoute() {
    setState(() {
      _selectedSlotCode = null;
      _currentRoute = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = SmartParkScope.of(context);
    final allSlots = controller.slotService.getAllSlots();
    final rowASlots = allSlots.where((s) => s.row == SlotRow.a).toList();
    final rowBSlots = allSlots.where((s) => s.row == SlotRow.b).toList();

    final topRecommendation =
        controller.recommendationService.getTopRecommendation();

    final destinationSlot = _selectedSlotCode != null
        ? controller.slotService.getSlot(_selectedSlotCode!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Route',
            onPressed: _clearRoute,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Facility Navigation Header
              _buildHeader(context),
              const SizedBox(height: 14),

              // Destination Selector Bar
              DestinationSelectorBar(
                allSlots: allSlots,
                selectedSlotCode: _selectedSlotCode,
                recommendedSlotCode: topRecommendation?.slot.slotCode,
                onSlotChanged: (code) =>
                    _calculateRoute(code, controller.navigationService),
              ),
              const SizedBox(height: 14),

              // Interactive Facility Map with Vector Route Visualization
              NavigationFacilityLayout(
                rowASlots: rowASlots,
                rowBSlots: rowBSlots,
                selectedSlotCode: _selectedSlotCode,
                activeRoute: _currentRoute,
                onSlotSelected: (code) =>
                    _calculateRoute(code, controller.navigationService),
              ),
              const SizedBox(height: 16),

              // Calculated Route Information and Waypoint Sequence
              NavigationRouteCard(
                route: _currentRoute,
                destinationSlot: destinationSlot,
                selectedSlotCode: _selectedSlotCode,
                graph: controller.navigationService.graph,
                onClearRoute: _clearRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Facility Navigation (Floor 1)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Shortest-path routing via custom Weighted Graph & Dijkstra algorithm',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

