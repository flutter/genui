// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

class OptionsFilterChip extends StatefulWidget {
  const OptionsFilterChip({
    super.key,
    required this.initialChipLabel,
    required this.options,
  });

  final String initialChipLabel;
  final List<String> options;

  @override
  State<OptionsFilterChip> createState() => _OptionsFilterChipState();
}

class _OptionsFilterChipState extends State<OptionsFilterChip> {
  late String _currentChipLabel;

  @override
  void initState() {
    super.initState();
    _currentChipLabel = widget.initialChipLabel;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(_currentChipLabel),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            String? tempSelectedOption = _currentChipLabel;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      // ignore: deprecated_member_use
                      groupValue: tempSelectedOption,
                      // ignore: deprecated_member_use
                      onChanged: (String? newValue) {
                        setModalState(() {
                          tempSelectedOption = newValue;
                        });
                        if (newValue != null) {
                          setState(() {
                            _currentChipLabel = newValue;
                          });
                          FcpProvider.of(context)?.onEvent?.call(
                            EventPayload(
                              sourceNodeId: 'options_filter_chip',
                              eventName: 'optionSelected',
                              arguments: {'value': newValue},
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }
}
