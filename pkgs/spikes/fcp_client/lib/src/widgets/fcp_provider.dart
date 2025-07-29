import 'package:flutter/material.dart';
import '../../fcp_client.dart';

/// An [InheritedWidget] that provides FCP-related data to the widget tree.
///
/// This is used to pass the [onEvent] callback down to widgets that need to
/// fire events, without having to pass the callback through many layers of
/// widget constructors.
class FcpProvider extends InheritedWidget {
  const FcpProvider({super.key, required super.child, this.onEvent});

  final ValueChanged<EventPayload>? onEvent;

  static FcpProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FcpProvider>();
  }

  @override
  bool updateShouldNotify(FcpProvider oldWidget) {
    return onEvent != oldWidget.onEvent;
  }
}
