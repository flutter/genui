# custom_backend

This app demonstrates integrating genui with a custom backend without using
predefined provider packages (`genui_firebase_ai`,
`genui_google_generative_ai`).

**Key Features:**
- Direct integration with `SurfaceController`
- Manual tool call parsing and handling
- Saved response testing for development without API calls
- Shows how to build `UiSchemaDefinition` and `catalogToFunctionDeclaration`

**Key Files:**
- `lib/backend.dart` - Custom backend implementation
- `lib/gemini_client.dart` - Direct Gemini API client
- `assets/data/saved-response-*.json` - Pre-recorded responses for testing

## Getting Started

This is a standard flutter app that directly calls the Gemini API. You need
a Gemini API Key. Get one in [Google AI Studio][ai-studio].

Then pass it as a `--dart-define` when calling `flutter run`:

**Run:**
```bash
cd examples/custom_backend
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

[ai-studio]: https://aistudio.google.com/api-keys
