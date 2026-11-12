# [json_schema_builder](https://pub.dev/packages/json_schema_builder) Change Log

## 0.1.8

- **Fix**: Resolving a `$ref` to an `$anchor`, or a `$dynamicRef`, no longer
  throws a `TypeError` when the schema declares a property named `$id`,
  `$anchor` or `$dynamicAnchor`. The anchor search now looks only inside
  subschemas, so it no longer reads the `properties` map, or data under
  keywords such as `const`, `enum` and `default`, as a schema.
- **Behavior change**: An `$anchor` or `$dynamicAnchor` under a keyword that
  doesn't take a schema, such as an unknown keyword or the pre-2020-12
  `definitions`, `dependencies`, array `items` and `additionalItems`, is no
  longer found. JSON Schema 2020-12 Core §9.4.2 leaves those targets undefined.
  JSON Pointer references such as `#/definitions/a` still resolve.

## 0.1.7

- **Feature**: Add `Schema.validateSync`, a synchronous validation entry point
  for schemas whose references all resolve without fetching. Validation itself
  is now a synchronous core, and the existing `Schema.validate` is a thin
  asynchronous wrapper around it that fetches the remote references it needs
  into the `SchemaRegistry` up front, in parallel. Behavior of `validate` is
  unchanged.
- **Feature**: Add `SchemaRegistry.resolveSync` and `SchemaRegistry.fetch`,
  which split reference resolution from fetching, and
  `SchemaRegistry.prefetchDependencies`, which fetches the schemas a schema
  refers to in parallel so that it can then be validated synchronously.
- **Feature**: Export `SchemaFetchException` and the new
  `SchemaResolutionRequiredException`, which `validateSync` throws when a
  reference can only be resolved by fetching.

## 0.1.6

- **Feature**: Export `SchemaRegistry` to support managing schema references during component validation.

## 0.1.5

- **Internal**: publishing workflow automation.

## 0.1.4

- **Fix**: Remove `package:intl` dependency (#682, #686).
- **Internal**: Enable stricter dynamic-related analysis (#652).
- **Internal**: Use null-aware elements per latest lint update (#690).
- **Internal**: Update test_and_fix script and json_schema_builder infrastructure.

## 0.1.3

- Use [`email_validator`](https://pub.dev/packages/email_validator) package to
  validate emails instead of a regular expression.
- Reduce required version for `meta` package to 1.16.0.

## 0.1.2

- Add dartdoc comments to all public APIs.
- Treat failures to fetch remote schemas as validation failures.
- Add web compatibility using conditional imports for `dart:io`.

## 0.1.1

- Fix homepage link

## 0.1.0

- Initial version.
