import 'package:example/sdk/agent/input.dart';
import 'package:example/sdk/agent/widget.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const _appTitle = 'GenUI Example';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const _MyHomePage(),
    );
  }
}

final _myImageCatalog = ImageCatalog();

class _MyHomePage extends StatefulWidget {
  const _MyHomePage();

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  final GenUiController _controller = GenUiController(
    imageCatalog: _myImageCatalog,
    agentIcon: 'assets/agent_icon.png',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.menu),
        title: Row(
          children: const <Widget>[
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 8.0), // Add spacing between icon and text
            Text('Chat'),
          ],
        ),
        actions: [Icon(Icons.person_outline), SizedBox(width: 8.0)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: GenUi.invitation(
            initialPrompt: 'Invite user to create a vacation travel itinerary.',
            controller: _controller,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
