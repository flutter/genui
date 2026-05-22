// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:express_chat/express/compiler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

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
      final ast = parser.parseExpression() as Map<String, dynamic>;

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

      final Map<String, dynamic> envelope = compiler.compile(
        dsl,
        surfaceId: 'test_surf',
      );
      expect(envelope['version'], 'v0.9');
      final createSurface = envelope['createSurface'] as Map<String, dynamic>;
      expect(createSurface['surfaceId'], 'test_surf');

      final List<Map<String, dynamic>> components =
          (createSurface['components'] as List).cast<Map<String, dynamic>>();
      expect(components, hasLength(3));

      final Map<String, dynamic> rootComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(rootComp['component'], 'Column');
      expect(rootComp['children'], ['repField', 'valueField']);

      final Map<String, dynamic> repComp = components.firstWhere(
        (c) => c['id'] == 'repField',
      );
      expect(repComp['component'], 'TextField');
      expect(repComp['label'], 'Representative');
      expect(repComp['value'], {'path': '/form/rep'});

      final Map<String, dynamic> valComp = components.firstWhere(
        (c) => c['id'] == 'valueField',
      );
      expect(valComp['component'], 'TextField');
      expect(valComp['label'], 'Deal Value');
      expect(valComp['value'], {'path': '/form/value'});
      expect(valComp['variant'], 'number');

      // Verify implicit path validation injection
      final checks = valComp['checks'] as List<Object?>;
      expect(checks, hasLength(1));
      final firstCheck = checks[0] as Map<String, dynamic>;
      final condition = firstCheck['condition'] as Map<String, dynamic>;
      expect(condition['call'], 'required');
      final conditionArgs = condition['args'] as Map<String, dynamic>;
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

      final Map<String, dynamic> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> components =
          (createSurface['components'] as List).cast<Map<String, dynamic>>();

      final Map<String, dynamic> welcomeComp = components.firstWhere(
        (c) => c['id'] == 'welcome',
      );
      expect(welcomeComp['text'], {
        'call': 'formatString',
        'args': {'value': 'Welcome, \${/user/name}!'},
        'returnType': 'string',
      });

      final Map<String, dynamic> buttonComp = components.firstWhere(
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

      final Map<String, dynamic> envelope = compiler.compile(dsl);
      expect(envelope['version'], 'v0.9');
      final createSurface = envelope['createSurface'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> components =
          (createSurface['components'] as List).cast<Map<String, dynamic>>();

      expect(components, hasLength(2));

      final Map<String, dynamic> textComp = components.firstWhere(
        (c) => c['id'] == 'txt_root_0',
      );
      expect(textComp['component'], 'Text');
      expect(textComp['text'], 'Submit');

      final Map<String, dynamic> buttonComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(buttonComp['component'], 'Button');
      expect(buttonComp['child'], 'txt_root_0');
      expect(buttonComp['action'], {
        'event': {'name': 'Send Request', 'context': const <String, dynamic>{}},
      });
    });

    test('compile inline nested components without re-wrapping', () {
      const dsl = 'root = Column([Text("Hello")])';

      final Map<String, dynamic> envelope = compiler.compile(dsl);
      final createSurface = envelope['createSurface'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> components =
          (createSurface['components'] as List).cast<Map<String, dynamic>>();

      expect(components, hasLength(2));

      final Map<String, dynamic> colComp = components.firstWhere(
        (c) => c['id'] == 'root',
      );
      expect(colComp['component'], 'Column');
      expect(colComp['children'], ['inline_Text_0']);

      final Map<String, dynamic> textComp = components.firstWhere(
        (c) => c['id'] == 'inline_Text_0',
      );
      expect(textComp['component'], 'Text');
      expect(textComp['text'], 'Hello');
    });
  });
}
