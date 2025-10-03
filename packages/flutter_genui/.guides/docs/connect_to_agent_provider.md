---
title: Connecting to an agent provider
description: |
  Instructions for connecting `flutter_genui` to the agent provider of your
  choice.
---

Follow these steps to connect `flutter_genui` to an agent provider and give
your app the ability to send messages and receive/display generated UI.

The instructions below use `FirebaseAiClient`. If your app uses a different
`AiClient`, substitute its name where you see `FirebaseAiClient`.

## 1. Create the connection to an agent

Use the following instructions to connect your app to your chosen agent
provider.

1. Create a `GenUiManager`, and provide it with the catalog of widgets you want
   to make available to the agent.
2. Create an `AiClient`, and provide it with a system instruction and a set of
   tools (functions you want the agent to be able to invoke). You should always
   include those provided by `GenUiManager`, but feel free to include others.
3. Create a `UiAgent` using the instances of `AiClient` and `GenUiManager`. Your
   app will primarily interact with this object to get things done.

    For example:

    ```dart
    class _MyHomePageState extends State<MyHomePage> {
      late final GenUiManager _genUiManager;
      late final UiAgent _uiAgent;

      @override
      void initState() {
        super.initState();

        // Create a GenUiManager with a widget catalog.
        // The CoreCatalogItems contain basic widgets for text, markdown, and images.
        _genUiManager = GenUiManager(catalog: CoreCatalogItems.asCatalog());

        // Create an AiClient to communicate with the LLM.
        // Provide system instructions and the tools from the GenUiManager.
        final aiClient = FirebaseAiClient(
          systemInstruction: '''
            You are an expert in creating funny riddles. Every time I give you a word,
            you should generate UI that displays one new riddle related to that word.
            Each riddle should have both a question and an answer.
            ''',
          tools: _genUiManager.getTools(),
        );

        // Create the UiAgent to orchestrate everything.
        _uiAgent = UiAgent(
          genUiManager: _genUiManager,
          aiClient: aiClient,
          onSurfaceAdded: _onSurfaceAdded, // Added in the next step.
          onSurfaceDeleted: _onSurfaceDeleted, // Added in the next step.
        );
      }

      @override
      void dispose() {
        _textController.dispose();
        _uiAgent.dispose();
        _genUiManager.dispose();
        super.dispose();
      }
    }
    ```

### 2. Send messages and display the agent's responses

Send a message to the agent using the `sendRequest` method in the `UiAgent`
class.

To receive and display generated UI:

1. Use `UiAgent`'s callbacks to track the addition and removal of UI surfaces as
   they are generated. These events include a "surface ID" for each surface.
2. Build a `GenUiSurface` widget for each active surface using the surface IDs
   received in the previous step.

    For example:

    ```dart
    class _MyHomePageState extends State<MyHomePage> {

      // ...

      final _textController = TextEditingController();
      final _surfaceIds = <String>[];

      // Send a message containing the user's text to the agent.
      void _sendMessage(String text) {
        if (text.trim().isEmpty) return;
        _uiAgent.sendRequest(UserMessage.text(text));
      }

      // A callback invoked by the [UiAgent] when a new UI surface is generated.
      // Here, the ID is stored so the build method can create a GenUiSurface to
      // display it.
      void _onSurfaceAdded(SurfaceAdded update) {
        setState(() {
          _surfaceIds.add(update.surfaceId);
        });
      }

      // A callback invoked by UiAgent when a UI surface is removed.
      void _onSurfaceDeleted(SurfaceRemoved update) {
        setState(() {
          _surfaceIds.remove(update.surfaceId);
        });
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _surfaceIds.length,
                  itemBuilder: (context, index) {
                    // For each surface, create a GenUiSurface to display it.
                    final id = _surfaceIds[index];
                    return GenUiSurface(host: _uiAgent.host, surfaceId: id);
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Send the user's text to the agent.
                          _sendMessage(_textController.text);
                          _textController.clear();
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    ```
