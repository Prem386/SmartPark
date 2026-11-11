import 'package:flutter/widgets.dart';

import '../services/smartpark_controller.dart';

/// Scoped inherited notifier providing shared access to [SmartParkController].
///
/// Descendant widgets automatically rebuild when [SmartParkController.notifyListeners] is called.
///
/// // ponytail: Flutter native InheritedNotifier; 0 dependencies, O(1) context lookup
class SmartParkScope extends InheritedNotifier<SmartParkController> {
  const SmartParkScope({
    super.key,
    required SmartParkController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Retrieves the active [SmartParkController] from the nearest ancestor [SmartParkScope].
  static SmartParkController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'No SmartParkScope found in the current widget tree context.',
    );
    return controller!;
  }

  /// Retrieves the active [SmartParkController], or `null` if none exists.
  static SmartParkController? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SmartParkScope>();
    return scope?.notifier;
  }
}

