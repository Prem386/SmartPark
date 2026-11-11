import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'services/smartpark_controller.dart';
import 'widgets/smartpark_scope.dart';

/// Root application widget for SmartPark.
///
/// Binds [SmartParkController] to the widget tree via [SmartParkScope] and
/// applies the cohesive Material 3 theme.
///
/// // ponytail: single MaterialApp root; declarative SmartParkScope wrapper
class SmartParkApp extends StatelessWidget {
  final SmartParkController controller;

  const SmartParkApp({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SmartParkScope(
      controller: controller,
      child: MaterialApp(
        title: 'SmartPark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}

