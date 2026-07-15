// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Conformance suite for the node layer, ported from web_core's
/// `node-resolver.test.ts` (itself ported from the Python reference
/// `test_node_graph.py` plus defect coverage: eager action resolution,
/// shared-node use-after-dispose, and whole-list template respawn).
///
/// Known divergences from the TypeScript suite:
/// - The Dart binder synthesizes `setX` setters only for path-bound dynamic
///   props; web_core's synthesizes them for every two-way dynamic prop, so
///   the serialization test here expects no setters for literal values.
/// - The compile-time rejection of a schema-only catalog has no Dart
///   equivalent: `Catalog` only holds `FunctionImplementation`s, so a
///   signature-only catalog is not constructable at all.
library;

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

class _TestComponentApi extends ComponentApi {
  @override
  final String name;
  @override
  final Schema schema;

  _TestComponentApi(this.name, this.schema);
}

class _ShoutFunction extends FunctionImplementation {
  @override
  String get name => 'shout';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(
    properties: {'value': Schema.string()},
    required: ['value'],
  );

  @override
  Object? execute(
    Map<String, Object?> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) {
    return args['value'].toString().toUpperCase();
  }
}

class _Opaque {
  final int marker;
  _Opaque(this.marker);
}

Catalog<ComponentApi> makeCatalog() {
  return Catalog<ComponentApi>(
    id: 'node-test-catalog',
    components: [
      _TestComponentApi(
        'Text',
        Schema.object(properties: {'text': CommonSchemas.dynamicString}),
      ),
      _TestComponentApi(
        'Button',
        Schema.object(
          properties: {
            'label': CommonSchemas.dynamicString,
            'action': CommonSchemas.action,
          },
        ),
      ),
      _TestComponentApi(
        'Card',
        Schema.object(properties: {'child': CommonSchemas.componentId}),
      ),
      _TestComponentApi(
        'Column',
        Schema.object(properties: {'children': CommonSchemas.childList}),
      ),
      _TestComponentApi(
        'Tabs',
        Schema.object(
          properties: {
            'items': Schema.list(
              items: Schema.object(
                properties: {
                  'title': Schema.string(),
                  'child': CommonSchemas.componentId,
                },
              ),
            ),
          },
        ),
      ),
    ],
    functions: [_ShoutFunction()],
  );
}

typedef TestSetup = ({
  Catalog<ComponentApi> catalog,
  SurfaceModel<ComponentApi> surface,
  NodeResolver<ComponentApi> resolver,
});

TestSetup setup() {
  final Catalog<ComponentApi> catalog = makeCatalog();
  final surface = SurfaceModel<ComponentApi>('surf-1', catalog: catalog);
  final resolver = NodeResolver<ComponentApi>(surface, catalog);
  return (catalog: catalog, surface: surface, resolver: resolver);
}

void add(
  SurfaceModel<ComponentApi> surface,
  String id,
  String type,
  Map<String, Object?> properties,
) {
  surface.componentsModel.addComponent(ComponentModel(id, type, properties));
}

NodeProps props(ComponentNode node) => node.props.peek();

ComponentNode child(ComponentNode node, String key, [int? index]) {
  final Object? value = index == null
      ? props(node)[key]
      : (props(node)[key] as List)[index];
  expect(
    value,
    isA<ComponentNode>(),
    reason: 'expected $key[${index ?? ''}] to be a ComponentNode',
  );
  return value as ComponentNode;
}

/// Counts emissions of a signal, excluding the subscription-time run.
class EmissionCounter {
  int _count = -1;
  late final void Function() dispose;

  EmissionCounter(ReadonlySignal<Object?> signal) {
    dispose = effect(() {
      signal.value;
      _count++;
    });
  }

  int get count => _count;
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('NodeResolver conformance (port of node-resolver.test.ts)', () {
    test('resolves the root and upgrades and downgrades referenced children '
        '(lifecycle)', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Column', {
        'children': ['child_1'],
      });
      final ComponentNode? root = resolver.rootNode.value;
      expect(root, isNotNull);
      expect(root!.type, 'Column');
      expect(child(root, 'children', 0).type, placeholderType);

      add(surface, 'child_1', 'Text', {'text': 'Hello Node'});
      final ComponentNode upgraded = child(root, 'children', 0);
      expect(upgraded.type, 'Text');
      expect(props(upgraded)['text'], 'Hello Node');

      surface.componentsModel.removeComponent('child_1');
      expect(child(root, 'children', 0).type, placeholderType);
      expect(upgraded.disposed, isTrue);
      resolver.dispose();
      surface.dispose();
    });

    test('tracks root creation and removal on rootNode', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      expect(resolver.rootNode.value, isNull);

      add(surface, 'root', 'Column', {'children': <Object?>[]});
      final ComponentNode? root = resolver.rootNode.value;
      expect(root, isA<ComponentNode>());
      expect(root!.componentId, 'root');
      expect(root.type, 'Column');

      surface.componentsModel.removeComponent('root');
      expect(resolver.rootNode.value, isNull);
      expect(root.disposed, isTrue);
      resolver.dispose();
    });

    test('exposes core node properties', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Card', {'child': 'text-1'});
      add(surface, 'text-1', 'Text', {'text': 'Hi'});
      final ComponentNode root = resolver.rootNode.value!;
      expect(root.instanceId, 'root');
      expect(root.dataPath, '/');
      final ComponentNode textNode = child(root, 'child');
      expect(textNode.instanceId, 'text-1');
      expect(textNode.componentId, 'text-1');
      expect(textNode.type, 'Text');
      expect(textNode.dataPath, '/');
      resolver.dispose();
    });

    test('resolves data-bound properties reactively', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/username', 'Alice');
      add(surface, 'root', 'Text', {
        'text': {'path': '/username'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      expect(props(root)['text'], 'Alice');

      surface.dataModel.set('/username', 'Bob');
      expect(props(root)['text'], 'Bob');
      resolver.dispose();
    });

    test('resolves a single child reference to a live node', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Card', {'child': 'text-1'});
      add(surface, 'text-1', 'Text', {'text': 'Hello'});
      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode textNode = child(root, 'child');
      expect(textNode.type, 'Text');
      expect(props(textNode)['text'], 'Hello');
      resolver.dispose();
    });

    test('resolves an explicit children list in order', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Column', {
        'children': ['c1', 'c2'],
      });
      add(surface, 'c1', 'Text', {'text': 'C1'});
      add(surface, 'c2', 'Text', {'text': 'C2'});
      final ComponentNode root = resolver.rootNode.value!;
      final List<ComponentNode> children = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(children, hasLength(2));
      expect(props(children[0])['text'], 'C1');
      expect(props(children[1])['text'], 'C2');
      resolver.dispose();
    });

    test('spawns one node per array item for a template child list', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/items', [
        {'name': 'A'},
        {'name': 'B'},
      ]);
      add(surface, 'root', 'Column', {
        'children': {'componentId': 'item_tpl', 'path': '/items'},
      });
      add(surface, 'item_tpl', 'Text', {
        'text': {'path': 'name'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      final List<ComponentNode> children = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(children, hasLength(2));
      expect(children[0].instanceId, 'item_tpl-[/items/0]');
      expect(children[0].dataPath, '/items/0');
      expect(props(children[0])['text'], 'A');
      expect(props(children[1])['text'], 'B');
      resolver.dispose();
    });

    test('renders placeholders progressively and emits the parent exactly once '
        'on upgrade', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Column', {
        'children': ['late'],
      });
      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode placeholder = child(root, 'children', 0);
      expect(placeholder.type, placeholderType);
      expect(placeholder.componentId, 'late');

      var destroyed = 0;
      placeholder.onDestroyed.addListener((_) {
        destroyed++;
      });
      final emissions = EmissionCounter(root.props);

      add(surface, 'late', 'Text', {'text': 'Arrived'});
      expect(emissions.count, 1);
      final ComponentNode upgraded = child(root, 'children', 0);
      expect(identical(upgraded, placeholder), isFalse);
      expect(upgraded.type, 'Text');
      expect(props(upgraded)['text'], 'Arrived');
      expect(placeholder.disposed, isTrue);
      expect(destroyed, 1);
      emissions.dispose();
      resolver.dispose();
    });

    test(
      'binds actions as closures that dispatch through the surface',
      () async {
        final (
          catalog: Catalog<ComponentApi> catalog,
          surface: SurfaceModel<ComponentApi> surface,
          resolver: NodeResolver<ComponentApi> resolver,
        ) = setup();
        final actions = <A2uiClientAction>[];
        surface.onAction.addListener(actions.add);
        surface.dataModel.set('/current_id', 42);
        add(surface, 'root', 'Button', {
          'label': 'Go',
          'action': {
            'event': {
              'name': 'submit',
              'context': {
                'itemId': {'path': '/current_id'},
              },
            },
          },
        });
        final ComponentNode root = resolver.rootNode.value!;
        final Object? fire = props(root)['action'];
        expect(fire, isA<Function>());
        (fire as Function)();
        await flush();

        expect(actions, hasLength(1));
        expect(actions[0].name, 'submit');
        expect(actions[0].surfaceId, 'surf-1');
        expect(actions[0].sourceComponentId, 'root');
        expect(actions[0].context, {'itemId': 42});
        resolver.dispose();
      },
    );

    test('resolves an unresolved binding to null without failing', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Text', {
        'text': {'path': '/missing'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      expect(props(root)['text'], isNull);
      resolver.dispose();
    });

    test(
      'reconciles explicit children list changes, reusing surviving nodes',
      () {
        final (
          catalog: Catalog<ComponentApi> catalog,
          surface: SurfaceModel<ComponentApi> surface,
          resolver: NodeResolver<ComponentApi> resolver,
        ) = setup();
        add(surface, 'root', 'Column', {
          'children': ['c1', 'c2'],
        });
        add(surface, 'c1', 'Text', {'text': 'C1'});
        add(surface, 'c2', 'Text', {'text': 'C2'});
        add(surface, 'c3', 'Text', {'text': 'C3'});
        final ComponentNode root = resolver.rootNode.value!;
        final List<ComponentNode> before = (props(root)['children'] as List)
            .cast<ComponentNode>();

        surface.componentsModel.get('root')!.properties = {
          'children': ['c1', 'c3'],
        };

        final List<ComponentNode> after = (props(root)['children'] as List)
            .cast<ComponentNode>();
        expect(after, hasLength(2));
        expect(identical(after[0], before[0]), isTrue);
        expect(props(after[1])['text'], 'C3');
        expect(before[1].disposed, isTrue);
        resolver.dispose();
      },
    );

    test('reconciles a swap from explicit children to a template', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/items', [
        {'name': 'T0'},
      ]);
      add(surface, 'root', 'Column', {
        'children': ['c1'],
      });
      add(surface, 'c1', 'Text', {'text': 'C1'});
      add(surface, 'item_tpl', 'Text', {
        'text': {'path': 'name'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode explicitChild = child(root, 'children', 0);

      surface.componentsModel.get('root')!.properties = {
        'children': {'componentId': 'item_tpl', 'path': '/items'},
      };

      final List<ComponentNode> children = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(children, hasLength(1));
      expect(props(children[0])['text'], 'T0');
      expect(explicitChild.disposed, isTrue);
      resolver.dispose();
    });

    test('resolves function-call bindings reactively', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/username', 'alice');
      add(surface, 'root', 'Text', {
        'text': {
          'call': 'shout',
          'args': {
            'value': {'path': '/username'},
          },
        },
      });
      final ComponentNode root = resolver.rootNode.value!;
      expect(props(root)['text'], 'ALICE');

      surface.dataModel.set('/username', 'bob');
      expect(props(root)['text'], 'BOB');
      resolver.dispose();
    });

    test('resolves nested child references inside item arrays', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Tabs', {
        'items': [
          {'title': 'One', 'child': 't1'},
          {'title': 'Two', 'child': 't2'},
        ],
      });
      add(surface, 't1', 'Text', {'text': 'First'});
      add(surface, 't2', 'Text', {'text': 'Second'});
      final ComponentNode root = resolver.rootNode.value!;
      final List<Map<Object?, Object?>> items = (props(root)['items'] as List)
          .cast<Map<Object?, Object?>>();
      expect(items, hasLength(2));
      expect(items[0]['title'], 'One');
      final Object? first = items[0]['child'];
      expect(first, isA<ComponentNode>());
      expect(props(first as ComponentNode)['text'], 'First');
      final Object? second = items[1]['child'];
      expect(second, isA<ComponentNode>());
      expect(props(second as ComponentNode)['text'], 'Second');
      resolver.dispose();
    });

    test('reconciles a deleted component back to a placeholder, leaving '
        'siblings alone', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Column', {
        'children': ['c1', 'c2'],
      });
      add(surface, 'c1', 'Text', {'text': 'C1'});
      add(surface, 'c2', 'Text', {'text': 'C2'});
      final ComponentNode root = resolver.rootNode.value!;
      final List<ComponentNode> before = (props(root)['children'] as List)
          .cast<ComponentNode>();

      surface.componentsModel.removeComponent('c2');

      final List<ComponentNode> after = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(identical(after[0], before[0]), isTrue);
      expect(after[1].type, placeholderType);
      expect(before[1].disposed, isTrue);
      resolver.dispose();
    });

    test(
      're-spawns template children as the bound array grows and shrinks',
      () {
        final (
          catalog: Catalog<ComponentApi> catalog,
          surface: SurfaceModel<ComponentApi> surface,
          resolver: NodeResolver<ComponentApi> resolver,
        ) = setup();
        surface.dataModel.set('/items', [
          {'name': 'A'},
        ]);
        add(surface, 'root', 'Column', {
          'children': {'componentId': 'item_tpl', 'path': '/items'},
        });
        add(surface, 'item_tpl', 'Text', {
          'text': {'path': 'name'},
        });
        final ComponentNode root = resolver.rootNode.value!;
        expect(props(root)['children'] as List, hasLength(1));

        surface.dataModel.set('/items', [
          {'name': 'A'},
          {'name': 'B'},
          {'name': 'C'},
        ]);
        final List<ComponentNode> grown = (props(root)['children'] as List)
            .cast<ComponentNode>();
        expect(grown, hasLength(3));
        expect(props(grown[2])['text'], 'C');

        surface.dataModel.set('/items', [
          {'name': 'A'},
        ]);
        final List<ComponentNode> shrunk = (props(root)['children'] as List)
            .cast<ComponentNode>();
        expect(shrunk, hasLength(1));
        expect(grown[1].disposed, isTrue);
        expect(grown[2].disposed, isTrue);
        resolver.dispose();
      },
    );

    test('serializes the resolved tree, rendering actions and placeholders '
        'specially', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Column', {
        'children': ['card', 'btn', 'late'],
      });
      add(surface, 'card', 'Card', {'child': 'txt'});
      add(surface, 'txt', 'Text', {'text': 'Hello'});
      add(surface, 'btn', 'Button', {
        'label': 'Go',
        'action': {
          'event': {'name': 'go'},
        },
      });
      final ComponentNode root = resolver.rootNode.value!;
      // Unlike web_core, the Dart binder synthesizes setters only for
      // path-bound props, so the literal-valued Text and Button carry none.
      expect(root.toJson(), {
        'id': 'root',
        'type': 'Column',
        'children': [
          {
            'id': 'card',
            'type': 'Card',
            'child': {'id': 'txt', 'type': 'Text', 'text': 'Hello'},
          },
          {'id': 'btn', 'type': 'Button', 'label': 'Go', 'action': '<Action>'},
          {'id': 'late', 'type': placeholderType},
        ],
      });
      resolver.dispose();
    });
  });

  group('NodeResolver defect coverage (fixes over the Python reference)', () {
    test('resolves action context at dispatch time, not bind time '
        '(late resolution)', () async {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      final actions = <A2uiClientAction>[];
      surface.onAction.addListener(actions.add);
      surface.dataModel.set('/current_id', 'stale');
      add(surface, 'root', 'Button', {
        'action': {
          'event': {
            'name': 'submit',
            'context': {
              'itemId': {'path': '/current_id'},
            },
          },
        },
      });
      final ComponentNode root = resolver.rootNode.value!;

      surface.dataModel.set('/current_id', 'fresh');
      (props(root)['action'] as Function)();
      await flush();

      expect(actions, hasLength(1));
      expect(actions[0].context, {'itemId': 'fresh'});
      resolver.dispose();
    });

    test('keeps a shared child alive for one parent when the other stops '
        'referencing it', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/label', 'shared text');
      add(surface, 'root', 'Column', {
        'children': ['card_a', 'card_b'],
      });
      add(surface, 'card_a', 'Card', {'child': 'shared'});
      add(surface, 'card_b', 'Card', {'child': 'shared'});
      add(surface, 'shared', 'Text', {
        'text': {'path': '/label'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode cardA = child(root, 'children', 0);
      final ComponentNode cardB = child(root, 'children', 1);
      final ComponentNode sharedViaA = child(cardA, 'child');
      final ComponentNode sharedViaB = child(cardB, 'child');
      expect(identical(sharedViaA, sharedViaB), isFalse);

      surface.componentsModel.get('card_a')!.properties = {};

      expect(sharedViaA.disposed, isTrue);
      expect(sharedViaB.disposed, isFalse);
      surface.dataModel.set('/label', 'still updating');
      expect(props(sharedViaB)['text'], 'still updating');
      resolver.dispose();
    });

    test('keeps surviving template nodes across array growth and shrink '
        '(key stability)', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/items', [
        {'name': 'A'},
        {'name': 'B'},
      ]);
      add(surface, 'root', 'Column', {
        'children': {'componentId': 'item_tpl', 'path': '/items'},
      });
      add(surface, 'item_tpl', 'Text', {
        'text': {'path': 'name'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      final before = List<ComponentNode>.of(
        (props(root)['children'] as List).cast<ComponentNode>(),
      );

      surface.dataModel.set('/items', [
        {'name': 'A'},
        {'name': 'B'},
        {'name': 'C'},
      ]);
      final List<ComponentNode> grown = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(identical(grown[0], before[0]), isTrue);
      expect(identical(grown[1], before[1]), isTrue);
      expect(before[0].disposed, isFalse);
      expect(before[1].disposed, isFalse);

      surface.dataModel.set('/items', [
        {'name': 'A'},
      ]);
      final List<ComponentNode> shrunk = (props(root)['children'] as List)
          .cast<ComponentNode>();
      expect(identical(shrunk[0], before[0]), isTrue);
      expect(before[1].disposed, isTrue);
      resolver.dispose();
    });

    test('does not emit a parent props signal when only a child property '
        'changes (no bubbling)', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      surface.dataModel.set('/username', 'Alice');
      surface.dataModel.set('/items', [
        {'name': 'A'},
        {'name': 'B'},
      ]);
      add(surface, 'root', 'Column', {
        'children': ['bound', 'tpl_col'],
      });
      add(surface, 'bound', 'Text', {
        'text': {'path': '/username'},
      });
      add(surface, 'tpl_col', 'Column', {
        'children': {'componentId': 'item_tpl', 'path': '/items'},
      });
      add(surface, 'item_tpl', 'Text', {
        'text': {'path': 'name'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode boundText = child(root, 'children', 0);
      final ComponentNode templateColumn = child(root, 'children', 1);
      final ComponentNode item0 = child(templateColumn, 'children', 0);

      final rootEmissions = EmissionCounter(root.props);
      final templateColumnEmissions = EmissionCounter(templateColumn.props);
      final boundEmissions = EmissionCounter(boundText.props);
      final item0Emissions = EmissionCounter(item0.props);

      surface.dataModel.set('/username', 'Bob');
      expect(boundEmissions.count, 1);
      expect(props(boundText)['text'], 'Bob');
      expect(rootEmissions.count, 0);

      // Editing one item's field re-fires the template's array
      // subscription (ancestor-path propagation); the item node must
      // update while the template parent's props stay identity-stable and
      // silent.
      surface.dataModel.set('/items/0/name', 'A2');
      expect(props(item0)['text'], 'A2');
      expect(item0Emissions.count, greaterThanOrEqualTo(1));
      expect(templateColumnEmissions.count, 0);
      expect(rootEmissions.count, 0);

      rootEmissions.dispose();
      templateColumnEmissions.dispose();
      boundEmissions.dispose();
      item0Emissions.dispose();
      resolver.dispose();
    });
  });

  group('NodeResolver malformed and unusual payloads', () {
    test('renders cyclic references as placeholders instead of recursing', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      final errors = <A2uiClientError>[];
      surface.onError.addListener(errors.add);
      add(surface, 'root', 'Card', {'child': 'a'});
      add(surface, 'a', 'Card', {'child': 'b'});
      add(surface, 'b', 'Card', {'child': 'a'});

      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode a = child(root, 'child');
      final ComponentNode b = child(a, 'child');
      final ComponentNode backReference = child(b, 'child');
      expect(backReference.type, placeholderType);
      expect(backReference.componentId, 'a');
      expect(errors.any((e) => e.code == 'CYCLIC_REFERENCE'), isTrue);
      expect(resolver.activeNodeCount, lessThanOrEqualTo(5));
      resolver.dispose();
    });

    test('renders a self-referencing component as a placeholder child', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      add(surface, 'root', 'Card', {'child': 'root'});
      final ComponentNode root = resolver.rootNode.value!;
      expect(child(root, 'child').type, placeholderType);
      resolver.dispose();
    });

    test('propagates changes to non-plain object values', () {
      // Class instances have no entries for key-wise stabilization to
      // compare, so the engine must treat them as always-changed.
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      final first = _Opaque(1);
      final second = _Opaque(2);
      surface.dataModel.set('/blob', {'wrapper': first});
      add(surface, 'root', 'Text', {
        'text': {'path': '/blob'},
      });
      final ComponentNode root = resolver.rootNode.value!;
      expect(identical((props(root)['text'] as Map)['wrapper'], first), isTrue);

      surface.dataModel.set('/blob', {'wrapper': second});
      expect(
        identical((props(root)['text'] as Map)['wrapper'], second),
        isTrue,
      );
      resolver.dispose();
    });

    test('keeps a stable placeholder for a component whose type is not in the '
        'catalog', () {
      final (
        catalog: Catalog<ComponentApi> catalog,
        surface: SurfaceModel<ComponentApi> surface,
        resolver: NodeResolver<ComponentApi> resolver,
      ) = setup();
      final errors = <A2uiClientError>[];
      surface.onError.addListener(errors.add);
      add(surface, 'root', 'Card', {'child': 'weird'});
      add(surface, 'weird', 'Bogus', {});

      final ComponentNode root = resolver.rootNode.value!;
      final ComponentNode placeholder = child(root, 'child');
      expect(placeholder.type, placeholderType);
      final int reportsBefore = errors
          .where((e) => e.code == 'UNKNOWN_COMPONENT_TYPE')
          .length;

      surface.componentsModel.get('root')!.properties = {'child': 'weird'};
      surface.componentsModel.get('root')!.properties = {'child': 'weird'};

      expect(identical(child(root, 'child'), placeholder), isTrue);
      expect(
        errors.where((e) => e.code == 'UNKNOWN_COMPONENT_TYPE').length,
        reportsBefore,
      );
      resolver.dispose();
    });
  });

  group('NodeResolver construction gate', () {
    test('rejects a catalog instance other than the surface catalog', () {
      final Catalog<ComponentApi> catalogA = makeCatalog();
      final Catalog<ComponentApi> catalogB = makeCatalog();
      final surface = SurfaceModel<ComponentApi>('surf-1', catalog: catalogA);
      expect(
        () => NodeResolver<ComponentApi>(surface, catalogB),
        throwsA(
          isA<A2uiStateError>().having(
            (e) => e.message,
            'message',
            contains('same catalog instance'),
          ),
        ),
      );
    });

    test(
      'disposes the whole tree with the resolver, leaving no live nodes',
      () {
        final (
          catalog: Catalog<ComponentApi> catalog,
          surface: SurfaceModel<ComponentApi> surface,
          resolver: NodeResolver<ComponentApi> resolver,
        ) = setup();
        surface.dataModel.set('/items', [
          {'name': 'A'},
          {'name': 'B'},
        ]);
        add(surface, 'root', 'Column', {
          'children': ['card', 'tpl_col'],
        });
        add(surface, 'card', 'Card', {'child': 'txt'});
        add(surface, 'txt', 'Text', {'text': 'Hello'});
        add(surface, 'tpl_col', 'Column', {
          'children': {'componentId': 'item_tpl', 'path': '/items'},
        });
        add(surface, 'item_tpl', 'Text', {
          'text': {'path': 'name'},
        });
        final ComponentNode root = resolver.rootNode.value!;
        expect(resolver.activeNodeCount, greaterThanOrEqualTo(6));

        resolver.dispose();
        expect(resolver.activeNodeCount, 0);
        expect(resolver.rootNode.value, isNull);
        expect(root.disposed, isTrue);

        // A data change after disposal must not resurrect any binding.
        surface.dataModel.set('/items', [
          {'name': 'X'},
        ]);
        expect(resolver.activeNodeCount, 0);
      },
    );
  });
}
