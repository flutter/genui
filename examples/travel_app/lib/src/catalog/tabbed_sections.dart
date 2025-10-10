// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  properties: {
    'sections': S.list(
      description: 'A list of sections to display as tabs.',
      items: S.object(
        properties: {
          'title': A2uiSchemas.stringReference(
            description: 'The title of the tab.',
          ),
          'child': A2uiSchemas.componentReference(
            description: 'The ID of the child widget for the tab content.',
          ),
        },
        required: ['title', 'child'],
      ),
    ),
  },
  required: ['sections'],
);

extension type _TabbedSectionsData.fromMap(Map<String, Object?> _json) {
  factory _TabbedSectionsData({required List<Map<String, Object?>> sections}) =>
      _TabbedSectionsData.fromMap({'sections': sections});

  Iterable<_TabSectionItemData> get sections => (_json['sections'] as List)
      .cast<Map<String, Object?>>()
      .map<_TabSectionItemData>(_TabSectionItemData.fromMap);
}

extension type _TabSectionItemData.fromMap(Map<String, Object?> _json) {
  factory _TabSectionItemData({
    required Map<String, Object?> title,
    required String child,
  }) => _TabSectionItemData.fromMap({'title': title, 'child': child});

  Map<String, Object?> get title => _json['title'] as Map<String, Object?>;
  String get childId => _json['child'] as String;
}

/// A container that organizes content into a series of tabs.
///
/// This widget is particularly useful for breaking down complex information
/// into manageable sections. For example, in a multi-day travel itinerary, each
/// tab could represent a different day, a different city, or a different theme
/// (e.g., "Activities", "Dining"). This helps to avoid overwhelming the user
/// with a long, scrolling list of information.
final tabbedSections = CatalogItem(
  name: 'TabbedSections',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final tabbedSectionsData = _TabbedSectionsData.fromMap(
          data as Map<String, Object?>,
        );
        final sections = tabbedSectionsData.sections.map((section) {
          final titleNotifier = dataContext.subscribeToString(section.title);
          return _TabSectionData(
            titleNotifier: titleNotifier,
            childId: section.childId,
          );
        }).toList();

        return _TabbedSections(sections: sections, buildChild: buildChild);
      },
);

class _TabSectionData {
  final ValueNotifier<String?> titleNotifier;
  final String childId;

  _TabSectionData({required this.titleNotifier, required this.childId});
}

class _TabbedSections extends StatefulWidget {
  const _TabbedSections({required this.sections, required this.buildChild});

  final List<_TabSectionData> sections;
  final Widget Function(String id) buildChild;

  @override
  State<_TabbedSections> createState() => _TabbedSectionsState();
}

class _TabbedSectionsState extends State<_TabbedSections>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.sections.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: widget.sections.map((section) {
            return Tab(
              child: ValueListenableBuilder<String?>(
                valueListenable: section.titleNotifier,
                builder: (context, title, child) {
                  return Text(title ?? '');
                },
              ),
            );
          }).toList(),
        ),
        IndexedStack(
          index: _selectedIndex,
          children: widget.sections
              .map((section) => widget.buildChild(section.childId))
              .toList(),
        ),
      ],
    );
  }
}
