// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/filter.dart';
import '../elements/text_intro.dart';
import '../shared/genui_widget.dart';

class Elicitation extends StatefulWidget {
  final ElicitationData data;
  final GenUiController controller;

  const Elicitation(this.data, this.controller, {super.key});

  @override
  State<Elicitation> createState() => _ElicitationState();
}

class _ElicitationState extends State<Elicitation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.controller.icon(width: 40, height: 40),
        const SizedBox(height: 8.0),
        TextIntro(widget.data.textIntroData),
        const SizedBox(height: 16.0),
        Filter(widget.data.filterData, _onInput),

        const SizedBox(height: 16.0),
        GenUiWidgetInternal(widget.controller),
      ],
    );
  }

  void _onInput(UserInput input) {
    widget.controller.state.input.complete(input);
  }
}

class ElicitationData extends WidgetData {
  final TextIntroData textIntroData;
  final FilterData filterData;

  ElicitationData({required this.filterData, required this.textIntroData});
}
