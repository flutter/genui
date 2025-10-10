// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

typedef JsonMap = Map<String, Object?>;

T parseEnum<T>(String? value, List<T> values, T defaultValue) {
  if (value == null) return defaultValue;
  return values.firstWhere(
    (T e) => (e as Enum).name == value,
    orElse: () => defaultValue,
  );
}
