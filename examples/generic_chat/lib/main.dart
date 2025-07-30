import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'firebase_options.dart';
import 'src/core_catalog.dart';
import 'src/widget_tree_llm_adapter.dart';

final systemPrompt =
    '''You are a helpful assistant who figures out what the user wants to do and then helps suggest options so they can develop a plan and find relevant information.

        The user will ask questions, and you will respond by generating appropriate UI elements. Typically, you will first elicit more information to understand the user's needs, then you will start displaying information and the user's plans.

        For example, the user may say "I want to plan a trip to Mexico". You will first ask some questions by displaying a combination of UI elements, such as a slider to choose budget, options showing activity preferences etc. Then you will walk the user through choosing a hotel, flight and accomodation.

        Typically, you should not update existing surfaces and instead just continually "add" new ones.
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GenUIHomePage(),
    );
  }
}

class GenUIHomePage extends StatefulWidget {
  const GenUIHomePage({
    super.key,
    this.aiClient,
  });

  final AiClient? aiClient;

  @override
  State<GenUIHomePage> createState() => _GenUIHomePageState();
}

class _GenUIHomePageState extends State<GenUIHomePage> {
  final _promptController = TextEditingController();
  late final WidgetTreeLlmAdapter _widgetTreeLlmAdapter;

  @override
  void initState() {
    super.initState();
    final aiClient = widget.aiClient ??
        AiClient(
          loggingCallback: (severity, message) {
            debugPrint('[$severity] $message');
          },
        );
    _widgetTreeLlmAdapter = WidgetTreeLlmAdapter(
      coreCatalog,
      systemPrompt,
      aiClient,
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _widgetTreeLlmAdapter.dispose();
    super.dispose();
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      _widgetTreeLlmAdapter.sendUserPrompt(prompt);
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
                child: _widgetTreeLlmAdapter.widget(),
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
                      stream: _widgetTreeLlmAdapter.loadingStream,
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
