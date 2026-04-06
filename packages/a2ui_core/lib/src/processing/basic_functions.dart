import 'package:json_schema_builder/json_schema_builder.dart';
import '../common/reactivity.dart';
import '../protocol/catalog.dart';
import '../rendering/contexts.dart';
import 'expressions.dart';

class FormatStringFunction extends FunctionImplementation {
  @override
  String get name => 'formatString';

  @override
  String get returnType => 'any';

  @override
  Schema get argumentSchema => Schema.object(
    properties: {
      'value': Schema.string(description: 'The string template to interpolate.'),
    },
    required: ['value'],
  );

  @override
  dynamic execute(Map<String, dynamic> args, DataContext context, [dynamic cancellationSignal]) {
    final template = args['value'] as String;
    final parser = ExpressionParser();
    final parts = parser.parse(template);

    if (parts.isEmpty) return '';
    if (parts.length == 1 && parts[0] is String) return parts[0];

    return ComputedNotifier(() {
      final resolvedParts = parts.map((part) {
        if (part is String) return part;
        final listenable = context.resolveListenable(part);
        return listenable.value?.toString() ?? '';
      });
      return resolvedParts.join('');
    });
  }
}
