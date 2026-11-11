import 'package:flutter/material.dart';

import 'app.dart';
import 'services/smartpark_controller.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, instantiates the shared [SmartParkController]
/// with local hardcoded facility data, and starts the root [SmartParkApp].
///
/// // ponytail: minimal 5-line main; single controller instance
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = SmartParkController();
  runApp(SmartParkApp(controller: controller));
}
