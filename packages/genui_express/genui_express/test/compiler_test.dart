// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_express/genui_express.dart';
import 'package:genui_express/src/compiler/parser.dart';
import 'package:genui_express/src/compiler/token.dart';

void main() {
  group('A2UI Express Tokenizer & Parser', () {
    test('tokenize basic assignment', () {
      const dsl = 'root = Column([welcome, saveButton])';
      final List<Token> tokens = tokenize(dsl.split('=').last.trim());
      expect(tokens, hasLength(8));
      expect(tokens[0].kind, TokenKind.identifier);
      expect(tokens[0].value, 'Column');
      expect(tokens[1].kind, TokenKind.lparen);
      expect(tokens[2].kind, TokenKind.lbracket);
      expect(tokens[3].kind, TokenKind.identifier);
      expect(tokens[3].value, 'welcome');
      expect(tokens[4].kind, TokenKind.comma);
      expect(tokens[5].kind, TokenKind.identifier);
      expect(tokens[5].value, 'saveButton');
      expect(tokens[6].kind, TokenKind.rbracket);
      expect(tokens[7].kind, TokenKind.rparen);
    });

    test('parse expressions with primitives, paths, checks, events', () {
      final List<Token> tokens = tokenize(
        'TextField(\$/form/value, "Deal Value", "number", ?required)',
      );
      final parser = TokenParser(tokens);
      final ast = parser.parseExpression() as Map<String, Object?>;

      expect(ast['call'], 'TextField');
      final args = ast['args'] as List<Object?>;
      expect(args, hasLength(4));
      expect(args[0], {'path': '/form/value'});
      expect(args[1], 'Deal Value');
      expect(args[2], 'number');
      expect(args[3], {'check': 'required', 'args': <Object?>[]});
    });
  });

  group('ExpressCompiler', () {
    late Catalog catalog;
    late ExpressCompiler compiler;

    setUp(() {
      catalog = BasicCatalogItems.asNoAssetCatalog();
      compiler = ExpressCompiler(catalog);
    });

    test('compile basic component hierarchy', () {
      const dsl = '''
root = Column([repField, valueField])
repField = TextField(\$/form/rep, "Representative")
valueField = TextField(\$/form/value, "Deal Value", "number", ?required)
''';

      final Map<String, Object?> envelope = compiler.compile(
        dsl,
        surfaceId: 'test_surf',
      );
      expect(envelope['version'], 'v0.9');
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      expect(createSurface['surfaceId'], 'test_surf');

      final List<Map<String, Object?>> components =
          (createSurface['components'] as List).cast<Map<String, Object?>>();
      expect(components, hasLength(3));

      final Map<String, Object?> rootComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(rootComp['component'], 'Column');
      expect(rootComp['children'], ['repField', 'valueField']);

      final Map<String, Object?> repComp = components.firstWhere(
        (c) => c['id'] == 'repField',
      );
      expect(repComp['component'], 'TextField');
      expect(repComp['label'], 'Representative');
      expect(repComp['value'], {'path': '/form/rep'});

      final Map<String, Object?> valComp = components.firstWhere(
        (c) => c['id'] == 'valueField',
      );
      expect(valComp['component'], 'TextField');
      expect(valComp['label'], 'Deal Value');
      expect(valComp['value'], {'path': '/form/value'});
      expect(valComp['variant'], 'number');

      // Verify implicit path validation injection
      final checks = valComp['checks'] as List<Object?>;
      expect(checks, hasLength(1));
      final firstCheck = checks[0] as Map<String, Object?>;
      final condition = firstCheck['condition'] as Map<String, Object?>;
      expect(condition['call'], 'required');
      final conditionArgs = condition['args'] as Map<String, Object?>;
      expect(conditionArgs['value'], {'path': '/form/value'});
      expect(firstCheck['message'], 'Required check failed');
    });

    test('compile format string and action events', () {
      const dsl = '''
root = Column([welcome, saveButton])
welcome = Text(formatString("Welcome, \${/user/name}!"))
saveButton = Button(saveLabel, Event("submitDeal", {rep: \$/form/rep}), "primary")
saveLabel = Text("Save")
''';

      final Map<String, Object?> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      final List<Map<String, Object?>> components =
          (createSurface['components'] as List).cast<Map<String, Object?>>();

      final Map<String, Object?> welcomeComp = components.firstWhere(
        (c) => c['id'] == 'welcome',
      );
      expect(welcomeComp['text'], {
        'call': 'formatString',
        'args': {'value': 'Welcome, \${/user/name}!'},
        'returnType': 'string',
      });

      final Map<String, Object?> buttonComp = components.firstWhere(
        (c) => c['id'] == 'saveButton',
      );
      expect(buttonComp['variant'], 'primary');
      expect(buttonComp['action'], {
        'event': {
          'name': 'submitDeal',
          'context': {
            'rep': {'path': '/form/rep'},
          },
        },
      });
    });

    test('resilient compile of missing root and auto-wrapping strings', () {
      const dsl = 'submit_button = Button("Submit", "Send Request")';

      final Map<String, Object?> envelope = compiler.compile(dsl);
      expect(envelope['version'], 'v0.9');
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      final List<Map<String, Object?>> components =
          (createSurface['components'] as List).cast<Map<String, Object?>>();

      expect(components, hasLength(2));

      final Map<String, Object?> textComp = components.firstWhere(
        (c) => c['id'] == 'txt_root_0',
      );
      expect(textComp['component'], 'Text');
      expect(textComp['text'], 'Submit');

      final Map<String, Object?> buttonComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(buttonComp['component'], 'Button');
      expect(buttonComp['child'], 'txt_root_0');
      expect(buttonComp['action'], {
        'event': {'name': 'Send Request', 'context': const <String, Object?>{}},
      });
    });

    test('compile inline nested components without re-wrapping', () {
      const dsl = 'root = Column([Text("Hello")])';

      final Map<String, Object?> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      final List<Map<String, Object?>> components =
          (createSurface['components'] as List).cast<Map<String, Object?>>();

      expect(components, hasLength(2));

      final Map<String, Object?> colComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(colComp['component'], 'Column');
      expect(colComp['children'], ['inline_Text_0']);

      final Map<String, Object?> textComp = components.firstWhere(
        (c) => c['id'] == 'inline_Text_0',
      );
      expect(textComp['component'], 'Text');
      expect(textComp['text'], 'Hello');
    });

    test('compile formatted multi-line statements', () {
      const dsl = '''
root = Column([
  Text("Line 1"),
  Text("Line 2")
])
''';

      final Map<String, Object?> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      final List<Map<String, Object?>> components =
          (createSurface['components'] as List).cast<Map<String, Object?>>();

      expect(components, hasLength(3));

      final Map<String, Object?> colComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(colComp['component'], 'Column');
      expect(colComp['children'], ['inline_Text_0', 'inline_Text_1']);
    });

    test('compile absolute data model assignments', () {
      const dsl = '''
root = Text("Status")
\$/icon = "check"
\$/user/profile/firstName = "Alice"
\$/user/profile/age = 30
''';

      final Map<String, Object?> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, Object?>;
      final dataModel = createSurface['dataModel'] as Map<String, Object?>;

      expect(dataModel, {
        'icon': 'check',
        'user': {
          'profile': {'firstName': 'Alice', 'age': 30},
        },
      });
    });
  });

  group('ExpressDecompiler', () {
    late Catalog catalog;
    late ExpressDecompiler decompiler;
    late ExpressCompiler compiler;

    setUp(() {
      catalog = BasicCatalogItems.asNoAssetCatalog();
      decompiler = ExpressDecompiler(catalog);
      compiler = ExpressCompiler(catalog);
    });

    test('decompile basic component hierarchy', () {
      final Map<String, Object?> originalEnvelope = {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'surf_1',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['repField', 'valueField'],
            },
            {
              'id': 'repField',
              'component': 'TextField',
              'value': {'path': '/form/rep'},
              'label': 'Representative',
            },
            {
              'id': 'valueField',
              'component': 'TextField',
              'value': {'path': '/form/value'},
              'label': 'Deal Value',
              'variant': 'number',
              'checks': [
                {
                  'condition': {
                    'call': 'required',
                    'args': {
                      'value': {'path': '/form/value'},
                    },
                  },
                  'message': 'Required check failed',
                },
              ],
            },
          ],
          'dataModel': {
            'form': {'rep': 'John Doe', 'value': 1500.0},
          },
        },
      };

      final String dsl = decompiler.decompile(originalEnvelope);
      expect(dsl, contains('root = Column([repField, valueField])'));
      expect(
        dsl,
        contains('repField = TextField(\$/form/rep, "Representative")'),
      );
      expect(
        dsl,
        contains(
          'valueField = TextField(\$/form/value, "Deal Value", "number", ?required)',
        ),
      );
      expect(dsl, contains('\$/form/rep = "John Doe"'));
      expect(dsl, contains('\$/form/value = 1500.0'));

      // Verify round-trip compilation works
      final Map<String, Object?> recompiled = compiler.compile(
        dsl,
        surfaceId: 'surf_1',
      );
      expect(recompiled['version'], 'v0.9');
      final createSurface = recompiled['createSurface'] as Map<String, Object?>;
      final recompiledData = createSurface['dataModel'] as Map<String, Object?>;
      expect(recompiledData['form'], {'rep': 'John Doe', 'value': 1500.0});
    });
  });
}
