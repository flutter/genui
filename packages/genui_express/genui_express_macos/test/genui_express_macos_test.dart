// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_express_macos/genui_express_macos.dart';
import 'package:genui_express_platform_interface/genui_express_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenuiExpressMacos', () {
    late GenuiExpressMacos platform;
    final log = <MethodCall>[];

    setUp(() {
      platform = GenuiExpressMacos();
      log.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('genui_express/local_ai'),
            (MethodCall methodCall) async {
              log.add(methodCall);
              if (methodCall.method == 'checkAvailability') {
                return true;
              }
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('genui_express/local_ai'),
            null,
          );
    });

    test('registers itself as GenuiExpressPlatform.instance', () {
      GenuiExpressMacos.registerWith();
      expect(GenuiExpressPlatform.instance, isA<GenuiExpressMacos>());
    });

    test('checkAvailability returns true from native call', () async {
      final bool result = await platform.checkAvailability();
      expect(result, isTrue);
      expect(log, <Matcher>[
        isMethodCall('checkAvailability', arguments: null),
      ]);
    });

    test(
      'generateStream receives broadcast events from event channel',
      () async {
        const mockPrompt = 'Hello local LLM';
        const mockSystemPrompt = 'You are a helpful assistant';

        // Setup mock EventChannel data
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              const EventChannel('genui_express/local_ai_stream'),
              InlineMockStreamHandler(
                onListenCall: (arguments, events) {
                  expect(arguments, <String, Object?>{
                    'prompt': mockPrompt,
                    'systemPrompt': mockSystemPrompt,
                  });
                  events.success('Chunk 1');
                  events.success('Chunk 2');
                  events.endOfStream();
                },
                onCancelCall: (arguments) {},
              ),
            );

        final List<String> received = await platform
            .generateStream(mockPrompt, mockSystemPrompt)
            .toList();

        expect(received, <String>['Chunk 1', 'Chunk 2']);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              const EventChannel('genui_express/local_ai_stream'),
              null,
            );
      },
    );
  });
}

class InlineMockStreamHandler extends MockStreamHandler {
  final void Function(Object? arguments, MockStreamHandlerEventSink events)
  onListenCall;
  final void Function(Object? arguments) onCancelCall;

  InlineMockStreamHandler({
    required this.onListenCall,
    required this.onCancelCall,
  });

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    onListenCall(arguments, events);
  }

  @override
  void onCancel(Object? arguments) {
    onCancelCall(arguments);
  }
}
