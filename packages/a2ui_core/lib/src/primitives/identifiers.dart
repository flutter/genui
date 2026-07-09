// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Matches identifiers conforming to Unicode Standard Annex #31 (UAX #31)
/// default identifier rules (`XID_Start` followed by `XID_Continue*`).
///
/// The `ID_Start`/`ID_Continue` Unicode property escapes are the closest
/// equivalents to `XID_Start`/`XID_Continue` available in Dart regular
/// expressions; they differ only for a handful of exotic code points.
final RegExp _identifierPattern = RegExp(
  r'^\p{ID_Start}\p{ID_Continue}*$',
  unicode: true,
);

/// Whether [name] is a valid A2UI catalog entity identifier per UAX #31.
///
/// A2UI v1.0 requires component names, function names, and argument keys to
/// conform to UAX #31 identifier rules. The `@` prefix is reserved for core
/// system context evaluations (such as `@index`) and is not a valid catalog
/// entity name.
bool isValidA2uiIdentifier(String name) => _identifierPattern.hasMatch(name);
