# Examples

This directory contains example applications demonstrating the `genui` SDK capabilities.

## Overview

| Example | Complexity | Backend | Description |
|---------|------------|---------|-------------|
| [catalog_gallery](#catalog_gallery) | Simple | None | Visual reference for core catalog widgets |
| [custom_backend](#custom_backend) | Intermediate | Custom/Saved | Demonstrates custom backend integration |
| [travel_app](#travel_app) | Advanced | Firebase/Google AI | Full travel planning assistant with custom catalog |
| [verdure](#verdure) | Advanced | Python A2A Server | Full-stack landscape design agent |

## Running Examples

Most examples support multiple AI backends. The default is typically Google Generative AI which requires an API key:

```bash
# Get API key from https://aistudio.google.com/app/apikey
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

---

## catalog_gallery

A developer tool for visualizing and testing the core widget catalog. Displays all available `CoreCatalogItems` widgets and allows interaction testing.

**Key Features:**
- Browse all core catalog widgets
- Interactive widget testing with event logging
- Sample file loading support

**Run:**
```bash
cd examples/catalog_gallery
flutter run
```

---

## custom_backend

Demonstrates integrating genui with a custom backend without using predefined provider packages (`genui_firebase_ai`, `genui_google_generative_ai`).

**Key Features:**
- Direct integration with `A2uiMessageProcessor`
- Manual tool call parsing and handling
- Saved response testing for development without API calls
- Shows how to build `UiSchemaDefinition` and `catalogToFunctionDeclaration`

**Key Files:**
- `lib/backend.dart` - Custom backend implementation
- `lib/gemini_client.dart` - Direct Gemini API client
- `assets/data/saved-response-*.json` - Pre-recorded responses for testing

**Run:**
```bash
cd examples/custom_backend
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

---

## travel_app

A full-featured travel planning assistant demonstrating advanced genui capabilities with a custom domain-specific widget catalog.

**Key Features:**
- Custom widget catalog with travel-specific components (carousel, itinerary, filter chips)
- Tool use (`ListHotelsTool` for fetching hotel data)
- System prompt engineering for AI behavior
- Dynamic UI generation based on conversation
- Supports Firebase AI and Google Generative AI backends

**Key Files:**
- `lib/src/catalog.dart` - Custom travel widgets catalog
- `lib/src/catalog/` - Individual widget implementations
- `lib/src/travel_planner_page.dart` - Main page with system prompt
- `lib/src/tools/booking/` - AI tool implementations
- `lib/src/config/configuration.dart` - Backend configuration

**Custom Widgets:**
- `TravelCarousel` - Image carousel for destinations
- `OptionsFilterChipInput` / `CheckboxFilterChipsInput` - User preference inputs
- `Itinerary` / `ItineraryEntry` - Trip planning display
- `ListingsBooker` - Hotel booking interface
- `Trailhead` - Suggested follow-up questions
- `TabbedSections` - Tabbed content display

**Run:**
```bash
cd examples/travel_app
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

**Switch to Firebase:**
1. Edit `lib/src/config/configuration.dart`: set `aiBackend = AiBackend.firebase`
2. Uncomment Firebase imports in `lib/main.dart`
3. Run `flutterfire configure` to generate Firebase options

---

## verdure

A full-stack example with a Python server and Flutter client demonstrating the A2A (Agent-to-Agent) protocol for landscape design.

**Prerequisites:**
- Python 3.13+
- [UV](https://docs.astral.sh/uv/) package manager
- Gemini API key

**Architecture:**
```
verdure/
├── server/         # Python A2A server
│   └── verdure/    # Agent implementation
└── client/         # Flutter client app
```

**Run Server:**
```bash
cd examples/verdure/server/verdure
echo "GEMINI_API_KEY=YOUR_API_KEY" > .env
uv run .
# Server starts on http://localhost:10002
```

**Run Client:**
```bash
cd examples/verdure/client
flutter run
```

**Android Emulator:**
The emulator uses `10.0.2.2` as localhost alias. Start server with:
```bash
uv run . --base-url="http://10.0.2.2:10002"
```

**Key Files:**
- `server/verdure/agent.py` - AI agent logic
- `server/verdure/a2ui_schema.py` - A2UI protocol schema
- `client/lib/features/ai/ai_provider.dart` - Client AI integration
