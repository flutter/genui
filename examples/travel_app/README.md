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
- **Dynamic UI State Management**: The `GenUiConversation` and `GenUiManager` from `genui` handle the orchestration of AI interaction, state of the dynamically generated UI surfaces, and event processing. The application's main page (`TravelPlannerPage`) uses `GenUiConversation` to manage the overall conversation flow and UI updates.
- **Firebase Integration**: The application uses `FirebaseAiContentGenerator` from `genui_firebase_ai` to connect to a Firebase backend for AI model access, as shown in `lib/src/travel_planner_page.dart`.

## Getting Started

To run this application, you will need to have a Firebase project set up and configured.

1. **Configure Firebase**: Follow the instructions to add Firebase to your
   Flutter app for the platforms you intend to support (Android, iOS, web,
   etc.). See [USAGE.md](../../packages/genui/USAGE.md) for steps to
   configure Firebase. You will need to replace the placeholder values in
   `lib/firebase_options.dart` with the configuration from your own Firebase
   project.
2. **Run the App**: Once Firebase is configured, you can run the app like any other Flutter project:

   ```bash
   flutter run
   ```
