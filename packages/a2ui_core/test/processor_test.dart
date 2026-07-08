// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/src/core/catalog.dart';
import 'package:a2ui_core/src/core/common_schemas.dart';
import 'package:a2ui_core/src/core/component_model.dart';
import 'package:a2ui_core/src/core/contexts.dart';
import 'package:a2ui_core/src/core/messages.dart';
import 'package:a2ui_core/src/core/minimal_catalog.dart';
import 'package:a2ui_core/src/core/surface_model.dart';
import 'package:a2ui_core/src/primitives/cancellation.dart';
import 'package:a2ui_core/src/primitives/errors.dart';
import 'package:a2ui_core/src/processing/processor.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

/// A function that may be invoked remotely via `callFunction` messages.
class EchoFunction extends FunctionImplementation {
  @override
  String get name => 'echo';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  A2uiCallableFrom get callableFrom => A2uiCallableFrom.clientOrRemote;

  @override
  Schema get argumentSchema =>
      Schema.object(properties: {'value': Schema.string()});

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) => args['value'];
}

class RemoteFunctionCatalog extends Catalog<ComponentApi> {
  RemoteFunctionCatalog()
    : super(id: 'test:remote', components: [], functions: [EchoFunction()]);
}

void main() {
  group('MessageProcessor', () {
    late MinimalCatalog catalog;
    late MessageProcessor processor;

    setUp(() {
      catalog = MinimalCatalog();
      processor = MessageProcessor(catalogs: [catalog]);
    });

    test('creates surface', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      expect(surface, isNotNull);
      expect(surface?.id, 's1');
      expect(surface?.catalog.id, catalog.id);
    });

    test('updates components', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        UpdateComponentsMessage(
          surfaceId: 's1',
          components: [
            {'id': 'root', 'component': 'Text', 'text': 'Hello'},
          ],
        ),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      final ComponentModel? root = surface?.componentsModel.get('root');
      expect(root, isNotNull);
      expect(root?.type, 'Text');
      expect(root?.properties['text'], 'Hello');
    });

    test('updates data model', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        UpdateDataModelMessage(
          surfaceId: 's1',
          path: '/user/name',
          value: 'Alice',
        ),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      expect(surface?.dataModel.get('/user/name'), 'Alice');
    });

    test('deletes surface', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        DeleteSurfaceMessage(surfaceId: 's1'),
      ]);

      expect(processor.groupModel.getSurface('s1'), isNull);
    });

    test('creates surface with inline components and data model', () {
      processor.processMessages([
        CreateSurfaceMessage(
          surfaceId: 's1',
          catalogId: catalog.id,
          components: [
            {'id': 'root', 'component': 'Text', 'text': 'Hello'},
          ],
          dataModel: {
            'user': {'name': 'Alice'},
          },
        ),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      expect(surface?.componentsModel.get('root')?.properties['text'], 'Hello');
      expect(surface?.dataModel.get('/user/name'), 'Alice');
    });

    test('throws on duplicate surfaceId', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
      ]);

      expect(
        () => processor.processMessages([
          CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        ]),
        throwsA(isA<A2uiStateError>()),
      );
    });

    test('deletes a data model key on explicit null value', () {
      processor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
        UpdateDataModelMessage(
          surfaceId: 's1',
          path: '/',
          value: {
            'user': {'name': 'Alice', 'age': 30},
          },
        ),
        UpdateDataModelMessage(surfaceId: 's1', path: '/user/age'),
      ]);

      final SurfaceModel<ComponentApi>? surface = processor.groupModel
          .getSurface('s1');
      expect(surface?.dataModel.get('/user'), {'name': 'Alice'});
    });

    test('executes remotely callable functions and emits a response', () {
      final responses = <A2uiFunctionResponse>[];
      final MessageProcessor<ComponentApi> remoteProcessor = MessageProcessor(
        catalogs: [RemoteFunctionCatalog()],
        onFunctionResponse: responses.add,
      );

      remoteProcessor.processMessages([
        CallFunctionMessage(
          functionCallId: 'fc-1',
          wantResponse: true,
          call: 'echo',
          args: {'value': 'hi'},
        ),
      ]);

      expect(responses, hasLength(1));
      expect(responses.first.functionCallId, 'fc-1');
      expect(responses.first.call, 'echo');
      expect(responses.first.value, 'hi');
    });

    test('rejects callFunction for clientOnly functions', () {
      final errors = <A2uiClientError>[];
      final MessageProcessor<ComponentApi> localProcessor = MessageProcessor(
        catalogs: [catalog],
        onError: errors.add,
      );

      localProcessor.processMessages([
        // 'capitalize' in the minimal catalog defaults to clientOnly.
        CallFunctionMessage(
          functionCallId: 'fc-1',
          call: 'capitalize',
          args: {'value': 'hi'},
        ),
      ]);

      expect(errors, hasLength(1));
      expect(errors.first.code, 'INVALID_FUNCTION_CALL');
      expect(errors.first.functionCallId, 'fc-1');
    });

    test('rejects callFunction for unregistered functions', () {
      final errors = <A2uiClientError>[];
      final MessageProcessor<ComponentApi> errorProcessor = MessageProcessor(
        catalogs: [catalog],
        onError: errors.add,
      );

      errorProcessor.processMessages([
        CallFunctionMessage(functionCallId: 'fc-1', call: 'doesNotExist'),
      ]);

      expect(errors, hasLength(1));
      expect(errors.first.code, 'INVALID_FUNCTION_CALL');
    });

    test('routes actionResponse values into the data model', () async {
      final actions = <A2uiClientAction>[];
      final MessageProcessor<ComponentApi> responseProcessor = MessageProcessor(
        catalogs: [catalog],
        onAction: actions.add,
      );

      responseProcessor.processMessages([
        CreateSurfaceMessage(surfaceId: 's1', catalogId: catalog.id),
      ]);
      final SurfaceModel<ComponentApi> surface = responseProcessor.groupModel
          .getSurface('s1')!;

      await surface.dispatchAction({
        'event': {
          'name': 'submit',
          'wantResponse': true,
          'responsePath': '/result',
        },
      }, 'button1');

      expect(actions, hasLength(1));
      final String actionId = actions.first.actionId!;
      expect(actions.first.wantResponse, isTrue);

      responseProcessor.processMessages([
        ActionResponseMessage(actionId: actionId, value: 'ok'),
      ]);

      expect(surface.dataModel.get('/result'), 'ok');
    });

    test('throws on actionResponse for an unknown actionId', () {
      expect(
        () => processor.processMessages([
          ActionResponseMessage(actionId: 'nope', value: 1),
        ]),
        throwsA(isA<A2uiStateError>()),
      );
    });

    test('generates client capabilities with inline catalogs', () {
      final Map<String, dynamic> caps = processor.getClientCapabilities(
        includeInlineCatalogs: true,
      );
      final v10 = caps['v1.0'] as Map<String, dynamic>;
      expect(v10['supportedCatalogIds'], contains(catalog.id));

      final inline = v10['inlineCatalogs'] as List;
      final first = inline.first as Map<String, dynamic>;
      expect(first['catalogId'], catalog.id);
      expect(first['components'], contains('Text'));

      // v1.0: functions are a map keyed by function name, with static
      // returnType and callableFrom metadata.
      final functions = first['functions'] as Map<String, dynamic>;
      expect(functions, contains('capitalize'));
      final capitalize = functions['capitalize'] as Map<String, dynamic>;
      expect(capitalize['returnType'], 'string');
      expect(capitalize['callableFrom'], 'clientOnly');
      expect((capitalize['properties'] as Map)['call'], {
        'const': 'capitalize',
      });

      // v1.0: surfaceProperties and unified schemas live under $defs.
      final defs = first[r'$defs'] as Map<String, dynamic>;
      expect(defs, contains('anyComponent'));
      expect(defs, contains('anyFunction'));
      expect(defs, contains('surfaceProperties'));
    });

    test('getClientCapabilities does not corrupt shared schemas', () {
      final Object? descBefore =
          CommonSchemas.dynamicString.value['description'];

      processor.getClientCapabilities(includeInlineCatalogs: true);

      // _processRefs mutates maps in-place to replace REF: descriptions
      // with $ref pointers. If toJsonMap uses a shallow copy, the shared
      // CommonSchemas statics are corrupted.
      expect(
        CommonSchemas.dynamicString.value['description'],
        equals(descBefore),
        reason:
            'CommonSchemas.dynamicString should not be mutated by '
            'getClientCapabilities',
      );
    });

    test('aggregates client data model', () {
      processor.processMessages([
        CreateSurfaceMessage(
          surfaceId: 's1',
          catalogId: catalog.id,
          sendDataModel: true,
        ),
        UpdateDataModelMessage(surfaceId: 's1', path: '/foo', value: 'bar'),
        CreateSurfaceMessage(
          surfaceId: 's2',
          catalogId: catalog.id,
          sendDataModel: false,
        ),
        UpdateDataModelMessage(surfaceId: 's2', path: '/secret', value: 'baz'),
      ]);

      final Map<String, dynamic>? dataModel = processor.getClientDataModel();
      expect(dataModel, isNotNull);
      final surfaces = dataModel?['surfaces'] as Map<String, dynamic>?;
      expect(surfaces, contains('s1'));
      expect(surfaces, isNot(contains('s2')));
      expect(surfaces?['s1'], {'foo': 'bar'});
    });
  });
}
