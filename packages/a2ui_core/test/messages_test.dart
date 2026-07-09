// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiMessage.fromJson', () {
    test('parses createSurface', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's1',
          'catalogId': 'cat1',
          'surfaceProperties': {'agentDisplayName': 'My Agent'},
          'sendDataModel': true,
        },
      });

      expect(msg, isA<CreateSurfaceMessage>());
      final cs = msg as CreateSurfaceMessage;
      expect(cs.surfaceId, 's1');
      expect(cs.catalogId, 'cat1');
      expect(cs.surfaceProperties, {'agentDisplayName': 'My Agent'});
      expect(cs.sendDataModel, true);
      expect(cs.version, 'v1.0');
    });

    test('parses createSurface with defaults', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'createSurface': {'surfaceId': 's1', 'catalogId': 'cat1'},
      });

      final cs = msg as CreateSurfaceMessage;
      expect(cs.surfaceProperties, isNull);
      expect(cs.sendDataModel, false);
      expect(cs.components, isNull);
      expect(cs.dataModel, isNull);
    });

    test('parses createSurface with inline components and dataModel', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's1',
          'catalogId': 'cat1',
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 'Hello'},
          ],
          'dataModel': {
            'user': {'name': 'Alice'},
          },
        },
      });

      final cs = msg as CreateSurfaceMessage;
      expect(cs.components, hasLength(1));
      expect(cs.components![0]['id'], 'root');
      expect(cs.dataModel, {
        'user': {'name': 'Alice'},
      });
    });

    test('parses updateComponents', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'updateComponents': {
          'surfaceId': 's1',
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 'Hello'},
          ],
        },
      });

      expect(msg, isA<UpdateComponentsMessage>());
      final uc = msg as UpdateComponentsMessage;
      expect(uc.surfaceId, 's1');
      expect(uc.components, hasLength(1));
      expect(uc.components[0]['text'], 'Hello');
    });

    test('parses updateDataModel', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'updateDataModel': {
          'surfaceId': 's1',
          'path': '/user/name',
          'value': 'Alice',
        },
      });

      expect(msg, isA<UpdateDataModelMessage>());
      final ud = msg as UpdateDataModelMessage;
      expect(ud.surfaceId, 's1');
      expect(ud.path, '/user/name');
      expect(ud.value, 'Alice');
    });

    test('parses updateDataModel without path or value', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'updateDataModel': {'surfaceId': 's1'},
      });

      final ud = msg as UpdateDataModelMessage;
      expect(ud.path, isNull);
      expect(ud.value, isNull);
    });

    test('serializes an explicit null value for updateDataModel deletion', () {
      final msg = UpdateDataModelMessage(surfaceId: 's1', path: '/user/name');
      final Map<String, dynamic> json = msg.toJson();
      final body = json['updateDataModel'] as Map<String, dynamic>;
      expect(body.containsKey('value'), isTrue);
      expect(body['value'], isNull);
    });

    test('parses deleteSurface', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'deleteSurface': {'surfaceId': 's1'},
      });

      expect(msg, isA<DeleteSurfaceMessage>());
      final ds = msg as DeleteSurfaceMessage;
      expect(ds.surfaceId, 's1');
    });

    test('parses callFunction', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'functionCallId': 'fc-1',
        'wantResponse': true,
        'callFunction': {
          'call': 'capitalize',
          'args': {'value': 'hello'},
        },
      });

      expect(msg, isA<CallFunctionMessage>());
      final cf = msg as CallFunctionMessage;
      expect(cf.functionCallId, 'fc-1');
      expect(cf.wantResponse, true);
      expect(cf.call, 'capitalize');
      expect(cf.args, {'value': 'hello'});
    });

    test('throws on callFunction without functionCallId', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 'v1.0',
          'callFunction': {'call': 'capitalize'},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('parses actionResponse with a value', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'actionId': 'a-1',
        'actionResponse': {'value': 42},
      });

      expect(msg, isA<ActionResponseMessage>());
      final ar = msg as ActionResponseMessage;
      expect(ar.actionId, 'a-1');
      expect(ar.hasValue, isTrue);
      expect(ar.value, 42);
      expect(ar.error, isNull);
    });

    test('parses actionResponse with an error', () {
      final msg = A2uiMessage.fromJson({
        'version': 'v1.0',
        'actionId': 'a-1',
        'actionResponse': {
          'error': {'code': 'NOT_FOUND', 'message': 'No such item.'},
        },
      });

      final ar = msg as ActionResponseMessage;
      expect(ar.hasValue, isFalse);
      expect(ar.error, isNotNull);
      expect(ar.error!.code, 'NOT_FOUND');
      expect(ar.error!.message, 'No such item.');
    });

    test('throws on actionResponse with both value and error', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 'v1.0',
          'actionId': 'a-1',
          'actionResponse': {
            'value': 42,
            'error': {'code': 'X', 'message': 'Y'},
          },
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws on unknown message type', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 'v1.0',
          'unknownType': {'surfaceId': 's1'},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws when version field is missing', () {
      expect(
        () => A2uiMessage.fromJson({
          'createSurface': {'surfaceId': 's1', 'catalogId': 'c1'},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws when version is not v1.0', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {'surfaceId': 's1', 'catalogId': 'c1'},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws when version is not a string', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 123,
          'createSurface': {'surfaceId': 's1', 'catalogId': 'c1'},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('throws when more than one message type is present', () {
      expect(
        () => A2uiMessage.fromJson({
          'version': 'v1.0',
          'createSurface': {'surfaceId': 's1', 'catalogId': 'c1'},
          'updateComponents': {'surfaceId': 's1', 'components': <Object?>[]},
        }),
        throwsA(isA<A2uiValidationError>()),
      );
    });

    test('roundtrips through toJson/fromJson', () {
      final original = CreateSurfaceMessage(
        surfaceId: 's1',
        catalogId: 'cat1',
        surfaceProperties: {'agentDisplayName': 'Agent'},
        sendDataModel: true,
        components: [
          {'id': 'root', 'component': 'Text', 'text': 'Hi'},
        ],
        dataModel: {'name': 'Alice'},
      );

      final roundtripped = A2uiMessage.fromJson(original.toJson());
      expect(roundtripped, isA<CreateSurfaceMessage>());
      final cs = roundtripped as CreateSurfaceMessage;
      expect(cs.surfaceId, 's1');
      expect(cs.catalogId, 'cat1');
      expect(cs.surfaceProperties, {'agentDisplayName': 'Agent'});
      expect(cs.sendDataModel, true);
      expect(cs.components, hasLength(1));
      expect(cs.dataModel, {'name': 'Alice'});
    });

    test('roundtrips callFunction through toJson/fromJson', () {
      final original = CallFunctionMessage(
        functionCallId: 'fc-9',
        wantResponse: true,
        call: 'capitalize',
        args: {'value': 'x'},
      );

      final roundtripped =
          A2uiMessage.fromJson(original.toJson()) as CallFunctionMessage;
      expect(roundtripped.functionCallId, 'fc-9');
      expect(roundtripped.wantResponse, true);
      expect(roundtripped.call, 'capitalize');
      expect(roundtripped.args, {'value': 'x'});
    });

    test('roundtrips actionResponse through toJson/fromJson', () {
      final original = ActionResponseMessage(actionId: 'a-9', value: null);

      final roundtripped =
          A2uiMessage.fromJson(original.toJson()) as ActionResponseMessage;
      expect(roundtripped.actionId, 'a-9');
      expect(roundtripped.hasValue, isTrue);
      expect(roundtripped.value, isNull);
    });
  });

  group('A2uiClientAction', () {
    test('serializes actionId and wantResponse when set', () {
      final action = A2uiClientAction(
        name: 'submit',
        surfaceId: 's1',
        sourceComponentId: 'button1',
        timestamp: DateTime.utc(2026),
        context: {'a': 1},
        wantResponse: true,
        actionId: 'act-1',
      );

      final Map<String, dynamic> json = action.toJson();
      expect(json['wantResponse'], true);
      expect(json['actionId'], 'act-1');
    });

    test('omits actionId and wantResponse by default', () {
      final action = A2uiClientAction(
        name: 'submit',
        surfaceId: 's1',
        sourceComponentId: 'button1',
        timestamp: DateTime.utc(2026),
        context: {},
      );

      final Map<String, dynamic> json = action.toJson();
      expect(json.containsKey('wantResponse'), isFalse);
      expect(json.containsKey('actionId'), isFalse);
    });
  });

  group('A2uiFunctionResponse', () {
    test('serializes functionCallId, call, and value', () {
      final response = A2uiFunctionResponse(
        functionCallId: 'fc-1',
        call: 'capitalize',
        value: 'Hello',
      );

      expect(response.toJson(), {
        'functionCallId': 'fc-1',
        'call': 'capitalize',
        'value': 'Hello',
      });
    });
  });

  group('A2uiClientError', () {
    test('serializes surface-scoped errors', () {
      final error = A2uiClientError(
        code: 'VALIDATION_FAILED',
        surfaceId: 's1',
        message: 'Bad input.',
      );

      final Map<String, dynamic> json = error.toJson();
      expect(json['surfaceId'], 's1');
      expect(json.containsKey('functionCallId'), isFalse);
    });

    test('serializes function-call-scoped errors', () {
      final error = A2uiClientError(
        code: 'INVALID_FUNCTION_CALL',
        functionCallId: 'fc-1',
        message: 'Not callable remotely.',
      );

      final Map<String, dynamic> json = error.toJson();
      expect(json['functionCallId'], 'fc-1');
      expect(json.containsKey('surfaceId'), isFalse);
    });

    test('asserts on both surfaceId and functionCallId', () {
      expect(
        () => A2uiClientError(
          code: 'X',
          surfaceId: 's1',
          functionCallId: 'fc-1',
          message: 'm',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
