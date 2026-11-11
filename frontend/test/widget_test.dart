import 'package:flutter_test/flutter_test.dart';

import 'package:smartpark_app/app.dart';
import 'package:smartpark_app/services/smartpark_controller.dart';

void main() {
  testWidgets('SmartParkApp smoke test verifies startup and dashboard shell',
      (WidgetTester tester) async {
    final controller = SmartParkController();
    await tester.pumpWidget(SmartParkApp(controller: controller));

    // Verify app bar title
    expect(find.text('SmartPark Dashboard'), findsOneWidget);

    // Verify facility overview header
    expect(find.text('SmartPark Facility (Floor 1)'), findsOneWidget);

    // Verify summary title and key metric labels
    expect(find.text('Parking Availability Summary'), findsOneWidget);
    expect(find.text('Total Slots'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Occupied'), findsOneWidget);
    expect(find.text('Reserved'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
  });
}
