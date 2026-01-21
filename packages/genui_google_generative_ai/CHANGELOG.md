# `genui_google_generative_ai` Changelog

## 0.6.2 (in progress)

## 0.6.1

- **Fix**: Ensure bytes are not null when creating Blob in content converter.

## 0.6.0

- **BREAKING**: Removed `GenUiConfiguration` from `GoogleGenerativeAiContentGenerator`.
- Bumped dependencies: `google_cloud_ai_generativelanguage_v1beta` to ^0.3.0 and `google_cloud_protobuf` to ^0.3.0.

- Bump dependent package versions to the latest that work with Flutter stable.

## 0.5.1

- Homepage URL was updated.

## 0.5.0

- Initial release of `genui_google_generative_ai`
- Implements `ContentGenerator` using Google Cloud Generative Language API
- Provides `GoogleGenerativeAiContentGenerator` with support for:
  - Tool calling and function declarations
  - Schema adaptation from `json_schema_builder` to Google Cloud API format
  - Message conversion between genui ChatMessages and Google Cloud Content
  - Protocol Buffer Struct type conversion for function calling
  - System instructions and custom model selection
  - Token usage tracking
- Includes `GoogleContentConverter` for message format conversion
- Includes `GoogleSchemaAdapter` for JSON schema adaptation
- Compatible with Google Cloud Generative Language API v1beta
- Supports multiple Type enum values (string, number, integer, boolean, array, object)
- Handles `FunctionCallingConfig` with AUTO and ANY modes

