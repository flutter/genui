import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage();

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  late final _chatBoxController = (() => ChatBoxController(onInputSubmitted))();
  final _log = TextEditingController(text: '');

  void onInputSubmitted(String input) {
    _log.text += 'User: $input\n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Box Tester'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.red,
              child: ChatBox(_chatBoxController),
            ),
          ),
          SizedBox(
            height: 150,
            child: Expanded(
              child: TextField(
                controller: _log,
                readOnly: true,
                decoration: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
