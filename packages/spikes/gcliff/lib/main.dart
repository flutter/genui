import 'package:flutter/material.dart';

import 'process.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GCliff',
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
  final _process = GCliProcess();
  var _status = '';

  Future<void> _start() async {
    await _process.run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('GCliff'),
      ),
      body: Center(child: Text(_status)),
      floatingActionButton: FloatingActionButton(
        onPressed: _start,
        tooltip: 'Start',
        child: const Icon(Icons.add),
      ),
    );
  }
}
