// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genai_primitives/genai_primitives.dart';

import 'parts/image.dart';
import 'parts/ui.dart';
export 'parts/image.dart';
export 'parts/ui.dart';

final _genuiPartConverterRegistry = <String, JsonToPartConverter>{
  ImagePart.type: const PartConverter(ImagePart.fromJson),
  UiInteractionPart.type: const PartConverter(UiInteractionPart.fromJson),
  UiPart.type: const PartConverter(UiPart.fromJson),
  ...defaultPartConverterRegistry,
};

Parts genuiPartsFromJson(List<Object?> json) =>
    Parts.fromJson(json, converterRegistry: _genuiPartConverterRegistry);
