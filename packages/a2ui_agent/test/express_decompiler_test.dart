// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  final catalogs = <Catalog<ComponentApi>>[MinimalCatalog()];
  final decompiler = ExpressDecompiler(catalogs: catalogs);

  ExpressCompiler compiler() => ExpressCompiler(catalogs: catalogs);

  /// Compiles [source], decompiles the result, and compiles it again.
  ///
  /// A format that cannot survive this loses information every time an agent
  /// turns an example payload into a prompt.
  void expectRoundTrip(String source) {
    final List<AgentToRendererMessage> first = compiler().compile(source);
    final String express = decompiler.decompile(first);
    final List<AgentToRendererMessage> second = compiler().compile(express);

    expect(
      second.map((message) => message.toJson()).toList(),
      first.map((message) => message.toJson()).toList(),
      reason: 'decompiled to:\n$express',
    );
  }

  group('decompile', () {
    test('renders a surface directive', () {
      expect(
        decompiler.decompile([
          CreateSurfaceMessage(surfaceId: 's', catalogId: 'cat'),
        ]),
        'surface("s", "cat")',
      );
    });

    test('renders deleteSurface', () {
      expect(
        decompiler.decompile([DeleteSurfaceMessage(surfaceId: 's')]),
        'deleteSurface("s")',
      );
    });

    test('renders a data assignment', () {
      expect(
        decompiler.decompile([
          UpdateDataModelMessage(
            surfaceId: 's',
            path: '/title',
            value: 'Hello',
          ),
        ]),
        r'$/title = "Hello"',
      );
    });

    test('renders positional arguments and drops trailing gaps', () {
      expect(
        decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {'id': 'a', 'component': 'Text', 'text': 'Hi'},
            ],
          ),
        ]),
        'a = Text("Hi")',
      );
    });

    test('uses an underscore for a skipped middle argument', () {
      expect(
        decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {
                'id': 'a',
                'component': 'Column',
                'children': ['b'],
                'align': 'center',
              },
            ],
          ),
        ]),
        'a = Column([b], _, "center")',
      );
    });

    test('renders a data binding', () {
      expect(
        decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {
                'id': 'a',
                'component': 'Text',
                'text': {'path': '/name'},
              },
            ],
          ),
        ]),
        r'a = Text($/name)',
      );
    });

    test('renders a list template', () {
      expect(
        decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {
                'id': 'a',
                'component': 'Column',
                'children': {'componentId': 'item', 'path': '/items'},
              },
            ],
          ),
        ]),
        r'a = Column(_template($/items, item))',
      );
    });

    test('prefers a raw string when the value contains backslashes', () {
      expect(
        decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {
                'id': 'a',
                'component': 'TextField',
                'label': 'Zip',
                'validationRegexp': r'^\d{5}$',
              },
            ],
          ),
        ]),
        r'a = TextField("Zip", _, _, _, r"^\d{5}$")',
      );
    });

    test('rejects an id that is not an Express identifier', () {
      expect(
        () => decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {'id': 'not-an-identifier', 'component': 'Text', 'text': 'x'},
            ],
          ),
        ]),
        throwsA(isA<A2uiFormatError>()),
      );
    });

    test('rejects a component that is not in the catalog', () {
      expect(
        () => decompiler.decompile([
          UpdateComponentsMessage(
            surfaceId: 's',
            components: [
              {'id': 'a', 'component': 'Carousel'},
            ],
          ),
        ]),
        throwsA(isA<A2uiFormatError>()),
      );
    });
  });

  group('round trip', () {
    test('a layout with named children', () {
      expectRoundTrip('''
surface("s1")
root = Column([title, cta], "spaceBetween", "center")
title = Text("Hello", "h1")
cta = Button(label, Event("go"))
label = Text("Go")
''');
    });

    test('inline children', () {
      expectRoundTrip('root = Column([Text("a"), Row([Text("b")])])');
    });

    test('data bindings and function calls', () {
      expectRoundTrip(r'''
root = Column([bound, formatted])
bound = Text($/user/name)
formatted = Text(capitalize($/user/name))
''');
    });

    test('a list template', () {
      expectRoundTrip(r'''
root = Column(_template($/items, item))
item = Text($label)
''');
    });

    test('events with context', () {
      expectRoundTrip(r'''
root = Button(label, Event("save", {rep: $/form/rep, force: true}))
label = Text("Save")
''');
    });

    test('validation checks', () {
      expectRoundTrip(r'''
root = TextField("Name", [?capitalize($/name, "Must be capitalized")])
''');
    });

    test('data assignments', () {
      expectRoundTrip(r'''
$/title = "Enable notifications"
$/count = 3
$/enabled = true
root = Text($/title)
''');
    });

    test('escaped and raw strings', () {
      expectRoundTrip(r'''
root = Column([multiline, pattern])
multiline = Text("line 1\nline 2")
pattern = TextField("Zip", _, _, _, r"^\d{5}$")
''');
    });

    test('surface deletion', () {
      expectRoundTrip('deleteSurface("gone")');
    });
  });
}
