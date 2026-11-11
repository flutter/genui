// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/basic_functions.dart';
import 'package:genui/src/model/client_function.dart';
import 'package:genui/src/model/data_model.dart';

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BasicFunctions', () {
    late DataContext context;
    late DataModel dataModel;

    setUp(() {
      dataModel = InMemoryDataModel();
      context = DataContext(dataModel, DataPath.root);
    });

    Future<T> run<T>(ClientFunction func, Map<String, Object?> args) async {
      final Stream<Object?> result = func.execute(args, context);
      return (await result.first) as T;
    }

    test('required', () async {
      final RequiredFunction func = BasicFunctions.requiredFunction;
      expect(await run<bool>(func, {'value': 'foo'}), isTrue);
      expect(await run<bool>(func, {'value': ''}), isFalse);
      expect(await run<bool>(func, {'value': null}), isFalse);
      expect(await run<bool>(func, {'value': []}), isFalse);
      expect(
        await run<bool>(func, {
          'value': ['a'],
        }),
        isTrue,
      );
    });

    test('regex', () async {
      final RegexFunction func = BasicFunctions.regexFunction;
      expect(
        await run<bool>(func, {'value': 'hello', 'pattern': '^h.*o\$'}),
        isTrue,
      );
      expect(
        await run<bool>(func, {'value': 'hello', 'pattern': '^w.*d\$'}),
        isFalse,
      );
      expect(
        await run<bool>(func, {'value': null, 'pattern': '.*'}),
        isFalse, // null value doesn't match
      );
    });

    test('length', () async {
      final LengthFunction func = BasicFunctions.lengthFunction;
      expect(await run<int>(func, {'value': 'hello'}), 5);
      expect(
        await run<int>(func, {
          'value': [1, 2, 3],
        }),
        3,
      );
      expect(
        await run<int>(func, {
          'value': {'a': 1, 'b': 2},
        }),
        2,
      );
      expect(await run<int>(func, {'value': null}), 0);
    });

    test('email', () async {
      final EmailFunction func = BasicFunctions.emailFunction;

      // Valid emails (Gmail)
      expect(await run<bool>(func, {'value': 'zhangsan@gmail.com'}), isTrue);
      expect(await run<bool>(func, {'value': 'a@gmail.c'}), isTrue);
      expect(await run<bool>(func, {'value': 'first.last@gmail.com'}), isTrue);
      expect(await run<bool>(func, {'value': 'user+tag@gmail.com'}), isTrue);

      // Invalid emails
      expect(await run<bool>(func, {'value': ''}), isFalse);
      expect(await run<bool>(func, {'value': 'plainaddress'}), isFalse);
      expect(await run<bool>(func, {'value': '@gmail.com'}), isFalse);
      expect(await run<bool>(func, {'value': 'no-domain@'}), isFalse);
      expect(await run<bool>(func, {'value': 'no-tld@gmail'}), isFalse);
      expect(await run<bool>(func, {'value': 'a@gmail@gmail.com'}), isFalse);

      // Non-string values return false
      expect(await run<bool>(func, {'value': null}), isFalse);
      expect(await run<bool>(func, {'value': 123}), isFalse);
      expect(await run<bool>(func, <String, Object?>{}), isFalse);
    });

    test('and', () async {
      final AndFunction func = BasicFunctions.andFunction;
      expect(
        await run<bool>(func, {
          'values': [true, true],
        }),
        isTrue,
      );
      expect(
        await run<bool>(func, {
          'values': [true, false],
        }),
        isFalse,
      );
    });

    test('or', () async {
      final OrFunction func = BasicFunctions.orFunction;
      expect(
        await run<bool>(func, {
          'values': [false, false],
        }),
        isFalse,
      );
      expect(
        await run<bool>(func, {
          'values': [false, true],
        }),
        isTrue,
      );
    });

    test('not', () async {
      final NotFunction func = BasicFunctions.notFunction;
      expect(await run<bool>(func, {'value': true}), isFalse);
      expect(await run<bool>(func, {'value': false}), isTrue);
    });

    test('pluralize', () async {
      final PluralizeFunction func = BasicFunctions.pluralizeFunction;

      // Test with 'value'
      expect(
        await run<String>(func, {
          'value': 0,
          'zero': 'zero items',
          'other': 'other items',
        }),
        'zero items',
      );

      expect(
        await run<String>(func, {
          'value': 1,
          'one': 'one item',
          'other': 'other items',
        }),
        'one item',
      );

      expect(
        await run<String>(func, {'value': 2, 'other': 'other items'}),
        'other items',
      );

      // Test fallback to 'count'
      expect(
        await run<String>(func, {
          'count': 1,
          'one': 'one item',
          'other': 'other items',
        }),
        'one item',
      );

      // Test missing optional categories fall back to 'other'
      expect(
        await run<String>(func, {'value': 0, 'other': 'fallback'}),
        'fallback',
      );

      // Test return empty string if count is not a number
      expect(await run<String>(func, {'value': 'not a number'}), '');
    });

    group('openUrl', () {
      final OpenUrlFunction func = BasicFunctions.openUrlFunction;
      late List<String> checkedUrls;
      late List<String> launchedUrls;
      var canLaunchResult = true;

      setUp(() {
        checkedUrls = <String>[];
        launchedUrls = <String>[];
        canLaunchResult = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_urlLauncherChannel, (
              MethodCall call,
            ) async {
              final args = call.arguments as Map<Object?, Object?>;
              final url = args['url'] as String;
              if (call.method == 'canLaunch') {
                checkedUrls.add(url);
                return canLaunchResult;
              }
              if (call.method == 'launch') {
                launchedUrls.add(url);
                return true;
              }
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_urlLauncherChannel, null);
      });

      test('allows http and https URLs case-insensitively', () async {
        expect(
          await run<bool>(func, {'url': 'https://example.com/docs'}),
          isTrue,
        );
        expect(
          await run<bool>(func, {'url': 'http://localhost:8080/path'}),
          isTrue,
        );
        expect(
          await run<bool>(func, {'url': 'HTTPS://Example.COM/upper'}),
          isTrue,
        );
        await Future<void>.delayed(Duration.zero);

        expect(checkedUrls, <String>[
          'https://example.com/docs',
          'http://localhost:8080/path',
          'https://example.com/upper',
        ]);
        expect(launchedUrls, <String>[
          'https://example.com/docs',
          'http://localhost:8080/path',
          'https://example.com/upper',
        ]);
      });

      test('does not launch when canLaunchUrl returns false', () async {
        canLaunchResult = false;
        expect(await run<bool>(func, {'url': 'https://example.com'}), isTrue);
        await Future<void>.delayed(Duration.zero);

        expect(checkedUrls, <String>['https://example.com']);
        expect(launchedUrls, isEmpty);
      });

      test(
        'ignores asynchronous PlatformException from url_launcher',
        () async {
          var throwOnCanLaunch = true;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(_urlLauncherChannel, (
                MethodCall call,
              ) async {
                if (call.method == 'canLaunch' && throwOnCanLaunch) {
                  throw PlatformException(code: 'CHANNEL_ERROR');
                }
                if (call.method == 'canLaunch') {
                  return true;
                }
                if (call.method == 'launch') {
                  throw PlatformException(code: 'LAUNCH_FAILED');
                }
                return null;
              });

          expect(await run<bool>(func, {'url': 'https://example.com'}), isTrue);
          await Future<void>.delayed(Duration.zero);

          throwOnCanLaunch = false;
          expect(await run<bool>(func, {'url': 'https://example.com'}), isTrue);
          await Future<void>.delayed(Duration.zero);
        },
      );

      test('rejects disallowed schemes and malformed URLs', () async {
        const disallowedUrls = <Object?>[
          'intent://scan/#Intent;scheme=example;package=com.example.app;end',
          'file:///etc/hosts',
          'javascript:alert(1)',
          'data:text/html,<script>alert(1)</script>',
          'mailto:user@example.com',
          'tel:+15551234567',
          'custom-scheme://open',
          '/relative/path',
          'example.com/no-scheme',
          'https:',
          'http:///missing-host',
          '',
          '   ',
          '://invalid',
          null,
          42,
        ];

        for (final url in disallowedUrls) {
          expect(
            await run<bool>(func, {'url': url}),
            isFalse,
            reason: 'Expected $url to be rejected',
          );
        }
        await Future<void>.delayed(Duration.zero);

        expect(checkedUrls, isEmpty);
        expect(launchedUrls, isEmpty);
      });
    });
  });
}
