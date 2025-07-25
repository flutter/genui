import 'package:example/sdk/agent/input.dart';
import 'package:example/sdk/agent/widget.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
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
  final GenUiController _controller = GenUiController(_myImageCatalog);

  @override
  Widget build(BuildContext context) {
    return GenUi.invitation(
      initialPrompt: 'Invite user to create a vacation travel itinerary.',
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
