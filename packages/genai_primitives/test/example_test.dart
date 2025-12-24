// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../example/main.dart' as example;

void main() {
  test('runExample', () {
    final List<String> output = [];
    void expectOutput(Object? object) {
      output.add(object.toString());
    }

    example.main(output: expectOutput);
  });
}
