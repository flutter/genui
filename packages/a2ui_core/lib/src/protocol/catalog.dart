import 'package:json_schema_builder/json_schema_builder.dart';
import '../common/cancellation.dart';
import '../common/reactivity.dart';
import '../rendering/contexts.dart';

/// A definition of a UI component's API.
abstract class ComponentApi {
  String get name;
  Schema get schema;
}

/// A definition of a UI function's API.
abstract class FunctionApi {
  String get name;
  String get returnType;
  Schema get argumentSchema;
}

/// A function implementation that can be registered with a catalog.
abstract class FunctionImplementation extends FunctionApi {
  /// Executes the function. Can return a static value or a [ValueListenable].
  dynamic execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]);
}

/// A collection of available components and functions.
class Catalog<T extends ComponentApi> {
  final String id;
  final Map<String, T> components;
  final Map<String, FunctionImplementation> functions;
  final Schema? themeSchema;

  Catalog({
    required this.id,
    required List<T> components,
    List<FunctionImplementation> functions = const [],
    this.themeSchema,
  }) : components = {for (var c in components) c.name: c},
       functions = {for (var f in functions) f.name: f};
}
