// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:characters/characters.dart';
import 'package:decimal/decimal.dart';

import 'constants.dart';
import 'exceptions.dart';
import 'formats.dart';
import 'json_type.dart';
import 'logging_context.dart';
import 'schema/list_schema.dart';
import 'schema/number_schema.dart';
import 'schema/object_schema.dart';
import 'schema/schema.dart';
import 'schema/string_schema.dart';
import 'schema_registry.dart';
import 'utils.dart';
import 'validation_error.dart';
import 'validation_result.dart';

/// A context object that holds information about the current validation
/// process.
class ValidationContext {
  final Schema rootSchema;
  final bool strictFormat;
  final Uri? sourceUri;
  final SchemaRegistry schemaRegistry;
  final Map<String, bool> vocabularies;
  final LoggingContext? loggingContext;

  /// The outcome of every fetch made for this validation, keyed by the URI of
  /// the schema resource, that did not produce a schema.
  ///
  /// A `null` value means the fetch produced no schema, and a non-null value is
  /// the exception it failed with. Successful fetches land in [schemaRegistry]
  /// instead. Keeping the failures here rather than in the registry scopes them
  /// to a single validation, so that a later validation retries the fetch just
  /// as it did before this context existed.
  final Map<Uri, SchemaFetchException?> _failedFetches;

  /// Creates a new validation context.
  ValidationContext(
    this.rootSchema, {
    this.strictFormat = false,
    this.sourceUri,
    required this.schemaRegistry,
    this.loggingContext,
    this.vocabularies = const {
      'https://json-schema.org/draft/2020-12/vocab/core': true,
      'https://json-schema.org/draft/2020-12/vocab/applicator': true,
      'https://json-schema.org/draft/2020-12/vocab/unevaluated': true,
      'https://json-schema.org/draft/2020-12/vocab/validation': true,
      'https://json-schema.org/draft/2020-12/vocab/meta-data': true,
      'https://json-schema.org/draft/2020-12/vocab/format-annotation': true,
      'https://json-schema.org/draft/2020-12/vocab/content': true,
    },
  }) : _failedFetches = {};

  ValidationContext._copyWith({
    required this.rootSchema,
    required this.strictFormat,
    required this.sourceUri,
    required this.schemaRegistry,
    required this.vocabularies,
    required this.loggingContext,
    required Map<Uri, SchemaFetchException?> failedFetches,
  }) : _failedFetches = failedFetches;

  /// Resolves the schema at [uri] for this validation, without performing any
  /// I/O.
  ///
  /// This is [SchemaRegistry.resolveSync], plus the outcomes of the fetches
  /// already made for this validation: a fetch that failed throws its
  /// [SchemaFetchException] again, and one that produced no schema resolves to
  /// `null` again, rather than asking for the fetch to be repeated.
  Schema? resolveSchemaSync(Uri uri) {
    final Uri uriWithoutFragment = uri.removeFragment();
    if (_failedFetches.containsKey(uriWithoutFragment)) {
      final SchemaFetchException? failure = _failedFetches[uriWithoutFragment];
      if (failure != null) throw failure;
      return null;
    }
    return schemaRegistry.resolveSync(uri);
  }

  /// Fetches the schema at [uri] into [schemaRegistry], recording the outcome
  /// so that [resolveSchemaSync] can answer for [uri] without fetching again.
  Future<void> fetchSchema(Uri uri) async {
    final Uri uriWithoutFragment = uri.removeFragment();
    try {
      final Schema? schema = await schemaRegistry.fetch(uriWithoutFragment);
      if (schema == null) {
        _failedFetches[uriWithoutFragment] = null;
      }
    } on SchemaFetchException catch (e) {
      _failedFetches[uriWithoutFragment] = e;
    }
  }

  /// Creates a copy of this context with a new [newSourceUri].
  ValidationContext withSourceUri(Uri newSourceUri) {
    return ValidationContext._copyWith(
      rootSchema: rootSchema,
      strictFormat: strictFormat,
      sourceUri: newSourceUri,
      schemaRegistry: schemaRegistry,
      vocabularies: vocabularies,
      loggingContext: loggingContext,
      failedFetches: _failedFetches,
    );
  }

  /// Creates a copy of this context with a new set of [newVocabularies].
  ValidationContext withVocabularies(Map<String, bool> newVocabularies) {
    return ValidationContext._copyWith(
      rootSchema: rootSchema,
      strictFormat: strictFormat,
      sourceUri: sourceUri,
      schemaRegistry: schemaRegistry,
      vocabularies: newVocabularies,
      loggingContext: loggingContext,
      failedFetches: _failedFetches,
    );
  }
}

/// Runs a synchronous validation [body], fetching the remote schemas it asks
/// for into [context] and retrying until every reference resolves from
/// memory.
///
/// This is what makes the asynchronous entry points thin wrappers around the
/// synchronous core: the only I/O validation ever needs is fetching the target
/// of a reference, and the synchronous core reports exactly which target it is
/// missing by throwing a [SchemaResolutionRequiredException]. Each retry
/// therefore resolves one more remote reference, and a schema with no remote
/// references runs [body] exactly once.
Future<T> _resolvingRemoteRefs<T>(
  ValidationContext context,
  T Function() body,
) async {
  final fetched = <Uri>{};
  while (true) {
    try {
      return body();
    } on SchemaResolutionRequiredException catch (e) {
      if (!fetched.add(e.uri)) {
        // The outcome of the fetch was not recorded, so retrying would loop
        // forever.
        rethrow;
      }
      await context.fetchSchema(e.uri);
    }
  }
}

/// Validates the given [data] against a [schema].
///
/// This is a helper function for recursively validating subschemas.
///
/// Remote references are fetched as they are encountered. See
/// [validateSubSchemaSync] for the synchronous equivalent.
Future<ValidationResult> validateSubSchema(
  Object? schema,
  Object? data,
  List<String> currentPath,
  ValidationContext context,
  List<Schema> dynamicScope, {
  AnnotationSet? initialAnnotations,
}) => _resolvingRemoteRefs(
  context,
  () => validateSubSchemaSync(
    schema,
    data,
    currentPath,
    context,
    dynamicScope,
    initialAnnotations: initialAnnotations,
  ),
);

/// Validates the given [data] against a [schema], without performing any I/O.
///
/// This is a helper function for recursively validating subschemas.
///
/// Every reference must resolve from `context.schemaRegistry`; see
/// [SchemaValidation.validateSync] for what happens when one does not.
ValidationResult validateSubSchemaSync(
  Object? schema,
  Object? data,
  List<String> currentPath,
  ValidationContext context,
  List<Schema> dynamicScope, {
  AnnotationSet? initialAnnotations,
}) {
  if (schema is bool) {
    if (schema == false) {
      return ValidationResult.failure([
        ValidationError(
          ValidationErrorType.custom,
          path: currentPath,
          details: 'Schema is false',
        ),
      ], AnnotationSet.empty());
    }
    // If schema is true, it's always valid.
    return ValidationResult.success(AnnotationSet.empty());
  }
  if (schema is Map) {
    return Schema.fromMap(schema.cast<String, Object?>()).validateSchemaSync(
      data,
      currentPath,
      context,
      dynamicScope,
      initialAnnotations: initialAnnotations,
    );
  }
  // This should not happen for a valid schema file.
  return ValidationResult.success(AnnotationSet.empty());
}

/// An extension on [Schema] that adds validation functionality.
extension SchemaValidation on Schema {
  /// Validates the given [data] against this schema.
  ///
  /// Returns a list of [ValidationError] if validation fails,
  /// or an empty list if validation succeeds.
  ///
  /// Remote references (`$ref`s pointing at a schema that is not already in
  /// [schemaRegistry]) are fetched as they are encountered. If this schema has
  /// none, prefer [validateSync], which does the same work without the
  /// [Future].
  Future<List<ValidationError>> validate(
    Object? data, {
    bool strictFormat = false,
    Uri? sourceUri,
    SchemaRegistry? schemaRegistry,
    LoggingContext? loggingContext,
  }) async {
    final SchemaRegistry registry =
        schemaRegistry ?? SchemaRegistry(loggingContext: loggingContext);
    try {
      final ValidationContext context = _rootValidationContext(
        registry,
        strictFormat: strictFormat,
        sourceUri: sourceUri,
        loggingContext: loggingContext,
      );
      final ValidationResult result = await _resolvingRemoteRefs(
        context,
        () => validateSchemaSync(data, [], context, [this]),
      );
      return result.errors;
    } finally {
      if (schemaRegistry == null) {
        // If we created our own, we need to dispose it.
        registry.dispose();
      }
    }
  }

  /// Validates the given [data] against this schema, without performing any
  /// I/O.
  ///
  /// Returns a list of [ValidationError] if validation fails, or an empty list
  /// if validation succeeds. The results are identical to those of [validate].
  ///
  /// This requires that every reference in this schema resolves without
  /// fetching anything: references within the schema itself, and references to
  /// schemas already added to [schemaRegistry]. That covers schemas whose
  /// `$ref`s have been inlined, and schemas whose dependencies were registered
  /// up front.
  ///
  /// If validation reaches a reference whose target would have to be fetched,
  /// this throws a [SchemaResolutionRequiredException] naming that target,
  /// rather than skipping the reference — an unfetched subschema would
  /// otherwise be silently treated as unconstrained and turn a missing fetch
  /// into a passing validation. Use [validate] for schemas with remote
  /// references, or pass a [schemaRegistry] that already holds them.
  List<ValidationError> validateSync(
    Object? data, {
    bool strictFormat = false,
    Uri? sourceUri,
    SchemaRegistry? schemaRegistry,
    LoggingContext? loggingContext,
  }) {
    final SchemaRegistry registry =
        schemaRegistry ?? SchemaRegistry(loggingContext: loggingContext);
    try {
      final ValidationContext context = _rootValidationContext(
        registry,
        strictFormat: strictFormat,
        sourceUri: sourceUri,
        loggingContext: loggingContext,
      );
      return validateSchemaSync(data, [], context, [this]).errors;
    } finally {
      if (schemaRegistry == null) {
        // If we created our own, we need to dispose it.
        registry.dispose();
      }
    }
  }

  /// Registers this schema in [registry] and creates the context that
  /// validation of it starts from.
  ValidationContext _rootValidationContext(
    SchemaRegistry registry, {
    required bool strictFormat,
    required Uri? sourceUri,
    required LoggingContext? loggingContext,
  }) {
    final Uri baseUri = sourceUri ?? Uri.parse('local://schema');
    registry.addSchema(baseUri, this);
    return ValidationContext(
      this,
      strictFormat: strictFormat,
      sourceUri: baseUri,
      schemaRegistry: registry,
      loggingContext: loggingContext,
    );
  }

  /// Validates the given [data] against this schema, including any subschemas.
  ///
  /// This is the main entry point for validating an object against a schema.
  ///
  /// Remote references are fetched as they are encountered. See
  /// [validateSchemaSync] for the synchronous equivalent.
  Future<ValidationResult> validateSchema(
    Object? data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope, {
    AnnotationSet? initialAnnotations,
  }) => _resolvingRemoteRefs(
    context,
    () => validateSchemaSync(
      data,
      currentPath,
      context,
      dynamicScope,
      initialAnnotations: initialAnnotations,
    ),
  );

  /// Validates the given [data] against the type-specific keywords in this
  /// schema.
  ///
  /// Remote references are fetched as they are encountered. See
  /// [validateTypeSpecificKeywordsSync] for the synchronous equivalent.
  Future<ValidationResult> validateTypeSpecificKeywords(
    Object? data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) => _resolvingRemoteRefs(
    context,
    () => validateTypeSpecificKeywordsSync(
      data,
      currentPath,
      context,
      dynamicScope,
    ),
  );

  /// Validates an object against the schema.
  ///
  /// Remote references are fetched as they are encountered. See
  /// [validateObjectSync] for the synchronous equivalent.
  Future<ValidationResult> validateObject(
    Map<String, Object?> data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) => _resolvingRemoteRefs(
    context,
    () => validateObjectSync(data, currentPath, context, dynamicScope),
  );

  /// Validates a list against the schema.
  ///
  /// Remote references are fetched as they are encountered. See
  /// [validateListSync] for the synchronous equivalent.
  Future<ValidationResult> validateList(
    List<Object?> data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) => _resolvingRemoteRefs(
    context,
    () => validateListSync(data, currentPath, context, dynamicScope),
  );

  /// Resolves a `$ref` reference to a schema.
  ///
  /// The target is fetched if it is not registered yet. See [resolveRefSync]
  /// for the synchronous equivalent.
  Future<(Schema, Uri)?> resolveRef(
    String ref,
    Schema rootSchema,
    ValidationContext context,
  ) => _resolvingRemoteRefs(
    context,
    () => resolveRefSync(ref, rootSchema, context),
  );

  /// Resolves a `$dynamicRef` reference to a schema.
  ///
  /// The target is fetched if it is not registered yet. See
  /// [resolveDynamicRefSync] for the synchronous equivalent.
  Future<(Schema, Uri)?> resolveDynamicRef(
    String ref,
    List<Schema> dynamicScope,
    ValidationContext context,
  ) => _resolvingRemoteRefs(
    context,
    () => resolveDynamicRefSync(ref, dynamicScope, context),
  );

  /// Validates the given [data] against this schema, including any subschemas,
  /// without performing any I/O.
  ///
  /// This is the main entry point for validating an object against a schema.
  /// Every reference must resolve from `context.schemaRegistry`; see
  /// [validateSync] for what happens when one does not.
  ValidationResult validateSchemaSync(
    Object? data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope, {
    AnnotationSet? initialAnnotations,
  }) {
    var currentContext = context;
    if ($id != null) {
      // This is a heuristic to avoid re-resolving a relative path that has
      // already been applied to the base URI.
      if (!($id!.endsWith('/') &&
          context.sourceUri!.path.endsWith('/${$id}'))) {
        final Uri newUri = context.sourceUri!.resolve($id!);
        currentContext = context.withSourceUri(newUri);
      }
    }

    context.loggingContext?.log(
      'Validating ${currentContext.sourceUri}#${currentPath.join('/')} '
      'with schema $value',
    );
    final newDynamicScope = [...dynamicScope, this];
    final errors = <ValidationError>[];
    AnnotationSet allAnnotations = initialAnnotations ?? AnnotationSet.empty();

    if ($schema != null) {
      try {
        final Uri metaSchemaUri = Uri.parse($schema!);
        final Schema? metaSchema = currentContext.resolveSchemaSync(
          metaSchemaUri,
        );
        if (metaSchema != null) {
          final Object? vocabulary = metaSchema.value['\$vocabulary'];
          if (vocabulary is Map) {
            currentContext = currentContext.withVocabularies(
              vocabulary.cast<String, bool>(),
            );
          } else {
            // If $vocabulary is not present, default to all vocabularies.
            currentContext = currentContext.withVocabularies(const {
              'https://json-schema.org/draft/2020-12/vocab/core': true,
              'https://json-schema.org/draft/2020-12/vocab/applicator': true,
              'https://json-schema.org/draft/2020-12/vocab/unevaluated': true,
              'https://json-schema.org/draft/2020-12/vocab/validation': true,
              'https://json-schema.org/draft/2020-12/vocab/meta-data': true,
              'https://json-schema.org/draft/2020-12/vocab/format-annotation':
                  true,
              'https://json-schema.org/draft/2020-12/vocab/content': true,
            });
          }
        }
      } on SchemaFetchException catch (e) {
        errors.add(
          ValidationError(
            ValidationErrorType.refResolutionError,
            path: currentPath,
            details: 'Failed to resolve meta schema: ${e.uri}',
          ),
        );
      }
    }

    if ($dynamicRef case final ref?) {
      final (Schema, Uri)? resolution = resolveDynamicRefSync(
        ref,
        newDynamicScope,
        currentContext,
      );
      if (resolution case (final referencedSchema, final referencedUri)?) {
        final ValidationContext newContext = currentContext.withSourceUri(
          referencedUri,
        );
        final ValidationResult refResult = referencedSchema.validateSchemaSync(
          data,
          currentPath,
          newContext,
          newDynamicScope,
        );
        errors.addAll(refResult.errors);
        allAnnotations = allAnnotations.merge(refResult.annotations);

        final Map<String, Object?> siblingSchemaMap = {...value};
        siblingSchemaMap.remove(kDynamicRef);
        if (siblingSchemaMap.isNotEmpty) {
          final siblingSchema = Schema.fromMap(siblingSchemaMap);
          final ValidationResult siblingResult = siblingSchema
              .validateSchemaSync(
                data,
                currentPath,
                currentContext,
                newDynamicScope,
                initialAnnotations: allAnnotations,
              );
          errors.addAll(siblingResult.errors);
          allAnnotations = allAnnotations.merge(siblingResult.annotations);
        }
        return ValidationResult.fromErrors(errors, allAnnotations);
      } else {
        return ValidationResult.failure([
          ValidationError(
            ValidationErrorType.refResolutionError,
            path: currentPath,
            details: 'Failed to resolve dynamic reference: $ref',
          ),
        ], AnnotationSet.empty());
      }
    }

    if ($ref case final ref?) {
      final (Schema, Uri)? resolution = resolveRefSync(
        ref,
        currentContext.rootSchema,
        currentContext,
      );
      if (resolution case (final referencedSchema, final referencedUri)?) {
        final ValidationContext newContext = currentContext.withSourceUri(
          referencedUri,
        );
        final ValidationResult refResult = referencedSchema.validateSchemaSync(
          data,
          currentPath,
          newContext,
          newDynamicScope,
        );
        context.loggingContext?.log(
          'Annotations from $ref: ${refResult.annotations.evaluatedKeys}',
        );
        errors.addAll(refResult.errors);
        allAnnotations = allAnnotations.merge(refResult.annotations);

        final Map<String, Object?> siblingSchemaMap = {...value};
        siblingSchemaMap.remove(kRef);
        if (siblingSchemaMap.isNotEmpty) {
          final siblingSchema = Schema.fromMap(siblingSchemaMap);
          final ValidationResult siblingResult = siblingSchema
              .validateSchemaSync(
                data,
                currentPath,
                currentContext,
                newDynamicScope,
                initialAnnotations: allAnnotations,
              );
          errors.addAll(siblingResult.errors);
          allAnnotations = allAnnotations.merge(siblingResult.annotations);
        }
        return ValidationResult.fromErrors(errors, allAnnotations);
      } else {
        return ValidationResult.failure([
          ValidationError(
            ValidationErrorType.refResolutionError,
            path: currentPath,
            details: 'Failed to resolve reference: $ref',
          ),
        ], AnnotationSet.empty());
      }
    }

    // 1. Conditional Applicators: if/then/else
    if (ifSchema case final ifS?) {
      final ValidationResult ifResult = validateSubSchemaSync(
        ifS,
        data,
        currentPath,
        currentContext,
        newDynamicScope,
      );
      if (ifResult.isValid) {
        allAnnotations = allAnnotations.merge(ifResult.annotations);
        if (thenSchema case final thenS?) {
          final ValidationResult thenResult = validateSubSchemaSync(
            thenS,
            data,
            currentPath,
            currentContext,
            newDynamicScope,
          );
          errors.addAll(thenResult.errors);
          if (thenResult.isValid) {
            allAnnotations = allAnnotations.merge(thenResult.annotations);
          }
        }
      } else {
        if (elseSchema case final elseS?) {
          final ValidationResult elseResult = validateSubSchemaSync(
            elseS,
            data,
            currentPath,
            currentContext,
            newDynamicScope,
          );
          errors.addAll(elseResult.errors);
          if (elseResult.isValid) {
            allAnnotations = allAnnotations.merge(elseResult.annotations);
          }
        }
      }
    }

    // 2. Schema Combiners: allOf, anyOf, oneOf, not
    if (allOf case final List<Object?> allOfList) {
      final allOfAnnotations = <AnnotationSet>[];
      for (final subSchema in allOfList) {
        final ValidationResult result = validateSubSchemaSync(
          subSchema,
          data,
          currentPath,
          currentContext,
          newDynamicScope,
        );
        errors.addAll(result.errors);
        if (result.isValid) {
          allOfAnnotations.add(result.annotations);
        }
      }
      allAnnotations = allAnnotations.mergeAll(allOfAnnotations);
    }

    if (anyOf case final List<Object?> anyOfList) {
      var passedCount = 0;
      final anyOfAnnotations = <AnnotationSet>[];
      final allAnyOfErrors = <ValidationError>[];
      for (final subSchema in anyOfList) {
        final ValidationResult result = validateSubSchemaSync(
          subSchema,
          data,
          currentPath,
          currentContext,
          newDynamicScope,
        );
        if (result.isValid) {
          passedCount++;
          anyOfAnnotations.add(result.annotations);
        } else {
          allAnyOfErrors.addAll(result.errors);
        }
      }
      if (passedCount == 0) {
        errors.add(
          ValidationError(ValidationErrorType.anyOfNotMet, path: currentPath),
        );
      }
      allAnnotations = allAnnotations.mergeAll(anyOfAnnotations);
    }

    if (oneOf case final List<Object?> oneOfList) {
      var passedCount = 0;
      AnnotationSet? oneOfAnnotations;
      for (final subSchema in oneOfList) {
        final ValidationResult result = validateSubSchemaSync(
          subSchema,
          data,
          currentPath,
          currentContext,
          newDynamicScope,
        );
        if (result.isValid) {
          passedCount++;
          oneOfAnnotations = result.annotations;
        }
      }
      if (passedCount != 1) {
        errors.add(
          ValidationError(
            ValidationErrorType.oneOfNotMet,
            path: currentPath,
            details:
                'Expected to match exactly one schema, but matched '
                '$passedCount',
          ),
        );
      } else if (oneOfAnnotations != null) {
        allAnnotations = allAnnotations.merge(oneOfAnnotations);
      }
    }

    if (not case final notSchema?) {
      final ValidationResult result = validateSubSchemaSync(
        notSchema,
        data,
        currentPath,
        currentContext,
        newDynamicScope,
      );
      if (result.isValid) {
        errors.add(
          ValidationError(
            ValidationErrorType.notConditionViolated,
            path: currentPath,
          ),
        );
      }
    }

    // 3. Generic Validation Keywords
    if (value.containsKey(kConst)) {
      final Object? constV = value[kConst];
      if (!deepEquals(data, constV)) {
        errors.add(
          ValidationError(
            ValidationErrorType.constMismatch,
            path: currentPath,
            details: 'Value does not match const value $constV',
          ),
        );
      }
    }

    if (enumValues case final enumV?) {
      if (!enumV.any((e) => deepEquals(data, e))) {
        errors.add(
          ValidationError(
            ValidationErrorType.enumValueNotAllowed,
            path: currentPath,
            details: 'Value is not one of the allowed enum values',
          ),
        );
      }
    }

    // 4. Type-Specific Validation
    final ValidationResult typeResult = validateTypeSpecificKeywordsSync(
      data,
      currentPath,
      currentContext,
      newDynamicScope,
    );
    errors.addAll(typeResult.errors);
    allAnnotations = allAnnotations.merge(typeResult.annotations);

    // 5. Unevaluated Properties & Items
    if (data is Map<String, Object?>) {
      if (this[kUnevaluatedProperties] case final up?) {
        context.loggingContext?.log(
          'Checking unevaluatedProperties. '
          'Annotations: ${allAnnotations.evaluatedKeys}',
        );
        final newlyEvaluatedKeys = <String>{};
        for (final String dataKey in data.keys) {
          if (!allAnnotations.evaluatedKeys.contains(dataKey)) {
            final newPath = [...currentPath, dataKey];
            final ValidationResult result = validateSubSchemaSync(
              up,
              data[dataKey],
              newPath,
              currentContext,
              newDynamicScope,
            );
            errors.addAll(result.errors);
            if (result.isValid) {
              allAnnotations = allAnnotations.merge(result.annotations);
            }
            newlyEvaluatedKeys.add(dataKey);
          }
        }
        allAnnotations.evaluatedKeys.addAll(newlyEvaluatedKeys);
      }
    } else if (data is List) {
      if (this[kUnevaluatedItems] case final ui?) {
        final newlyEvaluatedItems = <int>{};
        for (var i = 0; i < data.length; i++) {
          if (!allAnnotations.evaluatedItems.contains(i)) {
            final newPath = [...currentPath, i.toString()];
            final ValidationResult result = validateSubSchemaSync(
              ui,
              data[i],
              newPath,
              currentContext,
              newDynamicScope,
            );
            errors.addAll(result.errors);
            if (result.isValid) {
              allAnnotations = allAnnotations.merge(result.annotations);
            }
            newlyEvaluatedItems.add(i);
          }
        }
        allAnnotations.evaluatedItems.addAll(newlyEvaluatedItems);
      }
    }

    return ValidationResult.fromErrors(errors, allAnnotations);
  }

  /// Validates the given [data] against the type-specific keywords in this
  /// schema.
  ValidationResult validateTypeSpecificKeywordsSync(
    Object? data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) {
    final JsonType actualType = getJsonType(data);
    final errors = <ValidationError>[];

    // First, validate against the `type` keyword if it exists.
    final Object? typeValue = type;
    if (typeValue != null) {
      final List<JsonType> types = switch (typeValue) {
        String() => [
          JsonType.values.firstWhere((t) => t.typeName == typeValue),
        ],
        List() =>
          typeValue
              .map((t) => JsonType.values.firstWhere((e) => e.typeName == t))
              .toList(),
        _ => <JsonType>[],
      };

      if (types.isNotEmpty) {
        if (types.contains(JsonType.num) && actualType == JsonType.int) {
          // Integers are valid numbers.
        } else if (!types.contains(actualType)) {
          errors.add(
            ValidationError.typeMismatch(
              path: currentPath,
              expectedType: types.map((t) => t.typeName).join(' or '),
              actualValue: data,
            ),
          );
          // If type doesn't match, no point in running other type-specific
          // validations
          return ValidationResult.failure(errors, AnnotationSet.empty());
        }
      }
    }

    // Now, apply keywords based on the actual type of the data.
    switch (actualType) {
      case JsonType.object:
        return (this as ObjectSchema).validateObjectSync(
          data as Map<String, Object?>,
          currentPath,
          context,
          dynamicScope,
        );
      case JsonType.list:
        return (this as ListSchema).validateListSync(
          data as List<Object?>,
          currentPath,
          context,
          dynamicScope,
        );
      case JsonType.string:
        {
          if (context
                  .vocabularies['https://json-schema.org/draft/2020-12/vocab/validation'] ==
              true) {
            final stringSchema = this as StringSchema;
            if (stringSchema.maxLength case final max?
                when (data as String).characters.length > max) {
              errors.add(
                ValidationError(
                  ValidationErrorType.maxLengthExceeded,
                  path: currentPath,
                  details:
                      'String length ${data.characters.length} exceeds '
                      'maximum length of $max',
                ),
              );
            }
            if (stringSchema.minLength case final min?
                when (data as String).characters.length < min) {
              errors.add(
                ValidationError(
                  ValidationErrorType.minLengthNotMet,
                  path: currentPath,
                  details:
                      'String length ${data.characters.length} is less '
                      'than minimum of $min',
                ),
              );
            }
            if (stringSchema.pattern case final p?) {
              if (!RegExp(p).hasMatch(data as String)) {
                errors.add(
                  ValidationError(
                    ValidationErrorType.patternMismatch,
                    path: currentPath,
                    details: 'String does not match pattern "$p"',
                  ),
                );
              }
            }
          }
          if ((this as StringSchema).format case final format?
              when context.strictFormat) {
            final FormatValidator? validator = formatValidators[format];
            if (validator != null && !validator(data as String)) {
              errors.add(
                ValidationError(
                  ValidationErrorType.formatInvalid,
                  path: currentPath,
                  details: 'String does not match format "$format"',
                ),
              );
            }
          }
        }
      case JsonType.num:
      case JsonType.int:
        {
          if (context
                  .vocabularies['https://json-schema.org/draft/2020-12/vocab/validation'] ==
              true) {
            final numSchema = this as NumberSchema;
            final numData = data as num;
            if (numSchema.multipleOf case final mOf?
                when (Decimal.parse(numData.toString()) %
                        Decimal.parse(mOf.toString())) !=
                    Decimal.zero) {
              errors.add(
                ValidationError(
                  ValidationErrorType.multipleOfInvalid,
                  path: currentPath,
                  details: '$numData is not a multiple of $mOf',
                ),
              );
            }
            if (numSchema.maximum case final max? when numData > max) {
              errors.add(
                ValidationError(
                  ValidationErrorType.maximumExceeded,
                  path: currentPath,
                  details: '$numData exceeds maximum of $max',
                ),
              );
            }
            if (numSchema.exclusiveMaximum case final exMax?
                when numData >= exMax) {
              errors.add(
                ValidationError(
                  ValidationErrorType.exclusiveMaximumExceeded,
                  path: currentPath,
                  details: '$numData exceeds exclusive maximum of $exMax',
                ),
              );
            }
            if (numSchema.minimum case final min? when numData < min) {
              errors.add(
                ValidationError(
                  ValidationErrorType.minimumNotMet,
                  path: currentPath,
                  details: '$numData is less than minimum of $min',
                ),
              );
            }
            if (numSchema.exclusiveMinimum case final exMin?
                when numData <= exMin) {
              errors.add(
                ValidationError(
                  ValidationErrorType.exclusiveMinimumNotMet,
                  path: currentPath,
                  details: '$numData is less than exclusive minimum of $exMin',
                ),
              );
            }
          }
        }
      case JsonType.boolean:
      case JsonType.nil:
      // No specific keywords for bool or null besides generic ones.
    }
    return ValidationResult.fromErrors(errors, AnnotationSet.empty());
  }

  /// Validates an object against the schema.
  ///
  /// This method is called by [validateTypeSpecificKeywordsSync] when the
  /// data is a [Map].
  ValidationResult validateObjectSync(
    Map<String, Object?> data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) {
    final objectSchema = this as ObjectSchema;
    final errors = <ValidationError>[];
    var annotations = AnnotationSet.empty();

    if (context
            .vocabularies['https://json-schema.org/draft/2020-12/vocab/validation'] ==
        true) {
      if (objectSchema.minProperties case final min?
          when data.keys.length < min) {
        errors.add(
          ValidationError(
            ValidationErrorType.minPropertiesNotMet,
            path: currentPath,
            details:
                'There should be at least $min properties. '
                'Only ${data.keys.length} were found',
          ),
        );
      }

      if (objectSchema.maxProperties case final max?
          when data.keys.length > max) {
        errors.add(
          ValidationError(
            ValidationErrorType.maxPropertiesExceeded,
            path: currentPath,
            details:
                'Exceeded maxProperties limit of $max '
                '(${data.keys.length})',
          ),
        );
      }

      for (final String reqProp in objectSchema.required ?? const []) {
        if (!data.containsKey(reqProp)) {
          errors.add(
            ValidationError(
              ValidationErrorType.requiredPropertyMissing,
              path: currentPath,
              details: 'Required property "$reqProp" is missing',
            ),
          );
        }
      }

      if (objectSchema.dependentRequired case final dr?) {
        for (final MapEntry<String, List<String>> entry in dr.entries) {
          if (data.containsKey(entry.key)) {
            for (final String requiredProp in entry.value) {
              if (!data.containsKey(requiredProp)) {
                errors.add(
                  ValidationError(
                    ValidationErrorType.dependentRequiredMissing,
                    path: currentPath,
                    details:
                        'Property "$requiredProp" is required because '
                        'property "${entry.key}" is present.',
                  ),
                );
              }
            }
          }
        }
      }
    }

    if (objectSchema.dependentSchemas case final ds?) {
      for (final MapEntry<String, Schema> entry in ds.entries) {
        if (data.containsKey(entry.key)) {
          final ValidationResult result = validateSubSchemaSync(
            entry.value,
            data,
            currentPath,
            context,
            dynamicScope,
          );
          errors.addAll(result.errors);
          annotations = annotations.merge(result.annotations);
        }
      }
    }

    final evaluatedKeys = <String>{};
    if (objectSchema.properties case final props?) {
      for (final MapEntry<String, Schema> entry in props.entries) {
        if (data.containsKey(entry.key)) {
          final List<String> newPath = [...currentPath, entry.key];
          evaluatedKeys.add(entry.key);
          final ValidationResult result = entry.value.validateSchemaSync(
            data[entry.key],
            newPath,
            context,
            dynamicScope,
          );
          errors.addAll(result.errors);
          annotations = annotations.merge(result.annotations);
        }
      }
    }

    if (objectSchema.patternProperties case final patternProps?) {
      for (final MapEntry<String, Schema> entry in patternProps.entries) {
        final pattern = RegExp(entry.key);
        for (final String dataKey in data.keys) {
          if (pattern.hasMatch(dataKey)) {
            final newPath = [...currentPath, dataKey];
            evaluatedKeys.add(dataKey);
            final ValidationResult result = entry.value.validateSchemaSync(
              data[dataKey],
              newPath,
              context,
              dynamicScope,
            );
            errors.addAll(result.errors);
            annotations = annotations.merge(result.annotations);
          }
        }
      }
    }

    if (objectSchema.propertyNames case final propNamesSchema?) {
      for (final String key in data.keys) {
        final ValidationResult result = propNamesSchema.validateSchemaSync(
          key,
          currentPath,
          context,
          dynamicScope,
        );
        errors.addAll(result.errors);
        annotations = annotations.merge(result.annotations);
      }
    }

    for (final String dataKey in data.keys) {
      if (evaluatedKeys.contains(dataKey)) continue;

      if (objectSchema.additionalProperties case final ap?) {
        final newPath = [...currentPath, dataKey];
        final ValidationResult result = ap.validateSchemaSync(
          data[dataKey],
          newPath,
          context,
          dynamicScope,
        );
        if (!result.isValid) {
          errors.add(
            ValidationError(
              ValidationErrorType.additionalPropertyNotAllowed,
              path: newPath,
              details: 'Additional property "$dataKey" is not allowed.',
            ),
          );
        }
        errors.addAll(result.errors);
        annotations = annotations.merge(result.annotations);
        evaluatedKeys.add(dataKey);
      }
    }
    annotations.evaluatedKeys.addAll(evaluatedKeys);
    return ValidationResult.fromErrors(errors, annotations);
  }

  /// Validates a list against the schema.
  ///
  /// This method is called by [validateTypeSpecificKeywordsSync] when the
  /// data is a [List].
  ValidationResult validateListSync(
    List<Object?> data,
    List<String> currentPath,
    ValidationContext context,
    List<Schema> dynamicScope,
  ) {
    final errors = <ValidationError>[];
    final evaluatedItems = <int>{};
    final listSchema = this as ListSchema;
    if (context
            .vocabularies['https://json-schema.org/draft/2020-12/vocab/validation'] ==
        true) {
      if (listSchema.minItems case final min? when data.length < min) {
        errors.add(
          ValidationError(
            ValidationErrorType.minItemsNotMet,
            path: currentPath,
            details:
                'List has ${data.length} items, but must have at '
                'least $min',
          ),
        );
      }

      if (listSchema.maxItems case final max? when data.length > max) {
        errors.add(
          ValidationError(
            ValidationErrorType.maxItemsExceeded,
            path: currentPath,
            details:
                'List has ${data.length} items, but must have less '
                'than $max',
          ),
        );
      }

      if (listSchema.uniqueItems == true) {
        final seenItems = HashSet<Object?>(
          equals: deepEquals,
          hashCode: deepHashCode,
        );
        for (final item in data) {
          if (!seenItems.add(item)) {
            errors.add(
              ValidationError(
                ValidationErrorType.uniqueItemsViolated,
                path: currentPath,
                details: 'List contains duplicate items',
              ),
            );
            break; // Found a duplicate, no need to check further.
          }
        }
      }
    }

    if (listSchema.contains case final containsSchema?) {
      final matches = <int>[];
      for (var i = 0; i < data.length; i++) {
        final ValidationResult result = validateSubSchemaSync(
          containsSchema,
          data[i],
          currentPath,
          context,
          dynamicScope,
        );
        if (result.isValid) {
          matches.add(i);
        }
      }

      for (final index in matches) {
        evaluatedItems.add(index);
      }

      if (context
              .vocabularies['https://json-schema.org/draft/2020-12/vocab/validation'] ==
          true) {
        final int matchCount = matches.length;
        if (matchCount == 0 &&
            (listSchema.minContains == null || listSchema.minContains! > 0)) {
          errors.add(
            ValidationError(
              ValidationErrorType.containsInvalid,
              path: currentPath,
              details: 'Array does not contain a valid item',
            ),
          );
        }
        if (listSchema.minContains case final min? when matchCount < min) {
          errors.add(
            ValidationError(
              ValidationErrorType.minContainsNotMet,
              path: currentPath,
              details:
                  'Array must contain at least $min valid items, but found '
                  '$matchCount',
            ),
          );
        }
        if (listSchema.maxContains case final max? when matchCount > max) {
          errors.add(
            ValidationError(
              ValidationErrorType.maxContainsExceeded,
              path: currentPath,
              details:
                  'Array must contain at most $max valid items, but found '
                  '$matchCount',
            ),
          );
        }
      }
    }

    if (listSchema.prefixItems case final pItems?) {
      for (var i = 0; i < pItems.length && i < data.length; i++) {
        evaluatedItems.add(i);
        final newPath = [...currentPath, i.toString()];
        final ValidationResult result = validateSubSchemaSync(
          pItems[i],
          data[i],
          newPath,
          context,
          dynamicScope,
        );
        errors.addAll(result.errors);
      }
    }
    if (listSchema.items case final itemSchema?) {
      final int startIndex = listSchema.prefixItems?.length ?? 0;
      for (var i = startIndex; i < data.length; i++) {
        evaluatedItems.add(i);
        final newPath = [...currentPath, i.toString()];
        final ValidationResult result = validateSubSchemaSync(
          itemSchema,
          data[i],
          newPath,
          context,
          dynamicScope,
        );
        errors.addAll(result.errors);
      }
    }
    return ValidationResult.fromErrors(
      errors,
      AnnotationSet(evaluatedItems: evaluatedItems),
    );
  }

  /// Gets the [JsonType] of the given [data].
  JsonType getJsonType(Object? data) {
    if (data is Map) return JsonType.object;
    if (data is List) return JsonType.list;
    if (data is String) return JsonType.string;
    if (data is int) return JsonType.int;
    if (data is num) {
      if (data is int || data.remainder(1) == 0) {
        return JsonType.int;
      }
      return JsonType.num;
    }
    if (data is bool) return JsonType.boolean;
    if (data == null) return JsonType.nil;
    // This should not happen for valid JSON data..
    throw StateError('Unknown JSON type for value: $data');
  }

  /// Resolves a `$ref` reference to a schema, without performing any I/O.
  ///
  /// Returns `null` if the reference does not resolve. Throws a
  /// [SchemaResolutionRequiredException] if resolving it would require
  /// fetching a schema that is not registered; see [validateSync].
  (Schema, Uri)? resolveRefSync(
    String ref,
    Schema rootSchema,
    ValidationContext context,
  ) {
    final Uri baseUri = context.sourceUri!;
    final Uri refUri = baseUri.resolve(ref);
    try {
      final Schema? schema = context.resolveSchemaSync(refUri);
      if (schema == null) return null;
      return (schema, refUri);
    } on SchemaFetchException {
      return null;
    }
  }

  /// Resolves a `$dynamicRef` reference to a schema, without performing any
  /// I/O.
  ///
  /// Returns `null` if the reference does not resolve. Throws a
  /// [SchemaResolutionRequiredException] if resolving it would require
  /// fetching a schema that is not registered; see [validateSync].
  (Schema, Uri)? resolveDynamicRefSync(
    String ref,
    List<Schema> dynamicScope,
    ValidationContext context,
  ) {
    // 1. Initial resolution, just like $ref
    final (Schema, Uri)? initialResolution = resolveRefSync(
      ref,
      dynamicScope.last,
      context,
    );
    if (initialResolution == null) {
      // Can't resolve initially, so it's an error.
      return null;
    }

    final (Schema initialSchema, Uri initialUri) = initialResolution;
    final String fragment = initialUri.fragment;

    if (fragment.isEmpty || fragment.startsWith('/')) {
      // Not a plain name fragment, so not a dynamic anchor.
      return initialResolution;
    }

    // We need to check if the anchor that was resolved to is dynamic.
    // The initialSchema is the schema that the anchor points to.
    if (initialSchema.$dynamicAnchor != fragment) {
      return initialResolution;
    }

    // It has a dynamic anchor, so we need to search the dynamic scope.
    // The dynamic scope is a list where the first element is the outermost.
    // We should search from outermost to innermost.
    for (final scopeSchema in dynamicScope) {
      if (scopeSchema.$id != null) {
        // This is a schema resource
        final Schema? found = _findDynamicAnchorInSchema(fragment, scopeSchema);
        if (found != null) {
          final Uri? resourceUri = context.schemaRegistry.getUriForSchema(
            scopeSchema,
          );
          if (resourceUri != null) {
            final Uri newUri = resourceUri.replace(fragment: fragment);
            // Found the outermost, so we can use it.
            return (found, newUri);
          }
        }
      }
    }

    return initialResolution;
  }

  /// Finds a schema with a matching `$dynamicAnchor` in the given [schema].
  Schema? _findDynamicAnchorInSchema(String anchorName, Schema schema) {
    Schema? result;
    final visited = <Map<String, Object?>>{};

    void visit(Object? current, {required bool isRootOfResource}) {
      if (result != null) return;
      if (current is Map<String, Object?>) {
        if (visited.contains(current)) return;
        visited.add(current);

        final currentSchema = Schema.fromMap(current);

        if (!isRootOfResource && currentSchema.$id != null) {
          return;
        }

        if (currentSchema.$dynamicAnchor == anchorName) {
          result = currentSchema;
          return;
        }

        for (final Object? value in current.values) {
          visit(value, isRootOfResource: false);
        }
      } else if (current is List) {
        for (final Object? item in current) {
          visit(item, isRootOfResource: false);
        }
      }
    }

    visit(schema.value, isRootOfResource: true);
    return result;
  }
}
