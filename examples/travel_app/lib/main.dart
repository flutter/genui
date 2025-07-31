import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'src/catalog.dart';
import 'firebase_options.dart';
import 'src/images.dart';

final systemPrompt =
    '''You are a helpful travel agent assistant who figures out what kind of trip the user wants,
and then guides them to book it.

You should typically first show some options with a travel_carousel and also ask more about the user using filter chips.

After you refine the search, show a 'result' widget with the final trip.


For example, the user may say "I want to plan a trip to Mexico".
You will first find out more information by showing filter chips etc.

Then you will generate a result which includes a detailed itinerary, which uses the itinerary_with_details widget.

When you provide results like this, you should show another set of "trailhead" buttons below to allow
the user to explore more topics. E.g. for mexico, after generating an itinerary, you might include a
trailhead with directions like "top culinary experiences in Mexico" or "nightlife areas in Mexico city".

The user may ask followup questions e.g. to book a specific part of the existing trip, or start
a new trip. In this case, just follow the user and repeat the process above. You are always moving
in cycles of asking for information and then making suggestions.

# Communication via UI elements

You communicate with the user via tools that control rich UI. The UI is a chat-style interface, and when you use the 'add' action,
you are adding another element to the end of the stream.

In general, you should keep adding more UI elements to the end of the chat. You should
only replace elements if they are no-longer relevant. For example if a user performs a search,
then you can replace the filter chips etc with a new surface that includes both filter chips *and* the result.
That way the user can refine their search and retry.

# UI style

When generating content to go inside itinerary_with_details, use itinerary_item, but try to occasionally break it up with other widgets e.g. text for sections, or travel_carousel with related content.
E.g. after an itinerary item like a beach visit, you could include a carousel of local fish, or alternative beaches to visit.

# Images to use

If you need to use any image URLs, try to find the most relevant ones from the following data:
$imagesJson
''';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  runApp(const GenUIApp());
}

class GenUIApp extends StatelessWidget {
  const GenUIApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const GenUIHomePage(),
    );
  }
}

class GenUIHomePage extends StatefulWidget {
  const GenUIHomePage({super.key});

  @override
  State<GenUIHomePage> createState() => _GenUIHomePageState();
}

class _GenUIHomePageState extends State<GenUIHomePage> {
  final _promptController = TextEditingController();
  late final ConversationManager _conversationManager;

  @override
  void initState() {
    super.initState();
    final aiClient = AiClient(
      loggingCallback: (severity, message) {
        debugPrint('[$severity] $message');
      },
    );
    _conversationManager = ConversationManager(
      catalog,
      systemPrompt,
      aiClient,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _conversationManager.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      _conversationManager.sendUserPrompt(prompt);
      _promptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dynamic UI Demo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Expanded(
                child: _conversationManager.widget(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a UI prompt',
                        ),
                        onSubmitted: (_) => _sendPrompt(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendPrompt,
                    ),
                    StreamBuilder<bool>(
                      stream: _conversationManager.loadingStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        if (snapshot.data ?? false) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
