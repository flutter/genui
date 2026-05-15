# Composer

A Flutter desktop app for generating and editing [A2UI](https://a2ui.org)
surfaces using the `genui` library.

## Features

- **Create** - Describe a UI in plain text and have Gemini generate an A2UI
  surface from your description.
- **Gallery** - Browse and preview pre-built sample surfaces.
- **Components** - View all available built-incatalog components.
- **Surface Editor** - Edit A2UI JSONL and data models with a live preview.

## Setup & run

The Gallery and Components tabs work without an API key.

The Create feature requires a Gemini API key. Get one from
<https://aistudio.google.com/app/apikey>.

Provide the key in one of two ways:

1. **Shell environment variable:**

   ```sh
   export GEMINI_API_KEY="your-key-here"
   flutter run
   ```

2. **Dart define:**

   ```sh
   flutter run --dart-define=GEMINI_API_KEY=your-key-here
   ```
