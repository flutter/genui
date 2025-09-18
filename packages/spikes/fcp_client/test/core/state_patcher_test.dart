// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/core/fcp_state.dart';
import 'package:fcp_client/src/core/state_patcher.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_patch/json_patch.dart';

void main() {
  group('StatePatcher', () {
    late FcpState state;
    late StatePatcher patcher;

    setUp(() {
      state = FcpState(
        {
          'user': {
            'name': 'Alice',
            'email': 'alice@example.com',
            'details': {'level': 5, 'points': 100},
          },
          'tags': ['a', 'b'],
          'config': {'setting': 'value'},
        },
        validator: DataTypeValidator(),
        catalog: WidgetCatalog.fromMap({
          'catalogVersion': '1.0.0',
          'items': <String, Object?>{},
          'dataTypes': <String, Object?>{},
        }),
      );
      patcher = StatePatcher();
    });

    test('applies a "update" operation correctly', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/user/name', 'value': 'Bob'},
        ],
      });

      patcher.apply(state, update);

      expect(state.getValue('user.name'), 'Bob');
    });

    test('applies an "add" operation to a list', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'add', 'path': '/tags/-', 'value': 'c'},
        ],
      });

      patcher.apply(state, update);

      expect(state.getValue('tags'), ['a', 'b', 'c']);
    });

    test('applies a "remove" operation from a list', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'remove', 'path': '/tags/0'},
        ],
      });

      patcher.apply(state, update);

      expect(state.getValue('tags'), ['b']);
    });

    test('applies a "copy" operation', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'copy', 'from': '/user/name', 'path': '/user/alias'},
        ],
      });
      patcher.apply(state, update);
      expect(state.getValue('user.alias'), 'Alice');
    });

    test('applies a "move" operation', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'move', 'from': '/config', 'path': '/user/config'},
        ],
      });
      patcher.apply(state, update);
      expect(state.getValue('config'), isNull);
      expect(state.getValue('user.config'), {'setting': 'value'});
    });

    test('applies a "test" operation successfully', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'test', 'path': '/user/name', 'value': 'Alice'},
        ],
      });
      // Should not throw
      patcher.apply(state, update);
    });

    test(
      'throws JsonPatchTestFailedException for a failing "test" operation',
      () {
        final update = StateUpdate.fromMap({
          'patches': [
            {'op': 'test', 'path': '/user/name', 'value': 'WrongValue'},
          ],
        });
        expect(
          () => patcher.apply(state, update),
          throwsA(isA<JsonPatchTestFailedException>()),
        );
      },
    );

    test('applies patch to a deeply nested property', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/user/details/points', 'value': 150},
        ],
      });
      patcher.apply(state, update);
      expect(state.getValue('user.details.points'), 150);
    });

    test('throws JsonPatchError for invalid path in "replace"', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/user/nonexistent/path', 'value': 'new'},
        ],
      });
      expect(
        () => patcher.apply(state, update),
        throwsA(isA<JsonPatchError>()),
      );
    });

    test('throws JsonPatchError for invalid path in "remove"', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'remove', 'path': '/nonexistent'},
        ],
      });
      expect(
        () => patcher.apply(state, update),
        throwsA(isA<JsonPatchError>()),
      );
    });

    test('applies multiple operations', () {
      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/user/email', 'value': 'new@example.com'},
          {'op': 'add', 'path': '/user/age', 'value': 30},
        ],
      });

      patcher.apply(state, update);

      final user = state.getValue('user') as Map;
      expect(user['email'], 'new@example.com');
      expect(user['age'], 30);
    });

    test('notifies listeners after applying patch', () {
      var notified = false;
      state.addListener(() {
        notified = true;
      });

      final update = StateUpdate.fromMap({
        'patches': [
          {'op': 'replace', 'path': '/user/name', 'value': 'Charlie'},
        ],
      });

      patcher.apply(state, update);

      expect(notified, isTrue);
    });
  });
}
