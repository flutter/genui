# Dart Schema Builder Examples

This directory contains examples demonstrating how to use the `dart_schema_builder` package.

## `build_and_validate_schema.dart`

This is a comprehensive example that shows how to:

1. **Build a complex schema** programmatically using the library's fluent API. The schema describes a "System Event" and uses advanced features like:
   - Nested `ObjectSchema`s.
   - `ListSchema` with unique item constraints.
   - `StringSchema` with regular expression patterns.
   - `IntegerSchema` with range constraints.
   - The `oneOf` combinator to enforce that the event data must match exactly one of several defined event types.
2. **Create valid and invalid data** to test against the schema.
3. **Run the validator** and print the detailed, human-readable error messages for the invalid data.

To run the example, execute the following command from the root of the `dart_schema_builder` package:

```shell
dart run example/build_and_validate_schema.dart
```
