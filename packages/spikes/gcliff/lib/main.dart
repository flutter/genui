import 'dart:async';

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
      title: 'Gemini CLI with Flutter Framework Gen UI',
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
  late final _gcli = GCliProcess(_updateStatus);
  final _status = ValueNotifier<String>('');
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _updateStatus(String update) {
    _status.value += '\n$update';
  }

  Future<void> _start() async {
    final question = 'What is the capital of France?';
    _updateStatus('Asking: $question');
    await _gcli.ask(question);

    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('GCliff'),
      ),
      body: Center(
        child: SelectionArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ValueListenableBuilder<String>(
              valueListenable: _status,
              builder: (context, value, child) {
                unawaited(_scheduleScrollToBottom(_scrollController));
                return Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _scheduleScrollToBottom(ScrollController controller) async {
  await Future.delayed(const Duration(milliseconds: 100));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}
