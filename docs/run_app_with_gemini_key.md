# How to run app with API key

## Get an API key

Obtain a Google Cloud API key with access
to the Generative Language API from the
[Google AI Studio](https://aistudio.google.com/app/apikey).


## Set up the API key

* Option 1: Using the VS Code based IDE UI

1. Open the example in the IDE.
2. Set the API key in the `.env` file of the workspace root:

   ```bash
   GEMINI_API_KEY=your_api_key_here
   ```

3. Run the app from the IDE UI.

* Option 2: Using the Command Line

1. Set the API key in the environment:

   ```bash
   export GEMINI_API_KEY=your_api_key_here
   ```

2. Run the app from the terminal:

   ```bash
   flutter run -d <device> --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
   ```
