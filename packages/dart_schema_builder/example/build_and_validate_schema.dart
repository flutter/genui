// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';

Future<void> main() async {
  // This example demonstrates how to build a complex, interesting schema to
  // validate a "System Event". Our system can have different types of events,
  // and we want to ensure that the data for each event is structured correctly.

  // We'll use the `oneOf` combinator to define that an event must be one of
  // several specific event types (e.g., a Login Event or a File Upload Event).

  // =========================================================================
  // 1. Define the Schemas for Different Event Payloads
  // =========================================================================

  // First, let's define the schema for a "Login Event".
  // This event occurs when a user logs in.
  final loginEventPayloadSchema = Schema.object(
    title: 'Login Event Payload',
    description: 'Schema for the data associated with a user login event.',
    required: ['userId', 'ipAddress'],
    properties: {
      'userId': StringSchema(
        description: 'The unique identifier of the user who logged in.',
        minLength: 1,
      ),
      'ipAddress': StringSchema(
        description: 'The IPv4 address from which the login occurred.',
        // A simple regex to validate an IPv4 address format.
        pattern:
            r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      ),
    },
    // We don't allow any other properties in the payload.
    additionalProperties: false,
  );

  // Next, let's define the schema for a "File Upload Event".
  // This event is more complex and includes a list of uploaded files.
  final fileUploadEventPayloadSchema = Schema.object(
    title: 'File Upload Event Payload',
    description: 'Schema for the data associated with a file upload event.',
    required: ['userId', 'files'],
    properties: {
      'userId': Schema.string(
        description: 'The unique identifier of the user who uploaded files.',
      ),
      'files': Schema.list(
        description: 'A list of files that were uploaded.',
        minItems: 1, // At least one file must be uploaded.
        // Each item in the list must be a unique object matching the file
        // schema.
        uniqueItems: true,
        items: Schema.object(
          required: ['filename', 'size'],
          properties: {
            'filename': Schema.string(
              description: 'The name of the uploaded file.',
              minLength: 1,
            ),
            'size': Schema.integer(
              description: 'The size of the file in bytes.',
              minimum: 0, // File size cannot be negative.
            ),
            'mimeType': Schema.string(
              description: 'Optional MIME type of the file.',
            ),
          },
          additionalProperties: false,
        ),
      ),
    },
    additionalProperties: false,
  );

  // =========================================================================
  // 2. Define the Top-Level Event Schema using `oneOf`
  // =========================================================================

  // Now, we'll create the main schema for any "System Event".
  // An event has a common structure (id, timestamp, eventType) and a payload
  // that must match one of our defined event payload schemas.
  final systemEventSchema = Schema.combined(
    oneOf: [
      // If eventType is 'user_login', the payload must match this schema.
      Schema.object(
        properties: {
          'eventType': Schema.string(enumValues: ['user_login']),
          'payload': loginEventPayloadSchema,
        },
      ),
      // If eventType is 'file_upload', the payload must match this one.
      Schema.object(
        properties: {
          'eventType': Schema.string(enumValues: ['file_upload']),
          'payload': fileUploadEventPayloadSchema,
        },
      ),
    ],
  );

  // =========================================================================
  // 3. Create Sample Data and Validate It
  // =========================================================================

  print('--- 1. Validating a Correct Login Event ---');
  final validLoginEvent = {
    'eventId': 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
    'timestamp': '2025-07-28T10:00:00Z',
    'eventType': 'user_login',
    'payload': {'userId': 'user-123', 'ipAddress': '192.168.1.1'},
  };
  await validateAndPrintResults(systemEventSchema, validLoginEvent);

  print('\n--- 2. Validating a Correct File Upload Event ---');
  final validFileUploadEvent = {
    'eventId': 'b2c3d4e5-f6a7-8901-2345-67890abcdef1',
    'timestamp': '2025-07-28T11:30:00Z',
    'eventType': 'file_upload',
    'payload': {
      'userId': 'user-456',
      'files': [
        {
          'filename': 'document.pdf',
          'size': 1024,
          'mimeType': 'application/pdf',
        },
        {'filename': 'image.png', 'size': 51200},
      ],
    },
  };
  await validateAndPrintResults(systemEventSchema, validFileUploadEvent);

  print('\n--- 3. Validating an Invalid Event (Multiple Errors) ---');
  final invalidEvent = {
    'eventId': 'not-a-uuid', // Fails pattern
    'timestamp': '2025-07-28 12:00:00', // Fails pattern (not ISO 8601)
    'eventType': 'user_logout', // Fails enumValues
    'payload': {
      'userId': 'user-789',
      // This payload doesn't match any of the `oneOf` schemas.
      'reason': 'user initiated',
    },
  };
  await validateAndPrintResults(systemEventSchema, invalidEvent);

  print('\n--- 4. Validating an Invalid Login Event Payload ---');
  final invalidLoginPayload = {
    'eventId': 'c3d4e5f6-a7b8-9012-3456-7890abcdef12',
    'timestamp': '2025-07-28T14:00:00Z',
    'eventType': 'user_login',
    'payload': {
      // Missing required 'ipAddress'
      'userId': 'user-123',
      'extraField': 'this is not allowed', // Fails additionalProperties
    },
  };
  await validateAndPrintResults(systemEventSchema, invalidLoginPayload);
}

/// Helper function to run validation and print the results in a friendly
/// format.
Future<void> validateAndPrintResults(
  Schema schema,
  Map<String, Object?> data,
) async {
  final errors = await schema.validate(data);

  if (errors.isEmpty) {
    print('✅ Success! The data is valid.');
  } else {
    print('❌ Failure! The data is invalid. Found ${errors.length} errors:');
    for (final error in errors) {
      // The toErrorString() method provides a human-readable summary of the
      // error.
      print('  - ${error.toErrorString()}');
    }
  }
}
