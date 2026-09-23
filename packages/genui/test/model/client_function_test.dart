// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class _AddSyncFunction extends SynchronousClientFunction {
  const _AddSyncFunction();

  @override
  String get name => 'addSync';

  @override
  String get description => 'Adds two numbers synchronously.';

  @override
  Schema get argumentSchema =>
      S.object(properties: {'a': S.number(), 'b': S.number()});

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.number;

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final num a = args['a'] as num? ?? 0;
    final num b = args['b'] as num? ?? 0;
    return a + b;
  }
}

class _FailSyncFunction extends SynchronousClientFunction {
  const _FailSyncFunction();

  @override
  String get name => 'failSync';

  @override
  String get description => 'Throws synchronously.';

  @override
  Schema get argumentSchema => S.object();

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    throw StateError('Sync failure');
  }
}

class _FetchAsyncFunction extends AsynchronousClientFunction {
  const _FetchAsyncFunction();

  @override
  String get name => 'fetchAsync';

  @override
  String get description => 'Fetches a message asynchronously.';

  @override
  Schema get argumentSchema => S.object(properties: {'prefix': S.string()});

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.string;

  @override
  Future<Object?> executeAsync(JsonMap args, ExecutionContext context) async {
    final String prefix = args['prefix'] as String? ?? '';
    return '$prefix processed async';
  }
}

class _AsyncNullFunction extends AsynchronousClientFunction {
  const _AsyncNullFunction();

  @override
  String get name => 'asyncNull';

  @override
  String get description => 'Returns null asynchronously.';

  @override
  Schema get argumentSchema => S.object();

  @override
  Future<Object?> executeAsync(JsonMap args, ExecutionContext context) async {
    return null;
  }
}

class _AsyncErrorFunction extends AsynchronousClientFunction {
  const _AsyncErrorFunction();

  @override
  String get name => 'asyncError';

  @override
  String get description => 'Throws an error inside Future.';

  @override
  Schema get argumentSchema => S.object();

  @override
  Future<Object?> executeAsync(JsonMap args, ExecutionContext context) async {
    await Future<void>.delayed(Duration.zero);
    throw StateError('Async future error');
  }
}

class _SyncThrowInAsyncFunction extends AsynchronousClientFunction {
  const _SyncThrowInAsyncFunction();

  @override
  String get name => 'syncThrowInAsync';

  @override
  String get description => 'Throws synchronously before returning Future.';

  @override
  Schema get argumentSchema => S.object();

  @override
  Future<Object?> executeAsync(JsonMap args, ExecutionContext context) {
    throw ArgumentError('Sync throw before future');
  }
}

class _LazyTestFunction extends AsynchronousClientFunction {
  _LazyTestFunction(this.onExecute);

  final void Function() onExecute;

  @override
  String get name => 'lazyTest';

  @override
  String get description => 'Tests lazy execution.';

  @override
  Schema get argumentSchema => S.object();

  @override
  Future<Object?> executeAsync(JsonMap args, ExecutionContext context) async {
    onExecute();
    return 'done';
  }
}

void main() {
  group('SynchronousClientFunction', () {
    late DataModel dataModel;
    late DataContext context;

    setUp(() {
      dataModel = InMemoryDataModel();
      context = DataContext(dataModel, DataPath.root);
    });

    test('executes synchronously and emits value on stream', () async {
      const func = _AddSyncFunction();
      final Stream<Object?> stream = func.execute({'a': 2, 'b': 3}, context);

      expect(await stream.first, 5);
      const Object obj = func;
      expect(obj is ClientFunction, isTrue);
      expect(obj is SynchronousClientFunction, isTrue);
      expect(obj is AsynchronousClientFunction, isFalse);
    });

    test('catches synchronous exception and emits error on stream', () async {
      const func = _FailSyncFunction();
      final Stream<Object?> stream = func.execute({}, context);

      expect(
        stream.first,
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'Sync failure'),
        ),
      );
    });
  });

  group('AsynchronousClientFunction', () {
    late DataModel dataModel;
    late DataContext context;

    setUp(() {
      dataModel = InMemoryDataModel();
      context = DataContext(dataModel, DataPath.root);
    });

    test('executes asynchronously and emits future result on stream', () async {
      const func = _FetchAsyncFunction();
      final Stream<Object?> stream = func.execute({'prefix': 'data:'}, context);

      expect(await stream.first, 'data: processed async');
      const Object obj = func;
      expect(obj is ClientFunction, isTrue);
      expect(obj is AsynchronousClientFunction, isTrue);
      expect(obj is SynchronousClientFunction, isFalse);
    });

    test('emits null value on stream when executeAsync returns null', () async {
      const func = _AsyncNullFunction();
      final Stream<Object?> stream = func.execute({}, context);

      expect(await stream.first, isNull);
    });

    test('emits stream error when Future rejects asynchronously', () async {
      const func = _AsyncErrorFunction();
      final Stream<Object?> stream = func.execute({}, context);

      expect(
        stream.first,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Async future error',
          ),
        ),
      );
    });

    test(
      'catches synchronous throw before Future and emits stream error',
      () async {
        const func = _SyncThrowInAsyncFunction();
        final Stream<Object?> stream = func.execute({}, context);

        expect(
          stream.first,
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Sync throw before future',
            ),
          ),
        );
      },
    );

    test(
      'executeAsync is executed lazily only when stream is listened to',
      () async {
        var executed = false;
        final func = _LazyTestFunction(() => executed = true);

        final Stream<Object?> stream = func.execute({}, context);
        expect(executed, isFalse);

        await stream.first;
        expect(executed, isTrue);
      },
    );
  });

  group('Catalog and DataContext integration with Synchronous and Asynchronous '
      'functions', () {
    late DataModel dataModel;
    late DataContext context;
    late Catalog catalog;

    setUp(() {
      catalog = const Catalog(
        [],
        functions: [_AddSyncFunction(), _FetchAsyncFunction()],
      );

      dataModel = InMemoryDataModel();
      context = DataContext(
        dataModel,
        DataPath.root,
        functions: catalog.functions,
      );
    });

    test('Catalog accepts both sync and async functions', () {
      expect(catalog.functions.length, 2);
      expect(context.getFunction('addSync'), isNotNull);
      expect(context.getFunction('fetchAsync'), isNotNull);
    });

    test('resolves asynchronous function call via DataContext', () async {
      final Map<String, Object> input = {
        'call': 'fetchAsync',
        'args': {'prefix': 'Hello'},
      };

      final Stream<Object?> stream = context.resolve(input);
      expect(await stream.first, 'Hello processed async');
    });

    test('resolves sync function call via DataContext', () async {
      final Map<String, Object> input = {
        'call': 'addSync',
        'args': {'a': 10, 'b': 25},
      };

      final Stream<Object?> stream = context.resolve(input);
      expect(await stream.first, 35);
    });
  });
}
