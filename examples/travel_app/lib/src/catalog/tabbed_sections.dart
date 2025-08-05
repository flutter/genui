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
            description: 'The ID of the child widget for the tab content.',
          ),
        },
      ),
    ),
    'height': Schema.number(
      description:
          'The fixed height for the content area of the tabbed sections.',
    ),
  },
);

extension type _TabbedSectionsData.fromMap(Map<String, Object?> _json) {
  factory _TabbedSectionsData({
    required List<Map<String, Object?>> sections,
    double? height,
  }) => _TabbedSectionsData.fromMap({'sections': sections, 'height': height});

  Iterable<_TabSectionItemData> get sections => (_json['sections'] as List)
      .cast<Map<String, Object?>>()
      .map<_TabSectionItemData>(_TabSectionItemData.fromMap);
  double? get height => (_json['height'] as num?)?.toDouble();
}

extension type _TabSectionItemData.fromMap(Map<String, Object?> _json) {
  factory _TabSectionItemData({required String title, required String child}) =>
      _TabSectionItemData.fromMap({'title': title, 'child': child});

  String get title => _json['title'] as String;
  String get childId => _json['child'] as String;
}

final tabbedSections = CatalogItem(
  name: 'tabbedSections',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final tabbedSectionsData = _TabbedSectionsData.fromMap(
          data as Map<String, Object?>,
        );
        final sections = tabbedSectionsData.sections
            .map(
              (section) => _TabSectionData(
                title: section.title,
                childId: section.childId,
              ),
            )
            .toList();
        final height = tabbedSectionsData.height;

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
