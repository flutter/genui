# GenUI Tic Tac Toe

A demonstration of the `genui` framework, showcasing how to build an AI-powered
interactive game using Flutter and Large Language Models (LLMs). But unlike
typical text-based LLM interactions, this example focuses on a **game-centric
UI** where the AI manipulates a graphical board.

<video controls src="readme/genui-tic-tac-toe.mov" title="Title"></video>

## Features

-   **AI-Powered Gameplay**: Play Tic Tac Toe against Google Gemini, OpenAI
    GPT-4, or Anthropic Claude.
-   **GenUI Components**: The game board is a custom Flutter widget
    (`TicTacToeBoard`) exposed to the AI via a `genui` catalog.
-   **Dynamic Interaction**:
    -   **Auto-Start**: The game begins automatically.
    -   **Thinking State**: Displays randomized status messages (e.g.,
        "Strategizing...", "Calculating...") along with a "jumping dots"
        animation while the AI thinks.
    -   **Input Safety**: The user's input is visually and functionally disabled
        while waiting for the AI, preventing race conditions.
    -   **Game State Management**: The AI tracks the game state and updates the
        board via tool calls.
-   **Simplified Configuration**: API keys are managed via environment variables
    for easy setup.

## Setup

This example requires an API key for at least one of the supported providers
(Google, OpenAI, Anthropic).

### 1. Get an API Key

-   **Google Gemini**: [Get an API Key](https://aistudio.google.com/app/apikey)
-   **OpenAI**: [Get an API Key](https://platform.openai.com/api-keys)
-   **Anthropic**: [Get an API Key](https://console.anthropic.com/settings/keys)

### 2. Run the App

Pass your API key using the `--dart-define` flag when running the app.

**For Google Gemini:**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

**For OpenAI:**
```bash
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
```

**For Anthropic:**
```bash
flutter run --dart-define=ANTHROPIC_API_KEY=your_api_key_here
```

## How It Works

1.  **Catalog Definition**: The `TicTacToeBoard` is defined in a `Catalog`,
    giving the AI knowledge of its schema (a list of 9 strings representing the
    board cells).
2.  **Tool Use**: The AI doesn't just "talk"; it uses the `showBoard` tool to
    render the game state.
3.  **Authentication**: The app uses `dartantic` to abstract the different AI
    providers. The `ProviderSelectionPage` automatically picks the provider
    based on the environment variables you supplied.
