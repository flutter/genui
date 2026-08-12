// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProtocolVersion', () {
    test('parses both the prefixed and bare forms', () {
      expect(ProtocolVersion.tryParse('v0.9'), ProtocolVersion.v09);
      expect(ProtocolVersion.tryParse('0.9'), ProtocolVersion.v09);
      expect(ProtocolVersion.tryParse('v1.0'), ProtocolVersion.v10);
      expect(ProtocolVersion.tryParse('v0.9.1'), ProtocolVersion.v091);
      expect(ProtocolVersion.tryParse('v0.8'), ProtocolVersion.v08);
    });

    test('returns null for an unknown version', () {
      expect(ProtocolVersion.tryParse('v2.0'), isNull);
      expect(ProtocolVersion.tryParse('nonsense'), isNull);
    });

    test('renders its wire value', () {
      expect('${ProtocolVersion.v091}', 'v0.9.1');
      expect(ProtocolVersion.current, ProtocolVersion.v09);
    });
  });

  group('response parts', () {
    test('text parts compare by content', () {
      expect(const TextPart('a'), const TextPart('a'));
      expect(const TextPart('a').hashCode, const TextPart('a').hashCode);
      expect(const TextPart('a'), isNot(const TextPart('b')));
    });

    test('raw parts compare by content', () {
      expect(const RawA2uiPart('[]'), const RawA2uiPart('[]'));
      expect(
        const RawA2uiPart('[]').hashCode,
        const RawA2uiPart('[]').hashCode,
      );
      expect(const RawA2uiPart('[]'), isNot(const RawA2uiPart('[1]')));
    });

    test('describe themselves without dumping their content', () {
      expect(const TextPart('hello').toString(), "TextPart('hello')");
      expect(
        TextPart('x' * 60).toString(),
        allOf(startsWith('TextPart('), contains('…')),
      );
      expect(
        const TextPart('two\nlines').toString(),
        r"TextPart('two\nlines')",
      );
      expect(const RawA2uiPart('[]').toString(), "RawA2uiPart('[]')");
      expect(
        const RawResponsePart(TextPart('a'), isFinal: false).toString(),
        contains('isFinal: false'),
      );
    });

    test('A2uiPart reports its message count and serializes', () {
      final part = A2uiPart([DeleteSurfaceMessage(surfaceId: 's')]);

      expect(part.toString(), 'A2uiPart(1 message(s))');
      expect(part.toJson().single, containsPair('version', 'v0.9'));
    });
  });

  group('errors', () {
    test('A2uiFormatError reports the line and source', () {
      final error = A2uiFormatError(
        'bad thing',
        line: 3,
        source: 'root = Nope()',
      );

      expect(
        error.toString(),
        allOf(
          contains('bad thing'),
          contains('line 3'),
          contains('root = Nope()'),
        ),
      );
      expect(error.code, 'FORMAT_ERROR');
    });

    test('A2uiFormatError omits absent details', () {
      expect(A2uiFormatError('bare').toString(), isNot(contains('line')));
    });

    test('A2uiCapabilityError carries its code', () {
      expect(A2uiCapabilityError('no overlap').code, 'CAPABILITY_ERROR');
    });

    test('A2uiValidationIssue names where the problem is', () {
      expect(
        const A2uiValidationIssue(
          'broken',
          surfaceId: 's',
          componentId: 'root',
        ).toString(),
        "broken (in surface 's', component 'root')",
      );
      expect(const A2uiValidationIssue('broken').toString(), 'broken');
    });
  });

  group('statement splitting', () {
    test('handles raw and triple-quoted strings', () {
      expect(completeStatementPrefixLength(r'a = TextField(r"^\d+$")'), 0);
      expect(completeStatementPrefixLength('a = Text("""x\ny""")\n'), 20);
    });

    test('does not treat an identifier ending in r as a raw string', () {
      expect(completeStatementPrefixLength('myvar = Text("x")\n'), 18);
    });

    test('waits for an unterminated block comment', () {
      expect(completeStatementPrefixLength('/* open\na = Text("x")\n'), 0);
    });

    test('recovers after a closed block comment', () {
      expect(completeStatementPrefixLength('/* shut */ a = Text("x")\n'), 25);
    });

    test('ignores an unmatched closing bracket', () {
      expect(completeStatementPrefixLength(') a = Text("x")\n'), 16);
    });
  });

  group('Express type hints', () {
    test('renders enums as alternatives', () {
      expect(
        ExpressPromptGenerator.componentSignature(MinimalTextApi()),
        'Text(text: DynamicString, variant?: "h1"|"h2"|"h3"|"h4"|"h5"|'
        '"caption"|"body")',
      );
    });

    test('renders common type references by name', () {
      expect(
        ExpressPromptGenerator.componentSignature(MinimalRowApi()),
        startsWith('Row(children: ChildList'),
      );
    });

    test('renders a function signature with its return type', () {
      expect(
        ExpressPromptGenerator.functionSignature(CapitalizeFunction()),
        'capitalize(value: DynamicString) -> string',
      );
    });
  });

  group('sentinel tokenizer', () {
    test('reports whether it is inside a block', () {
      final tokenizer = SentinelTokenizer(openTag: '<a>', closeTag: '</a>');

      expect(tokenizer.inBlock, isFalse);
      tokenizer.add('text <a>');
      expect(tokenizer.inBlock, isTrue);
      tokenizer.add('body </a>');
      expect(tokenizer.inBlock, isFalse);
    });

    test('flushes an unterminated block', () {
      final tokenizer = SentinelTokenizer(openTag: '<a>', closeTag: '</a>');

      // '</' could still become the closing tag, so it is held back until
      // flush proves the stream ended.
      final List<SentinelToken> added = tokenizer.add('<a>body</');
      expect(added.whereType<BlockContentToken>().single.content, 'body');
      expect(added.whereType<BlockEndToken>(), isEmpty);

      final List<SentinelToken> flushed = tokenizer.flush();
      expect(flushed.whereType<BlockContentToken>().single.content, '</');
      expect(flushed.whereType<BlockEndToken>().single.terminated, isFalse);
      expect(tokenizer.inBlock, isFalse);
    });
  });
}
