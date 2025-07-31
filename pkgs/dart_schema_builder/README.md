# Dart Schema Builder

A robust and developer-friendly Dart library for creating, validating, and working with JSON Schemas. `dart_schema_builder` provides a fluent, type-safe API to define the structure of your data, ensuring its integrity and correctness throughout your application.

This package is compliant with the [**JSON Schema Draft 2020-12 specification**](https://json-schema.org/draft/2020-12), making it a powerful and standard-compliant choice for data validation. Whether you're building a backend service that consumes structured data, a client-side application that needs to validate user input, or any system where data consistency is key, this package offers the tools you need.

## Key Features

- **JSON Schema 2020-12 Compliant:** Implements the full core and validation specifications for Draft 2020-12, ensuring compatibility and access to the latest features.
- **Fluent & Type-Safe API:** Construct complex schemas programmatically with a clear, chainable, and Dart-native API. Say goodbye to writing raw JSON maps for your schemas.
- **Comprehensive Validation:** Go beyond simple type checks. Define required fields, length constraints, patterns, numerical ranges, and advanced keywords like `unevaluatedProperties` and `dependentSchemas`.
- **Remote and Dynamic References:** Resolve schema references (`$ref`) from local files or remote HTTP sources. Full support for dynamic scope resolution with `$dynamicRef` and `$dynamicAnchor`.
- **Rich Type Support:** First-class support for all major data types:
  - `ObjectSchema`: For structured objects with defined properties.
  - `ListSchema`: For arrays with constraints on items.
  - `StringSchema`: With pattern matching, length limits, and format validation (e.g., `date-time`, `email`).
  - `NumberSchema` & `IntegerSchema`: With range and multiple-of checks.
  - `BooleanSchema` & `NullSchema`.
- **Advanced Schema Composition:** Combine and reuse schemas with powerful logical combinators:
  - `allOf`: The data must be valid against _all_ of the given sub-schemas.
  - `anyOf`: The data must be valid against _at least one_ of the given sub-schemas.
  - `oneOf`: The data must be valid against _exactly one_ of the given sub-schemas.
  - `not`: The data must _not_ be valid against the given sub-schema.
- **Detailed & Actionable Error Reporting:** When validation fails, you get a list of `ValidationError` objects. Each error contains:
  - A precise `path` to the invalid data field.
  - The specific `error` type (e.g., `minLengthNotMet`, `typeMismatch`).
  - A human-readable `details` message.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```shell
dart pub add dart_schema_builder
```

Import the library in your Dart code:

```dart
import 'package:dart_schema_builder/dart_schema_builder.dart';
```

## Usage Example

Let's define a schema for a user profile and then validate some data against it.

```dart
import 'package:dart_schema_builder/dart_schema_builder.dart';

Future<void> main() async {
  // 1. Define a schema for a 'User' object.
  final userProfileSchema = ObjectSchema(
    title: 'User Profile',
    description: 'Schema for a user profile object',
    // 'username' and 'email' are mandatory.
    required: ['username', 'email'],
    properties: {
      'username': StringSchema(
        description: 'Must be 3-20 characters, lowercase letters and numbers only.',
        minLength: 3,
        maxLength: 20,
        pattern: r'^[a-z0-9]+',
      ),
      'email': StringSchema(
        description: 'A valid email address.',
        format: 'email', // Use the built-in format validator
      ),
      'age': IntegerSchema(
        description: 'Optional age, must be 18 or older.',
        minimum: 18,
      ),
      'roles': ListSchema(
        description: 'Optional list of user roles, must be unique.',
        items: StringSchema(enumValues: ['admin', 'editor', 'viewer']),
        uniqueItems: true,
      ),
    },
    // No other properties are allowed in the object.
    additionalProperties: false,
  );

  // 2. Create some data to validate.

  // This data perfectly matches the schema.
  final validUser = {
    'username': 'testuser123',
    'email': 'test@example.com',
    'age': 30,
    'roles': ['editor', 'viewer'],
  };

  // This data has several issues.
  final invalidUser = {
    'username': 'UPPERCASE', // Fails pattern (uppercase)
    'email': 'not-an-email', // Fails email format
    'age': 17,               // Fails minimum age
    'roles': ['admin', 'admin'], // Fails uniqueItems
    'extraField': 'not allowed' // Fails additionalProperties: false
  };

  // 3. Validate the data and inspect the results.

  print('--- Validating a correct user profile ---');
  final validResult = await userProfileSchema.validate(validUser);
  if (validResult.isEmpty) {
    print('✅ Success! The data is valid.');
  }

  print('\n--- Validating an incorrect user profile ---');
  final invalidResult = await userProfileSchema.validate(invalidUser);
  if (invalidResult.isNotEmpty) {
    print('❌ Failure! The data is invalid. Found ${invalidResult.length} errors:');
    for (final error in invalidResult) {
      // The toErrorString() method provides a human-readable summary.
      print('  - ${error.toErrorString()}');
    }
  }
}
```

### Example Output

```txt
--- Validating a correct user profile ---
✅ Success! The data is valid.

--- Validating an incorrect user profile ---
❌ Failure! The data is invalid. Found 5 errors:
  - String "UPPERCASE" doesn't match the pattern "^[a-z0-9]+$" at path #root["username"]
  - String "not-an-email" does not match format "email" at path #root["email"]
  - Value 17 is not at least 18 at path #root["age"]
  - List contains duplicate items at path #root["roles"]
  - Additional property "extraField" is not allowed. at path #root["extraField"]
```
