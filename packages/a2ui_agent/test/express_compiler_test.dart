// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final catalogs = <Catalog<ComponentApi>>[MinimalCatalog()];
  final String catalogId = MinimalCatalog().id;

  ExpressCompiler compiler() => ExpressCompiler(catalogs: catalogs);

  List<Map<String, dynamic>> componentsOf(
    List<AgentToRendererMessage> messages,
  ) => [
    for (final message in messages)
      if (message is UpdateComponentsMessage) ...message.components,
  ];

  group('lexer', () {
    test('reads strings, numbers, booleans, null and paths', () {
      final List<ExpressToken> tokens = ExpressLexer(
        r'x = f("a", 1, -2.5, true, null, $/p/q, ?req, _)',
      ).tokenize();

      expect(tokens.map((token) => token.type).toList(), [
        ExpressTokenType.identifier,
        ExpressTokenType.assign,
        ExpressTokenType.identifier,
        ExpressTokenType.leftParen,
        ExpressTokenType.string,
        ExpressTokenType.comma,
        ExpressTokenType.number,
        ExpressTokenType.comma,
        ExpressTokenType.number,
        ExpressTokenType.comma,
        ExpressTokenType.boolean,
        ExpressTokenType.comma,
        ExpressTokenType.nullLiteral,
        ExpressTokenType.comma,
        ExpressTokenType.path,
        ExpressTokenType.comma,
        ExpressTokenType.check,
        ExpressTokenType.comma,
        ExpressTokenType.underscore,
        ExpressTokenType.rightParen,
        ExpressTokenType.eof,
      ]);
    });

    test('applies escapes in standard strings but not raw strings', () {
      expect(ExpressLexer(r'"a\nb"').tokenize().first.value, 'a\nb');
      expect(ExpressLexer(r'r"a\nb"').tokenize().first.value, r'a\nb');
    });

    test('reads triple-quoted strings across lines', () {
      expect(ExpressLexer('"""a\nb"""').tokenize().first.value, 'a\nb');
    });

    test('skips comments and semicolons', () {
      final List<ExpressToken> tokens = ExpressLexer('''
# a comment
a // trailing
/* block */ ;b
''').tokenize();

      expect(tokens.map((token) => token.lexeme).toList(), ['a', 'b', '']);
    });

    test('tracks line numbers', () {
      final List<ExpressToken> tokens = ExpressLexer('a\n\nb').tokenize();

      expect(tokens[0].line, 1);
      expect(tokens[1].line, 3);
    });

    test('rejects an unterminated string', () {
      expect(
        () => ExpressLexer('"open').tokenize(),
        throwsA(isA<A2uiFormatError>()),
      );
    });
  });

  group('compile', () {
    test('emits createSurface, then components in source order', () {
      final List<AgentToRendererMessage> messages = compiler().compile('''
surface("s1")
root = Column([title, cta])
title = Text("Hello", "h1")
cta = Button(label, Event("go"))
label = Text("Go")
''');

      expect(messages, hasLength(2));
      final created = messages.first as CreateSurfaceMessage;
      expect(created.surfaceId, 's1');
      expect(created.catalogId, catalogId);

      expect(
        componentsOf(messages).map((component) => component['id']).toList(),
        ['root', 'title', 'cta', 'label'],
      );
    });

    test('maps positional arguments through the catalog signature', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('root = Text("Hi", "h2")'),
      );

      expect(components.single, {
        'id': 'root',
        'component': 'Text',
        'text': 'Hi',
        'variant': 'h2',
      });
    });

    test('skips an optional argument written as an underscore', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('root = Column([a], _, "center")\na = Text("x")'),
      );

      expect(components.first.containsKey('justify'), isFalse);
      expect(components.first['align'], 'center');
    });

    test('accepts named arguments mixed with positional ones', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('root = Text("Hi", variant="h3")'),
      );

      expect(components.single['variant'], 'h3');
    });

    test('compiles data paths into bindings', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'root = Text($/user/name)'),
      );

      expect(components.single['text'], {'path': '/user/name'});
    });

    test('keeps a relative path relative', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'root = Text($firstName)'),
      );

      expect(components.single['text'], {'path': 'firstName'});
    });

    test('flattens inline children ahead of their descendants', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('root = Column([Text("a"), Row([Text("b")])])'),
      );

      expect(components.map((component) => component['id']).toList(), [
        'root',
        'root_children0',
        'root_children1',
        'root_children1_children0',
      ]);
      expect(components.first['children'], [
        'root_children0',
        'root_children1',
      ]);
      expect(components[2]['children'], ['root_children1_children0']);
    });

    test('compiles an inline component in a single-child slot', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('root = Button(Text("Go"), Event("go"))'),
      );

      expect(components.first['child'], 'root_child');
      expect(components[1]['text'], 'Go');
    });

    test('compiles a list template', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'''
root = Column(_template($/items, item))
item = Text($label)
'''),
      );

      expect(components.first['children'], {
        'componentId': 'item',
        'path': '/items',
      });
    });

    test('compiles events with a context map', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'''
root = Button(label, Event("save", {rep: $/form/rep, force: true}))
label = Text("Save")
'''),
      );

      expect(components.first['action'], {
        'event': {
          'name': 'save',
          'context': {
            'rep': {'path': '/form/rep'},
            'force': true,
          },
        },
      });
    });

    test('compiles a catalog function call', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'root = Text(capitalize($/name))'),
      );

      expect(components.single['text'], {
        'call': 'capitalize',
        'args': {
          'value': {'path': '/name'},
        },
        'returnType': 'string',
      });
    });

    test('compiles checks, taking the last argument as the message', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'''
root = TextField("Name", [?capitalize($/name, "Must be capitalized")])
'''),
      );

      expect(components.single['checks'], [
        {
          'condition': {
            'call': 'capitalize',
            'args': {
              'value': {'path': '/name'},
            },
            'returnType': 'boolean',
          },
          'message': 'Must be capitalized',
        },
      ]);
    });

    test('supplies a default message for a bare check', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile(r'root = TextField("Name", [?capitalize($/name)])'),
      );

      expect(
        (components.single['checks'] as List).single,
        containsPair('message', 'Failed check: capitalize'),
      );
    });

    test('emits an updateDataModel per data assignment', () {
      final List<AgentToRendererMessage> messages = compiler().compile(r'''
$/title = "Enable notifications"
$/user = {firstName: "Alice", age: 30}
''');

      expect(messages.first, isA<CreateSurfaceMessage>());
      final List<UpdateDataModelMessage> updates = messages
          .whereType<UpdateDataModelMessage>()
          .toList();
      expect(updates, hasLength(2));
      expect(updates.first.path, '/title');
      expect(updates.first.value, 'Enable notifications');
      expect(updates[1].value, {'firstName': 'Alice', 'age': 30});
    });

    test('emits no components when a block only assigns data', () {
      final List<AgentToRendererMessage> messages = compiler().compile(
        r'$/title = "Only data"',
      );

      expect(messages.whereType<UpdateComponentsMessage>(), isEmpty);
    });

    test('uses the default surface when none is named', () {
      final List<AgentToRendererMessage> messages = compiler().compile(
        'root = Text("Hi")',
      );

      expect(
        (messages.first as CreateSurfaceMessage).surfaceId,
        expressDefaultSurfaceId,
      );
    });

    test('takes the catalog id from surface()', () {
      final List<AgentToRendererMessage> messages = compiler().compile(
        'surface("s", "custom-catalog")\nroot = Text("Hi")',
      );

      expect(
        (messages.first as CreateSurfaceMessage).catalogId,
        'custom-catalog',
      );
    });

    test('skips createSurface for a surface the renderer already has', () {
      final compiler = ExpressCompiler(
        catalogs: catalogs,
        existingSurfaceIds: const {'s1'},
      );

      final List<AgentToRendererMessage> messages = compiler.compile(
        'surface("s1")\nroot = Text("Hi")',
      );

      expect(messages.whereType<CreateSurfaceMessage>(), isEmpty);
      expect(messages.single, isA<UpdateComponentsMessage>());
    });

    test('compiles deleteSurface', () {
      final List<AgentToRendererMessage> messages = compiler().compile(
        'deleteSurface("gone")',
      );

      expect((messages.single as DeleteSurfaceMessage).surfaceId, 'gone');
    });

    test('creates one surface across several statement batches', () {
      final ExpressCompiler session = compiler();

      final List<AgentToRendererMessage> first = session.compile(
        'root = Text("a")',
      );
      final List<AgentToRendererMessage> second = session.compile(
        'b = Text("b")',
      );

      expect(first.whereType<CreateSurfaceMessage>(), hasLength(1));
      expect(second.whereType<CreateSurfaceMessage>(), isEmpty);
    });

    test('gives generated ids a fresh name when one is taken', () {
      final List<Map<String, dynamic>> components = componentsOf(
        compiler().compile('''
root_children0 = Text("taken")
root = Column([Text("inline")])
'''),
      );

      expect(components.map((component) => component['id']).toList(), [
        'root_children0',
        'root',
        'root_children02',
      ]);
    });
  });

  group('errors', () {
    test('rejects an unknown component', () {
      expect(
        () => compiler().compile('root = Carousel()'),
        throwsA(
          isA<A2uiFormatError>().having(
            (error) => error.message,
            'message',
            contains("Unknown component 'Carousel'"),
          ),
        ),
      );
    });

    test('rejects a missing required argument', () {
      expect(
        () => compiler().compile('root = Text()'),
        throwsA(
          isA<A2uiFormatError>().having(
            (error) => error.message,
            'message',
            contains("missing required argument 'text'"),
          ),
        ),
      );
    });

    test('rejects too many positional arguments', () {
      expect(
        () => compiler().compile('root = Text("a", "h1", "extra")'),
        throwsA(isA<A2uiFormatError>()),
      );
    });

    test('rejects an unknown parameter name', () {
      expect(
        () => compiler().compile('root = Text("a", nope="x")'),
        throwsA(
          isA<A2uiFormatError>().having(
            (error) => error.message,
            'message',
            contains("no parameter 'nope'"),
          ),
        ),
      );
    });

    test('reports the line a failure happened on', () {
      expect(
        () => compiler().compile('root = Text("a")\nbad = Nope()'),
        throwsA(
          isA<A2uiFormatError>().having((error) => error.line, 'line', 2),
        ),
      );
    });

    test('rejects a standalone call that needs the v1.0 RPC envelope', () {
      expect(
        () => compiler().compile('openUrl("https://example.com")'),
        throwsA(
          isA<A2uiFormatError>().having(
            (error) => error.message,
            'message',
            contains('callFunction'),
          ),
        ),
      );
    });

    test('rejects assigning a non-component to a variable', () {
      expect(
        () => compiler().compile('root = "just text"'),
        throwsA(isA<A2uiFormatError>()),
      );
    });

    test('rejects compiling without a catalog', () {
      expect(
        () => ExpressCompiler(catalogs: const []).compile('root = Text("a")'),
        throwsA(isA<A2uiFormatError>()),
      );
    });

    test('rejects unbalanced syntax', () {
      expect(
        () => compiler().compile('root = Text("a"'),
        throwsA(isA<A2uiFormatError>()),
      );
    });
  });
}
