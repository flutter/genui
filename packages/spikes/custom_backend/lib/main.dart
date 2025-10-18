import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'protocol.dart';

void main() {
  runApp(const MyApp());
}

const _title = 'Custom Backend Demo';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  final _controller = TextEditingController(
    text: 'Show me options how you can help me, using radio buttons.',
  );
  final _protocol = Protocol();
  late final GenUiManager _genUi = GenUiManager(catalog: _protocol.catalog);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(_title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _controller),
            const SizedBox(height: 16.0),
            IconButton(
              onPressed: () {
                _genUi.addOrUpdateSurface(surfaceId, definition)
              },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
