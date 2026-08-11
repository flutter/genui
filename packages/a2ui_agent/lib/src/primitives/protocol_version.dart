// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An A2UI protocol specification version.
///
/// The agent SDK negotiates and validates against these versions. Note that
/// `package:a2ui_core` currently models the `v0.9` message envelopes only; the
/// other members exist so that catalog documents declaring another version can
/// be recognized and reported rather than silently mis-parsed.
enum ProtocolVersion {
  /// Protocol `v0.8`. Predates `catalogId`, so catalog documents at this
  /// version carry no identifier.
  v08('v0.8'),

  /// Protocol `v0.9`, the version modelled by `package:a2ui_core`.
  v09('v0.9'),

  /// Protocol `v0.9.1`.
  v091('v0.9.1'),

  /// Protocol `v1.0`. The first version where catalog documents declare their
  /// own `protocolVersion`.
  v10('v1.0');

  const ProtocolVersion(this.wireValue);

  /// The value used on the wire and in catalog documents, e.g. `v0.9`.
  final String wireValue;

  /// The version emitted by `package:a2ui_core` message envelopes.
  static const ProtocolVersion current = ProtocolVersion.v09;

  /// Parses [value] into a [ProtocolVersion].
  ///
  /// Accepts both the `v`-prefixed wire form (`v0.9`) and the bare numeric
  /// form (`0.9`). Returns `null` when [value] is not a known version.
  static ProtocolVersion? tryParse(String value) {
    final normalized = value.startsWith('v') ? value : 'v$value';
    for (final ProtocolVersion version in values) {
      if (version.wireValue == normalized) return version;
    }
    return null;
  }

  @override
  String toString() => wireValue;
}
