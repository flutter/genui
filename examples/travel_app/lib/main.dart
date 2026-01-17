// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Be sure to uncomment these Firebase initialization code and these imports
// if using Firebase AI.
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart'
    show FirebaseAiContentGenerator;
import 'package:logging/logging.dart';

import 'src/catalog.dart';
import 'src/config/configuration.dart';
import 'src/travel_planner_page.dart';

// If you want to convert to using Firebase AI, run:
//
//   sh tool/refresh_firebase.sh <project_id>
//
// to refresh the Firebase configuration for a specific Firebase project.
// and uncomment the Firebase initialization code and import below that is
// marked with UNCOMMENT_FOR_FIREBASE, and set the value of `aiBackend` to
// `AiBackend.firebase` in `lib/config/configuration.dart`.

// import 'firebase_options.dart'; // UNCOMMENT_FOR_FIREBASE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase if we are using the Firebase backend.
  if (aiBackend == AiBackend.firebase) {
    await Firebase.initializeApp(
      // UNCOMMENT_FOR_FIREBASE (See top of file for details)
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleDebugProvider(),
      providerAndroid: const AndroidDebugProvider(),
      providerWeb: ReCaptchaV3Provider('debug'),
    );
  }

  await loadImagesJson();
  configureGenUiLogging(level: Level.ALL);

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
  /// The optional [contentGenerator] can be used to inject a specific AI
  /// client, which is useful for testing with a mock implementation.
  const TravelApp({this.contentGenerator, super.key});

  final ContentGenerator? contentGenerator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _TravelAppBody(contentGenerator: contentGenerator),
    );
  }
}

class _TravelAppBody extends StatelessWidget {
  const _TravelAppBody({this.contentGenerator});

  /// The AI client to use for the application.
  ///
  /// If null, a default [FirebaseAiContentGenerator] will be created by the
  /// [TravelPlannerPage].
  final ContentGenerator? contentGenerator;

  @override
  Widget build(BuildContext context) {
    final Map<String, StatefulWidget> tabs = {
      'Travel': TravelPlannerPage(contentGenerator: contentGenerator),
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
              SizedBox(width: 16.0),
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
