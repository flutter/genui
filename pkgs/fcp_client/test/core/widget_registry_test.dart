import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetRegistry', () {
    late WidgetRegistry registry;

    setUp(() {
      registry = WidgetRegistry();
    });

    test('register and getBuilder work correctly', () {
      SizedBox builder(
        BuildContext context,
        WidgetNode node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => const SizedBox();
      registry.register('SizedBox', builder);

      final retrievedBuilder = registry.getBuilder('SizedBox');
      expect(retrievedBuilder, isNotNull);
      expect(retrievedBuilder, same(builder));
    });

    test('getBuilder returns null for unregistered type', () {
      final retrievedBuilder = registry.getBuilder('UnregisteredWidget');
      expect(retrievedBuilder, isNull);
    });

    test('hasBuilder returns true for registered type', () {
      SizedBox builder(
        BuildContext context,
        WidgetNode node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => const SizedBox();
      registry.register('SizedBox', builder);
      expect(registry.hasBuilder('SizedBox'), isTrue);
    });

    test('hasBuilder returns false for unregistered type', () {
      expect(registry.hasBuilder('UnregisteredWidget'), isFalse);
    });

    test('registering a builder overwrites an existing one', () {
      SizedBox builder1(
        BuildContext context,
        WidgetNode node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => const SizedBox(width: 1);
      SizedBox builder2(
        BuildContext context,
        WidgetNode node,
        Map<String, Object?> properties,
        Map<String, dynamic> children,
      ) => const SizedBox(width: 2);

      registry.register('SizedBox', builder1);
      expect(registry.getBuilder('SizedBox'), same(builder1));

      registry.register('SizedBox', builder2);
      expect(registry.getBuilder('SizedBox'), same(builder2));
    });
  });
}
