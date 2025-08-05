// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'firebase_options.dart';
import 'src/asset_images.dart';
import 'src/catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  _imagesJson = await assetImageCatalogJson();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _promptController = TextEditingController();
  late final GenUiManager _genUiManager;
  late AiClient aiClient;

  @override
  void initState() {
    super.initState();
    aiClient = AiClient(
      loggingCallback: (severity, message) {
        debugPrint('[$severity] $message');
      },
    );
    _genUiManager = GenUiManager.conversation(
      catalog: catalog,
      instruction: prompt,
      llmConnection: aiClient,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _genUiManager.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      _genUiManager.sendUserPrompt(prompt);
      _promptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: const Icon(Icons.menu),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 16.0), // Add spacing between icon and text
            Text('Dynamic UI Demo'),
          ],
        ),
        actions: [
          ValueListenableBuilder<GeminiModel>(
            valueListenable: aiClient.model,
            builder: (context, currentModel, child) {
              return PopupMenuButton<GeminiModel>(
                icon: const Icon(Icons.psychology_outlined),
                onSelected: (GeminiModel value) {
                  // Handle model selection
                  aiClient.switchModel(value);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<GeminiModel>>[
                      PopupMenuItem<GeminiModel>(
                        value: GeminiModel.flash,
                        child: Row(
                          children: [
                            const Text('Gemini Flash'),
                            if (currentModel == GeminiModel.flash)
                              const Icon(Icons.check),
                          ],
                        ),
                      ),
                      PopupMenuItem<GeminiModel>(
                        value: GeminiModel.pro,
                        child: Row(
                          children: [
                            const Text('Gemini Pro'),
                            if (currentModel == GeminiModel.pro)
                              const Icon(Icons.check),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
          const Icon(Icons.person_outline),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Expanded(child: _genUiManager.widget()),
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
                      stream: _genUiManager.loadingStream,
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

late final String _imagesJson;

final prompt =
    '''You are a helpful travel agent assistant who figures out what kind of trip the user wants,
and then guides them to book it.

You should typically first show some options with a travel_carousel and also ask more about the
user request using filter chips.

After you refine the search, show a 'itinerary_with_details' widget with the final trip.

# Example
For example, the user may say "I want to plan a trip to Mexico".
You will first find out more information by showing filter chips etc.

Then you will generate a result which includes a detailed itinerary, which
uses the itinerary_with_details widget. Typically, you should keep the filter chips *and*
the itinerary_with_details together in a column, so the user can refine their search.

When you provide results like this, you should show another set of "trailhead" buttons below to allow
the user to explore more topics. E.g. for mexico, after generating an itinerary, you might include a
trailhead with directions like "top culinary experiences in Mexico" or "nightlife areas in Mexico city".

The user may ask followup questions e.g. to book a specific part of the existing trip, or start
a new trip. In this case, just follow the user and repeat the process above. You are always moving
in cycles of asking for information and then making suggestions. If the user requests something other than a complete trip booking,
e.g. ideas about jazz clubs or food tours etc, use something like a travel_carousel to show options, rather
than a full itinerary_with_details. If the followup question seems to be a departure from the previous context,
'add' a new surface rather than updating an existing one.

# Communication via UI elements

You communicate with the user via tools that control rich UI. The UI is a chat-style interface,
and when you use the 'add' action,
you are adding another element to the end of the stream.

In general, you should keep adding more UI elements to the end of the chat. You should
only replace elements if they are no-longer relevant. For example if a userperforms a search,
then you can replace the filter chips etc with a new surface that includes both
filterchips *and* the result.
That way the user can refine their search and retry.

# UI style

When generating content to go inside itinerary_with_details, use itinerary_item, but try to occasionally break it up with other widgets e.g. section_header items to break up the section, or travel_carousel with related content.
E.g. after an itinerary item like a beach visit, you could include a carousel of local fish, or alternative beaches to visit.

If you need to use any images, try to find the most relevant ones from the following
asset images:
$_imagesJson
''';
