// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'src/travel_planner_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });

  await loadImagesJson();
  runApp(const TravelApp());
}

const _title = 'Agentic Travel Inc (Dartantic)';

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: _title,
    home: TravelPlannerHomePage(),
  );
}

class TravelPlannerHomePage extends StatelessWidget {
  const TravelPlannerHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_airport),
          SizedBox(width: 16.0),
          Text(_title),
        ],
      ),
    ),
    body: TravelPlannerView(),
  );
}
