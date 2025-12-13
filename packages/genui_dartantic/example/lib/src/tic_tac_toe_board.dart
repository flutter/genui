// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TicTacToeBoard extends StatelessWidget {
  const TicTacToeBoard({required this.cells, this.onCellTap, super.key});

  /// A list of 9 strings representing the board state.
  /// Each string should be "X", "O", or "" (empty).
  final List<String> cells;

  /// Callback when a cell is tapped. Returns the index (0-8).
  final ValueChanged<int>? onCellTap;

  @override
  Widget build(BuildContext context) {
    if (cells.length != 9) {
      return Center(child: Text('Invalid board state: ${cells.length} cells'));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final value = cells[index];
          return InkWell(
            onTap: onCellTap != null && value.isEmpty
                ? () => onCellTap!(index)
                : null,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: value == 'X' ? Colors.blue : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
