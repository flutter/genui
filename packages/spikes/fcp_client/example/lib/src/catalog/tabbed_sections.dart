// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TabbedSections extends StatelessWidget {
  const TabbedSections({super.key, required this.sections, this.height});

  final List<TabSectionData> sections;
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
                    children: sections.map((section) => section.child).toList(),
                  ),
                )
              : Expanded(
                  child: TabBarView(
                    children: sections.map((section) => section.child).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}

class TabSectionData {
  final String title;
  final Widget child;

  TabSectionData({required this.title, required this.child});
}
