// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'src/catalog.dart';
import 'src/travel_planner_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerApple: const AppleDebugProvider(),
    providerAndroid: const AndroidDebugProvider(),
    providerWeb: ReCaptchaV3Provider('debug'),
  );
  await loadImagesJson();
  final logger = configureGenUiLogging(level: Level.ALL);
  logger.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: '
      '${record.message}',
    );
  });
  runApp(const TravelApp());
}

const _title = 'Agentic Travel Inc';

/// The root widget for the travel application.
///
/// This widget sets up the [MaterialApp], which configures the overall theme,
/// title, and home page for the app. It serves as the main entry point for the
/// user interface.
class TravelApp extends StatelessWidget {
  /// Creates a new [TravelApp].
  ///
  /// The optional [aiClient] can be used to inject a specific AI client,
  /// which is useful for testing with a mock implementation.
  const TravelApp({this.aiClient, super.key});

  final AiClient? aiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _TravelAppBody(aiClient),
    );
  }
}

class _TravelAppBody extends StatelessWidget {
  _TravelAppBody(this.aiClient);

  /// The AI client to use for the application.
  ///
  /// If null, a default [FirebaseAiClient] will be created by the
  /// [TravelPlannerPage].
  final AiClient? aiClient;

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'Travel': TravelPlannerPage(aiClient: aiClient),
      'Widget Catalog': const CatalogTab(),
    };
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: const Icon(Icons.menu),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.local_airport),
              SizedBox(width: 16.0), // Add spacing between icon and text
              Text(_title),
            ],
          ),
          actions: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 8.0),
          ],
          bottom: TabBar(
            tabs: tabs.entries.map((entry) => Tab(text: entry.key)).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs.entries.map((entry) => entry.value).toList(),
        ),
      ),
    );
  }
}

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DebugCatalogView(catalog: travelAppCatalog);
  }

  @override
  bool get wantKeepAlive => true;
}
