# Changelog

## 0.1.0

* Initial release of flutter_genui_google_generative_ai
* Implements ContentGenerator using Google Cloud Generative Language API
* Provides GoogleGenerativeAiContentGenerator with support for:
  * Tool calling and function declarations
  * Schema adaptation from json_schema_builder to Google Cloud API format
  * Message conversion between flutter_genui ChatMessages and Google Cloud Content
  * Protocol Buffer Struct type conversion for function calling
  * System instructions and custom model selection
  * Token usage tracking
* Includes GoogleContentConverter for message format conversion
* Includes GoogleSchemaAdapter for JSON schema adaptation
* Compatible with Google Cloud Generative Language API v1beta
* Supports multiple Type enum values (string, number, integer, boolean, array, object)
* Handles FunctionCallingConfig with AUTO and ANY modes

