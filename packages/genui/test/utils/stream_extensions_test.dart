// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/utils/stream_extensions.dart';

void main() {
  group('SwitchMapExtension', () {
    test('switchMap maps and switches streams', () async {
      final controller = StreamController<int>();
      final innerControllers = <StreamController<String>>[];

      final Stream<String> resultStream = controller.stream.switchMap((val) {
        final inner = StreamController<String>();
        innerControllers.add(inner);
        return inner.stream;
      });

      final emitted = <String>[];
      final StreamSubscription<String> subscription = resultStream.listen(
        emitted.add,
      );

      controller.add(1);
      await Future<void>.value();
      innerControllers[0].add('a');
      await Future<void>.value();
      expect(emitted, ['a']);

      controller.add(2);
      await Future<void>.value();
      innerControllers[0].add('b');
      innerControllers[1].add('c');
      await Future<void>.value();
      expect(emitted, ['a', 'c']);

      await subscription.cancel();
      await controller.close();
    });

    test('outer stream error is forwarded', () async {
      final controller = StreamController<int>();
      final Stream<String> resultStream = controller.stream.switchMap(
        (val) => Stream.value('a'),
      );

      final List<dynamic> errors = [];
      resultStream.listen((_) {}, onError: errors.add);

      controller.addError('outer error');
      await Future<void>.value();
      expect(errors, ['outer error']);
      await controller.close();
    });

    test(
      'outer stream done closes controller when no inner stream is active',
      () async {
        final controller = StreamController<int>();
        final Stream<String> resultStream = controller.stream.switchMap(
          (val) => const Stream<String>.empty(),
        );

        final completer = Completer<void>();
        resultStream.listen((_) {}, onDone: completer.complete);

        await controller.close();
        await completer.future;
      },
    );

    test(
      'inner stream done closes controller if outer stream is already done',
      () async {
        final controller = StreamController<int>();
        final innerController = StreamController<String>();
        final Stream<String> resultStream = controller.stream.switchMap(
          (val) => innerController.stream,
        );

        final completer = Completer<void>();
        resultStream.listen((_) {}, onDone: completer.complete);

        controller.add(1);
        await Future<void>.value();

        await controller.close();
        expect(completer.isCompleted, isFalse);

        await innerController.close();
        await completer.future;
      },
    );

    test('pause and resume are propagated to subscriptions', () async {
      final controller = StreamController<int>();
      final innerController = StreamController<String>();

      final Stream<String> resultStream = controller.stream.switchMap((val) {
        return innerController.stream;
      });

      final emitted = <String>[];
      final StreamSubscription<String> subscription = resultStream.listen(
        emitted.add,
      );

      controller.add(1);
      await Future<void>.value();

      expect(controller.isPaused, isFalse);
      expect(innerController.isPaused, isFalse);

      subscription.pause();
      // Allow event loop to process pause commands
      await Future<void>.value();

      expect(controller.isPaused, isTrue);
      expect(innerController.isPaused, isTrue);

      subscription.resume();
      await Future<void>.value();

      expect(controller.isPaused, isFalse);
      expect(innerController.isPaused, isFalse);

      await subscription.cancel();
      await controller.close();
      await innerController.close();
    });
  });
}
