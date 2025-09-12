// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/flutter_genui_dev.dart';
import 'package:flutter_genui_firebase_ai/flutter_genui_firebase_ai.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'src/chats/inline_chat_travel_planner.dart';
import 'src/chats/no_chat_travel_planner.dart';
import 'src/chats/side_chat_travel_planner.dart';
import 'src/controllers/travel_planner_canvas_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  await TravelPlannerCanvasController.initializeAssetImages();
  configureGenUiLogging(level: Level.ALL);
  runApp(const TravelApp());
}

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

  /// The AI client to use for the application.
  ///
  /// If null, a default [FirebaseAiClient] will be created by the
  /// travel planner screens.
  final AiClient? aiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agentic Travel Inc.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => InlineChatTravelPlanner(aiClient: aiClient),
        '/side-chat': (context) => SideChatTravelPlanner(aiClient: aiClient),
        '/no-chat': (context) => NoChatTravelPlanner(aiClient: aiClient),
      },
    );
  }
}
