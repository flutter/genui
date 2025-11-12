# Verdure Landscape Design Example

This directory contains a sample application demonstrating a Flutter client interacting with a Python-based A2A (Agent-to-Agent) server for landscape design.

## Prerequisites

- Flutter SDK
- Python 3.13 or higher
- [UV](https://docs.astral.sh/uv/)
- A Gemini API Key
  - You can create one using [AI Studio](https://ai.google.dev/aistudio).

## Running the Example

To run this example, you need to start both the server and the client application.

### 1. Start the Server

a. Navigate to the server directory:

   ```bash
   cd server
   ```

b. Create a `.env` file with your Gemini API key:

   ```bash
   echo "GEMINI_API_KEY=YOUR_API_KEY_HERE" > .env
   ```
   *Replace `YOUR_API_KEY_HERE` with your actual Gemini API key.*

c. Install dependencies and run the server using UV:

   ```bash
   uv run verdure
   ```

The server will start on `http://localhost:10002` by default.

### 2. Run the Client

a. Open a new terminal window.

b. Navigate to the client directory:

   ```bash
   cd client
   ```

c. Run the Flutter application on your desired device:

   ```bash
   flutter run
   ```

The Flutter application will connect to the server running on `localhost:10002` to interact with the landscape design agent.

## Disclaimer

Important: The sample code provided is for demonstration purposes and illustrates the mechanics of the Agent-to-Agent (A2A) protocol. When building production applications, it is critical to treat any agent operating outside of your direct control as a potentially untrusted entity.

All data received from an external agent—including but not limited to its AgentCard, messages, artifacts, and task statuses—should be handled as untrusted input. Failure to properly validate and sanitize this data before use can introduce security vulnerabilities into your application.
