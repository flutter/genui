// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import 'chat_box.dart';

class GenUiWidgetInternal extends StatefulWidget {
  GenUiWidgetInternal(this.controller);

  final GenUiController controller;

  @override
  State<GenUiWidgetInternal> createState() => _GenUiWidgetInternalState();
}

class _GenUiWidgetInternalState extends State<GenUiWidgetInternal> {
  Input? _input;
  WidgetBuilder? _builder;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final state = widget.controller.state;

    final input = await state.input.future;
    setState(() => _input = input);
    final builder = await state.builder.future;
    setState(() => _builder = builder);
  }

  @override
  Widget build(BuildContext context) {
    if (_input == null) return _buildChatBox();

    final builder = _builder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChatInput(context),
        const SizedBox(height: 16.0),
        if (builder == null)
          const Center(child: CircularProgressIndicator())
        else
          builder(context),
      ],
    );
  }

  void _onInput(UserInput input) {
    widget.controller.state.input.complete(input);
  }

  Widget _buildChatBox() {
    return ChatBox(_onInput);
  }

  Widget _buildChatInput(BuildContext context) {
    return _input?.build(context) ?? const SizedBox.shrink();
  }
}
