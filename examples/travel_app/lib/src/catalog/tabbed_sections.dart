import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'sections': Schema.array(
      description: 'A list of sections to display as tabs.',
      items: Schema.object(
        properties: {
          'title': Schema.string(description: 'The title of the tab.'),
          'child': Schema.string(
              description: 'The ID of the child widget for the tab content.'),
        },
      ),
    ),
    'height': Schema.number(
      description:
          'The fixed height for the content area of the tabbed sections.',
    ),
  },
);

final tabbedSections = CatalogItem(
  name: 'tabbedSections',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
  }) {
    final sections = (data['sections'] as List)
        .map((section) => _TabSectionData(
              title: section['title'] as String,
              childId: section['child'] as String,
            ))
        .toList();
    final height = (data['height'] as num?)?.toDouble();

    return _TabbedSections(
      sections: sections,
      buildChild: buildChild,
      height: height,
    );
  },
);

class _TabSectionData {
  final String title;
  final String childId;

  _TabSectionData({required this.title, required this.childId});
}

class _TabbedSections extends StatelessWidget {
  const _TabbedSections({
    required this.sections,
    required this.buildChild,
    this.height,
  });

  final List<_TabSectionData> sections;
  final Widget Function(String id) buildChild;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: sections.length,
      child: Column(
        children: [
          TabBar(
            tabs: sections.map((section) => Tab(text: section.title)).toList(),
          ),
          height != null
              ? SizedBox(
                  height: height,
                  child: TabBarView(
                    children: sections
                        .map((section) => buildChild(section.childId))
                        .toList(),
                  ),
                )
              : Expanded(
                  child: TabBarView(
                    children: sections
                        .map((section) => buildChild(section.childId))
                        .toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
