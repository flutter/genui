// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'components_tab.dart';
import 'create_tab.dart';
import 'gallery_tab.dart';
import 'surface_editor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const ComposerApp());
}

class ComposerApp extends StatelessWidget {
  const ComposerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Composer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ComposerShell(),
    );
  }
}

/// The main shell widget with a NavigationRail for switching between tabs.
class ComposerShell extends StatefulWidget {
  const ComposerShell({super.key});

  @override
  State<ComposerShell> createState() => _ComposerShellState();
}

class _ComposerShellState extends State<ComposerShell> {
  int _selectedIndex = 0;

  /// When set, the surface editor is shown with this JSON pre-loaded.
  /// This is used when the user clicks "Open in Surface Editor" from the
  /// gallery detail dialog.
  String? _editorJsonl;
  String? _editorDataJson;
  int _editorKey = 0;

  void _openSurfaceEditor(String jsonl, {String? dataJson}) {
    setState(() {
      _editorJsonl = jsonl;
      _editorDataJson = dataJson;
      _editorKey++;
      _selectedIndex = 0; // Switch to the Create tab
    });
  }

  void _closeSurfaceEditor() {
    setState(() {
      _editorJsonl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: Text('Gallery'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.widgets_outlined),
                selectedIcon: Icon(Icons.widgets),
                label: Text('Components'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Create tab - shows editor if JSON is loaded, else prompt
                _editorJsonl != null
                    ? SurfaceEditorView(
                        key: ValueKey('editor-$_editorKey'),
                        initialJsonl: _editorJsonl!,
                        initialDataJson: _editorDataJson,
                        onClose: _closeSurfaceEditor,
                      )
                    : CreateTab(
                        onSurfaceCreated: (String jsonl, {String? dataJson}) {
                          _openSurfaceEditor(jsonl, dataJson: dataJson);
                        },
                      ),
                GalleryTab(onOpenInEditor: _openSurfaceEditor),
                const ComponentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
