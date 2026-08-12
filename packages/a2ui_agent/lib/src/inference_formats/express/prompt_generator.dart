// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../parser/response_part.dart';
import '../../prompt/generator.dart';
import '../../utils/schema_utils.dart';
import 'constants.dart';
import 'decompiler.dart';

/// Renders the system prompt for the A2UI Express inference format.
///
/// Catalogs are described as positional signatures rather than JSON Schema,
/// which is the point of the format: the model spends its output tokens on
/// content instead of structural keys and quotes.
class ExpressPromptGenerator extends PromptGenerator {
  const ExpressPromptGenerator(super.catalogs, {super.examples});

  @override
  String generate() {
    final buffer = StringBuffer()
      ..writeln('# A2UI Express output format')
      ..writeln()
      ..writeln(
        'You build user interfaces by writing A2UI Express: a compact, '
        'line-oriented syntax that the host compiles into A2UI protocol '
        'messages.',
      )
      ..writeln()
      ..writeln('## Rules')
      ..writeln()
      ..writeln(
        '- Every Express block MUST be wrapped in `$expressOpenTag` and '
        '`$expressCloseTag` tags. Conversational text goes outside the tags.',
      )
      ..writeln(
        '- Each statement is a variable assignment on its own line: '
        '`name = Component(arguments)`. A statement may span lines while its '
        'brackets are open.',
      )
      ..writeln(
        '- `$expressRootVariable` is the reserved entry point of the '
        'component tree. Define it first, then its children.',
      )
      ..writeln(
        '- Arguments are positional, in the order given by the signatures '
        'below. `name=value` also works and can be mixed in. Trailing '
        'optional arguments may be omitted; use `$expressSkipPlaceholder` to '
        'skip an optional argument that comes before one you need.',
      )
      ..writeln(
        '- A child is either a variable holding a component, or an inline '
        'component: `Card(Text("Hi"))`. Lists use brackets: `[header, body]`.',
      )
      ..writeln(
        r'- Bind to the data model with `$/absolute/path`, or `$relative` '
        'inside a list template.',
      )
      ..writeln(
        r'- Populate the data model with `$/path = value`, for example '
        r'`$/title = "Inbox"`.',
      )
      ..writeln(
        '- Bind a child slot to a data-driven list with '
        '`$expressTemplateHelper(\$/items, itemComponent)`.',
      )
      ..writeln(
        '- Trigger a server event with '
        '`$expressEventCall("name", {key: \$/path})`. The context map is '
        'optional.',
      )
      ..writeln(
        '- Write validation checks with `?name`, e.g. `?required` or '
        r'`?regex(r"^[0-9]{5}$", "Must be a zip code")`. Group them in a '
        'list: `[?required, ?email]`. The last argument is the message shown '
        'when the check fails.',
      )
      ..writeln(
        '- Strings use double quotes. `r"..."` is a raw string where '
        'backslashes are literal, which is what regex patterns need. '
        '`"""..."""` spans lines. Numbers, `true`, `false` and `null` are '
        'written plainly.',
      )
      ..writeln(
        '- Target a surface with `$expressSurfaceCall("id")` before any '
        'component. Remove one with `$expressDeleteSurfaceCall("id")`.',
      )
      ..writeln('- Comments start with `#` or `//`.')
      ..writeln(
        '- Never invent a component, function or parameter that is not listed '
        'below.',
      )
      ..writeln()
      ..write(_signatures());

    final String examplesSection = _renderExamples();
    if (examplesSection.isNotEmpty) {
      buffer
        ..writeln()
        ..write(examplesSection);
    }
    return buffer.toString();
  }

  String _signatures() {
    final buffer = StringBuffer()
      ..writeln('## Component signatures')
      ..writeln()
      ..writeln('```');
    for (final Catalog<ComponentApi> catalog in catalogs) {
      for (final ComponentApi component in catalog.components.values) {
        buffer.writeln(componentSignature(component));
      }
    }
    buffer
      ..writeln('```')
      ..writeln();

    final List<FunctionImplementation> functions = [
      for (final Catalog<ComponentApi> catalog in catalogs)
        ...catalog.functions.values,
    ];
    if (functions.isNotEmpty) {
      buffer
        ..writeln('## Functions')
        ..writeln()
        ..writeln('```');
      for (final function in functions) {
        buffer.writeln(functionSignature(function));
      }
      buffer
        ..writeln('```')
        ..writeln();
    }

    buffer
      ..writeln('## Types')
      ..writeln()
      ..writeln(
        r'- `DynamicString` / `DynamicBoolean`: a literal, a `$path` binding, '
        'or a function call.',
      )
      ..writeln(
        '- `ChildList`: `[child, child]` or '
        '`$expressTemplateHelper(\$/path, child)`.',
      )
      ..writeln('- `ComponentId`: a variable holding a component.')
      ..writeln(
        '- `Action`: `$expressEventCall("name", {...})` or a call to one of '
        'the functions above.',
      );
    return buffer.toString();
  }

  /// The positional signature of [component], e.g. `Text(text, variant?)`.
  static String componentSignature(ComponentApi component) {
    final List<SignatureParameter> parameters = signatureOf(component.schema);
    final Iterable<String> rendered = parameters.map(
      (parameter) => '${parameter.label}: ${typeHint(parameter.schema)}',
    );
    return '${component.name}(${rendered.join(', ')})';
  }

  /// The positional signature of [function], e.g.
  /// `capitalize(value: DynamicString) -> string`.
  static String functionSignature(FunctionImplementation function) {
    final List<SignatureParameter> parameters = signatureOf(
      function.argumentSchema,
    );
    final Iterable<String> rendered = parameters.map(
      (parameter) => '${parameter.label}: ${typeHint(parameter.schema)}',
    );
    return '${function.name}(${rendered.join(', ')}) -> '
        '${function.returnType.jsonValue}';
  }

  /// A compact description of the values [schema] accepts.
  static String typeHint(Schema schema) {
    final Object? enumValues = schema['enum'];
    if (enumValues is List && enumValues.isNotEmpty) {
      return enumValues.map((value) => '"$value"').join('|');
    }

    final String? ref = schemaRefName(schema);
    if (ref != null) return ref;

    final Object? type = schema['type'];
    if (type is String) return type;
    if (type is List) return type.join('|');

    if (schema['properties'] is Map) return 'object';
    if (schema['items'] is Map) {
      final items = Schema.fromMap(
        (schema['items']! as Map).cast<String, Object?>(),
      );
      return 'array<${typeHint(items)}>';
    }
    return 'any';
  }

  String _renderExamples() {
    final PromptExamples? examples = this.examples;
    if (examples == null || examples.isEmpty) return '';

    final decompiler = ExpressDecompiler(catalogs: catalogs);
    final buffer = StringBuffer()
      ..writeln('## Examples')
      ..writeln();
    for (final MapEntry<String, List<AgentToRendererMessage>> entry
        in examples.entries) {
      buffer
        ..writeln('### ${entry.key}')
        ..writeln()
        ..writeln(expressOpenTag)
        ..writeln(decompiler.decompile(entry.value))
        ..writeln(expressCloseTag)
        ..writeln();
    }
    return buffer.toString();
  }
}
