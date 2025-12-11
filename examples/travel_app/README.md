# Travel App Example

This application is a demonstration of the `genui` package, showcasing how to build a dynamic, conversational user interface powered by a generative AI model (like Google's Gemini).

The app functions as a travel planning assistant. Users can describe their desired trip, and the AI will respond by generating a rich, interactive UI to help them plan and refine their itinerary.

## How it Works

Instead of responding with text, the AI in this application communicates by building a user interface from a predefined catalog of Flutter widgets. The conversation flows as follows:

1. **User Prompt**: The user starts by typing a request, such as "I want to plan a trip to Mexico."
2. **AI-Generated UI**: The AI receives the prompt and, guided by its system instructions, generates a response in the form of UI elements. Initially, it might present a `travelCarousel` of destinations and `filterChipGroup` to ask clarifying questions about the user's budget, desired activities, or travel dates.
3. **User Interaction**: The user interacts with the generated UI (e.g., selects an option from a filter chip). These interactions are sent back to the AI as events.
4. **UI Refinement**: The AI processes the user's selections and refines the plan, often by adding new UI elements to the conversation. For example, it might display a detailed `itinerary_with_details` widget that outlines the proposed trip.
5. **Continued Conversation**: The AI may also present a `trailhead` widget with suggested follow-up questions (e.g., "Top culinary experiences," "Nightlife areas"), allowing the conversation to continue organically.

All of the UI is generated dynamically and streamed into a chat-like view, creating a seamless and interactive experience.

## Key Features Demonstrated

This example highlights several core concepts of the `genui` package:

- **Dynamic UI Generation**: The entire user interface is constructed on-the-fly by the AI based on the conversation.
- **Component Catalog**: The AI builds the UI from a custom, domain-specific catalog of widgets defined in `lib/src/catalog.dart`. This includes widgets like `TravelCarousel`, `ItineraryEntry`, and `OptionsFilterChipInput`.
- **System Prompt Engineering**: The behavior of the AI is guided by a detailed system prompt located in `lib/src/travel_planner_page.dart`. This prompt instructs the AI on how to act like a travel agent and which widgets to use in various scenarios.
- **Dynamic UI State Management**: The `GenUiConversation` and `A2uiMessageProcessor` from `genui` handle the orchestration of AI interaction, state of the dynamically generated UI surfaces, and event processing.
- **Multiple AI Backends**: The app supports switching between **Google Generative AI** (direct API) and **Firebase Vertex AI**. This is configured in `lib/src/config/configuration.dart`.
- **Tool Use**: The AI uses tools like `ListHotelsTool` to fetch real-world data (mocked in this example) and present it to the user.
- **Widget Catalog**: A dedicated tab allows developers to inspect all available widgets in the catalog, facilitating development and debugging.

## Getting Started

This application can be run using either the **Google Generative AI** API directly (default) or **Firebase Vertex AI**.

### Option 1: Google Generative AI (Default)

This is the simplest way to get started.

1.  **Get an API Key**: Obtain a Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).
2.  **Run the App**: Pass your API key as a dart-define or environment variable:

    ```bash
    flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
    ```

    *Alternatively, you can set the `GEMINI_API_KEY` environment variable in your shell.*

### Option 2: Firebase Vertex AI

To use Firebase, you need to configure the project and update the code.

1.  **Configure Firebase**: Follow the instructions in the main `genui` package [README.md](../../packages/genui/README.md#configure-firebase-ai-logic) to add Firebase to your Flutter app.
    *   Set up a Firebase project.
    *   Generate `firebase_options.dart` using `flutterfire configure`.
2.  **Update Configuration**:
    *   Open `lib/src/config/configuration.dart` and change `aiBackend` to `AiBackend.firebase`.
    *   Open `lib/main.dart` and uncomment the Firebase initialization code and imports (look for `UNCOMMENT_FOR_FIREBASE`).
3.  **Run the App**:
    ```bash
    flutter run
    ```
