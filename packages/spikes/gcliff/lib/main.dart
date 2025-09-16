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
  late final _process = GCliProcess(_status);
  final _status = ValueNotifier<String>('');
  final _scrollController = ScrollController();

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
      body: Center(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _start,
        tooltip: 'Start',
        child: const Icon(Icons.add),
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
