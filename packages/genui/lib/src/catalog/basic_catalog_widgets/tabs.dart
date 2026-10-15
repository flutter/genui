// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';
import 'widget_helpers.dart';

final _schema = S.object(
  description: 'A tab layout to navigate between different child components.',
  properties: {
    'tabs': S.list(
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(
            description: 'The label for the tab.',
          ),
          'content': A2uiSchemas.componentReference(
            description:
                'The content (widget ID) to display when this tab is active.',
          ),
        },
        required: ['label', 'content'],
      ),
    ),
    'activeTab': A2uiSchemas.numberReference(
      description: 'The index of the currently active tab.',
    ),
  },
  required: ['tabs'],
);

extension type _TabsData.fromMap(JsonMap _json) {
  factory _TabsData({required List<JsonMap> tabs, Object? activeTab}) =>
      _TabsData.fromMap({'tabs': tabs, 'activeTab': activeTab});

  /// The tabs that can be drawn, each with its position in the list as the
  /// agent sent it.
  ///
  /// An entry that is not an object is left out. `activeTab` counts positions
  /// in the list as sent, so the tabs that remain keep theirs: leaving one out
  /// must not move the selection onto its neighbour.
  List<(int, JsonMap)> get tabs {
    final Object? value = _json['tabs'];
    if (value is! List) return const <(int, JsonMap)>[];
    return <(int, JsonMap)>[
      for (var i = 0; i < value.length; i++)
        if (value[i] case final Map<Object?, Object?> entry)
          (i, entry.cast<String, Object?>()),
    ];
  }

  Object? get activeTab => _json['activeTab'];
}

class _TabsWidget extends StatefulWidget {
  const _TabsWidget({
    required this.tabs,
    required this.positions,
    required this.itemContext,
    required this.activeTab,
    this.initialTab = 0,
    required this.onTabChanged,
  });

  final List<JsonMap> tabs;

  /// Where each of [tabs] sits in the list the agent sent. [activeTab], and
  /// the value [onTabChanged] writes back, count positions there.
  final List<int> positions;
  final CatalogItemContext itemContext;
  final int? activeTab;
  final int initialTab;
  final ValueChanged<int> onTabChanged;

  @override
  State<_TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<_TabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// The drawn tab for [position] in the list as sent, or the next one after
  /// it when the entry there was left out.
  int _indexFor(int position) => widget.positions
      .where((int p) => p < position)
      .length
      .clamp(0, widget.tabs.length - 1);

  @override
  void initState() {
    super.initState();
    final int initialIndex = _indexFor(widget.activeTab ?? widget.initialTab);
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void didUpdateWidget(_TabsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.positions, oldWidget.positions)) {
      _tabController.dispose();
      final int initialIndex = _indexFor(widget.activeTab ?? widget.initialTab);
      _tabController = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: initialIndex,
      );
      _tabController.addListener(_handleTabSelection);
    } else if (widget.activeTab != oldWidget.activeTab) {
      _handleExternalChange();
    }
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged(widget.positions[_tabController.index]);
    }
  }

  void _handleExternalChange() {
    final int? position = widget.activeTab;
    if (position == null) return;
    // A position with no drawn tab, out of range or left out, moves nothing.
    final int index = widget.positions.indexOf(position);
    if (index >= 0 && index != _tabController.index) {
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          tabs: widget.tabs.map((tabItem) {
            final Object? labelRef = tabItem['label'] ?? tabItem['title'];
            return BoundString(
              dataContext: widget.itemContext.dataContext,
              value: labelRef,
              builder: (context, label) {
                return Tab(text: label ?? '');
              },
            );
          }).toList(),
        ),
        SizedBox(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final int index = _tabController.index;
              return IndexedStack(
                index: index,
                sizing: StackFit.loose,
                children: widget.tabs.map((tabItem) {
                  // A tab that names no content is an empty tab, not a
                  // reason to take the rest of them down.
                  final String? contentId = asStringOrNull(
                    tabItem['content'] ?? tabItem['child'],
                  );
                  if (contentId == null) return const SizedBox.shrink();
                  return widget.itemContext.buildChild(contentId);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A Material Design tab layout.
///
/// This widget displays a [TabBar] and a view area to allow navigation
/// between different child components. Each tab in `tabs` has a label and
/// a corresponding child component ID to display when selected.
///
/// ## Parameters:
///
/// - `tabs`: A list of tabs to display, each with a `label` and a `content`
///   widget ID.
/// - `activeTab`: (Optional) Binding to the current tab index.
final tabs = CatalogItem(
  name: 'Tabs',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final tabsData = _TabsData.fromMap(itemContext.data as JsonMap);
    final List<(int, JsonMap)> drawn = tabsData.tabs;
    // `TabController` throws on a length of zero, and it is built in
    // `initState`, so the check has to happen before the widget exists. An
    // agent that sends a `Tabs` with nothing in it has asked for nothing to
    // be shown.
    if (drawn.isEmpty) return const SizedBox.shrink();
    final Object? activeTabRef = tabsData.activeTab;
    final path = (activeTabRef is Map && activeTabRef.containsKey('path'))
        ? activeTabRef['path'] as String
        : '${itemContext.id}.activeTab';

    return BoundNumber(
      dataContext: itemContext.dataContext,
      value: {'path': path},
      builder: (context, value) {
        // We pass the current value to _TabsWidget, which will handle
        // updating the TabController when it changes.
        // We no longer pass a ValueNotifier.
        return _TabsWidget(
          tabs: [for (final (_, tab) in drawn) tab],
          positions: [for (final (position, _) in drawn) position],
          itemContext: itemContext,
          activeTab: value?.toInt(),
          initialTab: activeTabRef is num ? activeTabRef.toInt() : 0,
          onTabChanged: (newIndex) {
            itemContext.dataContext.update(DataPath(path), newIndex);
          },
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Tabs",
          "activeTab": { "path": "/currentTab" },
          "tabs": [
            {
              "label": "Overview",
              "content": "text1"
            },
            {
              "label": "Details",
              "content": "text2"
            }
          ]
        },
        {
          "id": "text1",
          "component": "Text",
          "text": "This is a short summary of the item."
        },
        {
          "id": "text2",
          "component": "Text",
          "text": "This is a much longer, more detailed description."
        }
      ]
    ''',
  ],
);
