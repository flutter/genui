// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_client/a2ui_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'agent_connection_view.dart';
import 'agent_state.dart';
import 'manual_input_view.dart';
import 'settings_view.dart';

void main() {
  initA2uiLogger();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AgentState(),
      child: Consumer<AgentState>(
        builder: (context, agentState, child) {
          final textTheme = Theme.of(context).textTheme;
          return MaterialApp(
            scaffoldMessengerKey: agentState.scaffoldMessengerKey,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange,
                secondaryContainer: Colors.blueGrey[100],
              ),
              textTheme: GoogleFonts.montserratTextTheme(textTheme).copyWith(
                displayLarge: GoogleFonts.lora(
                  textStyle: textTheme.displayLarge,
                  fontWeight: FontWeight.bold,
                ),
                displayMedium: GoogleFonts.lora(
                  textStyle: textTheme.displayMedium,
                  fontWeight: FontWeight.bold,
                ),
                headlineSmall: GoogleFonts.lora(
                  textStyle: textTheme.headlineSmall,
                  fontWeight: FontWeight.bold,
                ),
                titleLarge: GoogleFonts.lora(textStyle: textTheme.titleLarge),
              ),
            ),
            home: Builder(
              builder: (context) {
                return DefaultTabController(
                  length: 2,
                  child: SafeArea(
                    child: Scaffold(
                      appBar: AppBar(
                        title: const Text('A2UI Client Example'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const SettingsView(),
                                ),
                              );
                            },
                          ),
                        ],
                        bottom: const TabBar(
                          tabs: [
                            Tab(text: 'Agent Connection'),
                            Tab(text: 'Manual Input'),
                          ],
                        ),
                      ),
                      body: const TabBarView(
                        children: [AgentConnectionView(), ManualInputView()],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
