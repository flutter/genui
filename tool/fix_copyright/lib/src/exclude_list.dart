// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

bool isExcluded(String path) {
  return _excludedPaths.any((pattern) => pattern.hasMatch(path));
}

final _excludedPaths = <RegExp>[
  RegExp(r'/android/.*'),
  RegExp(r'/ios/.*'),
  RegExp(r'/macos/.*'),
  RegExp(r'/web/.*'),
  RegExp(r'/windows/.*'),
];
