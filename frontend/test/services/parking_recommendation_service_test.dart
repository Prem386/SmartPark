import 'package:flutter_test/flutter_test.dart';
import 'package:smartpark_app/dsa/graph/graph.dart';
import 'package:smartpark_app/models/parking_slot.dart';
import 'package:smartpark_app/services/parking_navigation_service.dart';
import 'package:smartpark_app/services/parking_recommendation_service.dart';
import 'package:smartpark_app/services/parking_slot_service.dart';

void main() {
  group('ParkingRecommendationService (Full DSA Integration)', () {
    late ParkingSlotService slotService;
    late ParkingNavigationService navigationService;
    late ParkingRecommendationService recommendationService;

    // Standard 20 slots generator
    List<ParkingSlot> createFacilitySlots() {
      final slots = <ParkingSlot>[];
      // Row A: P01 - P10
      for (int i = 1; i <= 10; i++) {
        final code = 'P${i.toString().padLeft(2, '0')}';
        slots.add(
          ParkingSlot(
            id: 'slot-$code',
            slotCode: code,
            row: SlotRow.a,
            status: SlotStatus.available,
            isActive: true,
            navigationNodeId: 'NODE_$code',
          ),
        );
      }
      // Row B: P11 - P20
      for (int i = 1; i <= 10; i++) {
        final code = 'P${i + 10}';
        slots.add(
          ParkingSlot(
            id: 'slot-$code',
            slotCode: code,
            row: SlotRow.b,
            status: SlotStatus.available,
            isActive: true,
            navigationNodeId: 'NODE_$code',
          ),
        );
      }
      return slots;
    }

    setUp(() {
      slotService = ParkingSlotService();
      navigationService = ParkingNavigationService();
      recommendationService = ParkingRecommendationService(
        slotService: slotService,
        navigationService: navigationService,
      );
    });

    test('recommends parking slots in ascending route distance order', () {
      final allSlots = createFacilitySlots();
      for (final s in allSlots) {
        slotService.registerSlot(s);
      }

      final recommendations = recommendationService.getRecommendations();
      expect(recommendations.length, equals(20));

      // Invariant: distances must be monotonically non-decreasing
      for (int i = 0; i < recommendations.length - 1; i++) {
        final curr = recommendations[i];
        final next = recommendations[i + 1];
        expect(
          curr.distance <= next.distance,
          isTrue,
          reason: '${curr.slot.slotCode} (${curr.distance}m) should be <= ${next.slot.slotCode} (${next.distance}m)',
        );
      }
    });

    test('breaks equal-distance ties deterministically by slotCode alphabetical order', () {
      // P01 (Row A, 9.5m) and P11 (Row B, 9.5m) are equidistant from entrance
      final slot01 = ParkingSlot(
        id: 'slot-P01',
        slotCode: 'P01',
        row: SlotRow.a,
        navigationNodeId: 'NODE_P01',
      );
      final slot11 = ParkingSlot(
        id: 'slot-P11',
        slotCode: 'P11',
        row: SlotRow.b,
        navigationNodeId: 'NODE_P11',
      );

      // Register P11 before P01 in slot service to ensure registration order doesn't dictate result
      slotService.registerSlot(slot11);
      slotService.registerSlot(slot01);

      final recommendations = recommendationService.getRecommendations();
      expect(recommendations.length, equals(2));

      // Both have 9.5m distance
      expect(recommendations[0].distance, equals(9.5));
      expect(recommendations[1].distance, equals(9.5));

      // 'P01' comes alphabetically before 'P11'
      expect(recommendations[0].slot.slotCode, equals('P01'));
      expect(recommendations[1].slot.slotCode, equals('P11'));
    });

    test('filters out occupied, reserved, maintenance, and inactive slots', () {
      // P01: Available & active (eligible)
      final p01 = ParkingSlot(id: 'P01', slotCode: 'P01', row: SlotRow.a, status: SlotStatus.available, isActive: true);
      // P02: Occupied (ineligible)
      final p02 = ParkingSlot(id: 'P02', slotCode: 'P02', row: SlotRow.a, status: SlotStatus.occupied, isActive: true);
      // P03: Reserved (ineligible)
      final p03 = ParkingSlot(id: 'P03', slotCode: 'P03', row: SlotRow.a, status: SlotStatus.reserved, isActive: true);
      // P04: Maintenance (ineligible)
      final p04 = ParkingSlot(id: 'P04', slotCode: 'P04', row: SlotRow.a, status: SlotStatus.maintenance, isActive: true);
      // P05: Available but isActive == false (ineligible)
      final p05 = ParkingSlot(id: 'P05', slotCode: 'P05', row: SlotRow.a, status: SlotStatus.available, isActive: false);
      // P06: Available & active (eligible)
      final p06 = ParkingSlot(id: 'P06', slotCode: 'P06', row: SlotRow.a, status: SlotStatus.available, isActive: true);

      for (final s in [p01, p02, p03, p04, p05, p06]) {
        slotService.registerSlot(s);
      }

      final recommendations = recommendationService.getRecommendations();

      // Only P01 and P06 should be recommended
      expect(recommendations.length, equals(2));
      expect(recommendations.map((c) => c.slot.slotCode).toList(), equals(['P01', 'P06']));
    });

    test('supports top-N recommendation limits without full heap extraction', () {
      final allSlots = createFacilitySlots();
      for (final s in allSlots) {
        slotService.registerSlot(s);
      }

      final top3 = recommendationService.getRecommendations(limit: 3);
      expect(top3.length, equals(3));
      expect(top3[0].slot.slotCode, equals('P01')); // 9.5m
      expect(top3[1].slot.slotCode, equals('P11')); // 9.5m
      expect(top3[2].slot.slotCode, equals('P02')); // 12.5m

      final top1 = recommendationService.getTopRecommendation();
      expect(top1, isNotNull);
      expect(top1!.slot.slotCode, equals('P01'));
      expect(top1.distance, equals(9.5));
    });

    test('returns clean empty list when slot registry is empty', () {
      final recommendations = recommendationService.getRecommendations();
      expect(recommendations, isEmpty);
      expect(recommendationService.getTopRecommendation(), isNull);
    });

    test('returns clean empty list when all slots are unavailable', () {
      final p01 = ParkingSlot(id: 'P01', slotCode: 'P01', row: SlotRow.a, status: SlotStatus.occupied);
      final p02 = ParkingSlot(id: 'P02', slotCode: 'P02', row: SlotRow.a, status: SlotStatus.maintenance);
      slotService.registerSlot(p01);
      slotService.registerSlot(p02);

      final recommendations = recommendationService.getRecommendations();
      expect(recommendations, isEmpty);
    });

    test('excludes slots that are unreachable in navigation graph', () {
      final customGraph = ParkingGraphFactory.createFacilityGraph();
      // Add unreachable node
      customGraph.addVertex(
        GraphNode(
          id: 'NODE_DISCONNECTED',
          type: GraphNodeType.parkingSlot,
          label: 'Disconnected Slot',
        ),
      );

      final disconnectedNav = ParkingNavigationService(graph: customGraph);
      final testRecService = ParkingRecommendationService(
        slotService: slotService,
        navigationService: disconnectedNav,
      );

      final reachableSlot = ParkingSlot(
        id: 'P01',
        slotCode: 'P01',
        row: SlotRow.a,
        navigationNodeId: 'NODE_P01',
      );
      final unreachableSlot = ParkingSlot(
        id: 'P99',
        slotCode: 'P99',
        row: SlotRow.a,
        navigationNodeId: 'NODE_DISCONNECTED',
      );

      slotService.registerSlot(reachableSlot);
      slotService.registerSlot(unreachableSlot);

      final recommendations = testRecService.getRecommendations();
      expect(recommendations.length, equals(1));
      expect(recommendations.first.slot.slotCode, equals('P01'));
    });
  });
}

