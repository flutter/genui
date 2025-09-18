// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:gulf_client/src/models/component.dart';
import 'package:gulf_client/src/models/data_node.dart';
import 'package:gulf_client/src/models/stream_message.dart';

void main() {
  group('GULF Models', () {
    test('Component can be serialized and deserialized', () {
      const component = Component(
        id: 'test',
        type: 'Text',
        value: Value(literalString: 'Hello'),
      );
      final json = component.toJson();
      final newComponent = Component.fromJson(json);
      expect(newComponent, component);
    });

    test('DataModelNode can be serialized and deserialized', () {
      const node = DataModelNode(id: 'root', children: {'user': 'user_node'});
      final json = node.toJson();
      final newNode = DataModelNode.fromJson(json);
      expect(newNode, node);
    });

    test('GulfStreamMessage can be serialized and deserialized', () {
      const message = StreamHeader(version: '1.0.0');
      final json = message.toJson();
      final newMessage = GulfStreamMessage.fromJson(json);
      expect(newMessage, message);
    });

    test('ComponentUpdate can be serialized and deserialized', () {
      const message = ComponentUpdate(
        components: [Component(id: 'test', type: 'Text')],
      );
      final json = message.toJson();
      final newMessage = GulfStreamMessage.fromJson(json);
      expect(newMessage, message);
    });

    test('DataModelUpdate can be serialized and deserialized', () {
      const message = DataModelUpdate(nodes: [DataModelNode(id: 'root')]);
      final json = message.toJson();
      final newMessage = GulfStreamMessage.fromJson(json);
      expect(newMessage, message);
    });

    test('UiRoot can be serialized and deserialized', () {
      const message = UiRoot(root: 'root', dataModelRoot: 'data_root');
      final json = message.toJson();
      final newMessage = GulfStreamMessage.fromJson(json);
      expect(newMessage, message);
    });
  });
}
