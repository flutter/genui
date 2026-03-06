# Glow

A creative AI companion that generates personalized wallpapers and immersive UI experiences using Gemini and GenUI.

## Overview

Glow is a demonstration of how Generative AI can be integrated into Flutter applications to create dynamic, personalized user experiences. By answering a few questions about your mood and style, Glow uses Gemini to generate unique visual assets and adapts the UI to match.

## Features

-   **Intelligent Onboarding**: A personality-driven quiz that gathers user preferences.
-   **AI Generation**: Integrated with Gemini (Google Generative AI) for real-time image and style generation.
-   **Immersive Aesthetics**: High-performance fragment shaders create ambient, glowing background effects.
-   **Modern Design**: Built with Material 3, custom typography, and a premium "glassmorphism" aesthetic.
-   **GenUI Driven**: Showcases the power of the GenUI framework for building intelligent, adaptive interfaces.

## Getting Started

### Prerequisites

-   Flutter SDK (^3.11.0-144.0.dev or later recommended)
-   A Google Gemini API Key

### Configuration

1.  Obtain an API key from [Google AI Studio](https://aistudio.google.com/).
2.  The first time you run the app, you will be prompted to enter your API key in the settings.

### Running the App

```bash
flutter run
```

## Project Structure

-   `lib/screens/`: Main application screens (Welcome, Quiz, Generation, Editor).
-   `lib/widgets/`: Reusable UI components including branded elements and shader-based backgrounds.
-   `lib/services/`: Backend logic for Gemini integration.
-   `lib/theme.dart`: Centralized design system tokens (colors, typography, shadows).
-   `shaders/`: Custom GLSL fragment shaders for advanced visual effects.
