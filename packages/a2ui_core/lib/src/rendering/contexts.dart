import '../common/reactivity.dart';
import '../common/data_path.dart';
import '../protocol/common.dart';
import '../protocol/catalog.dart';
import '../state/data_model.dart';
import '../state/surface_model.dart';
import '../state/component_model.dart';

/// A contextual view of the main DataModel.
class DataContext {
  final SurfaceModel surface;
  final String path;

  DataContext(this.surface, this.path);

  DataModel get dataModel => surface.dataModel;

  /// Resolves a path against this context.
  String resolvePath(String relativePath) {
    if (relativePath.startsWith('/')) return relativePath;
    if (relativePath == '' || relativePath == '.') return path;
    
    final base = path == '/' ? '' : (path.endsWith('/') ? path.substring(0, path.length - 1) : path);
    return '$base/$relativePath';
  }

  /// Synchronously evaluates a dynamic value.
  dynamic resolveSync(dynamic value) {
    if (value is Map && value.containsKey('path')) {
      return dataModel.get(resolvePath(value['path'] as String));
    }
    if (value is Map && value.containsKey('call')) {
      final call = FunctionCall.fromJson(Map<String, dynamic>.from(value));
      final args = <String, dynamic>{};
      for (final entry in call.args.entries) {
        args[entry.key] = resolveSync(entry.value);
      }
      final result = surface.catalog.invoker(call.call, args, this);
      if (result is ValueListenable) {
        return result.value;
      }
      return result;
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        result[entry.key as String] = resolveSync(entry.value);
      }
      return result;
    }
    if (value is List) {
      return value.map((item) => resolveSync(item)).toList();
    }
    return value;
  }

  /// Reactively evaluates a dynamic value.
  ValueListenable<dynamic> resolveListenable(dynamic value) {
    if (value is Map && value.containsKey('path')) {
      return dataModel.watch(resolvePath(value['path'] as String));
    }
    if (value is Map && value.containsKey('call')) {
      final call = FunctionCall.fromJson(Map<String, dynamic>.from(value));
      return ComputedNotifier(() {
        final args = <String, dynamic>{};
        for (final entry in call.args.entries) {
          final resolved = resolveListenable(entry.value);
          args[entry.key] = resolved.value;
        }
        final result = surface.catalog.invoker(call.call, args, this);
        if (result is ValueListenable) {
          return result.value;
        }
        return result;
      });
    }
    return ValueNotifier(value);
  }

  /// Creates a nested data context.
  DataContext nested(String relativePath) {
    return DataContext(surface, resolvePath(relativePath));
  }

  /// Sets a value in the data model.
  void set(String relativePath, dynamic value) {
    dataModel.set(resolvePath(relativePath), value);
  }
}

/// Context provided to components during rendering.
class ComponentContext {
  final SurfaceModel surface;
  final ComponentModel componentModel;
  final DataContext dataContext;

  ComponentContext(this.surface, this.componentModel, {String? basePath})
      : dataContext = DataContext(surface, basePath ?? '/');

  /// Dispatches an action from the component.
  Future<void> dispatchAction(Map<String, dynamic> action) {
    return surface.dispatchAction(action, componentModel.id);
  }

  /// Resolves a child component's context.
  ComponentContext childContext(String childId, {String? basePath}) {
    final childModel = surface.componentsModel.get(childId);
    if (childModel == null) {
      throw ArgumentError('Child component not found: $childId');
    }
    return ComponentContext(surface, childModel, basePath: basePath ?? dataContext.path);
  }
}

extension CatalogInvokerExtension on Catalog {
  /// Helper to invoke functions.
  dynamic invoker(String name, Map<String, dynamic> args, DataContext context) {
    final fn = functions[name];
    if (fn == null) {
      throw ArgumentError('Function not found: $name');
    }
    return fn.execute(args, context);
  }
}
