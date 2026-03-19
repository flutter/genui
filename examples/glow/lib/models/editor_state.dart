// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

class EditorState {
  final int selectedStyleIndex;
  final double atmosphereValue;
  final bool isSheetOpen;
  final bool isRegenerating;
  final Uint8List? currentImage;

  const EditorState({
    this.selectedStyleIndex = 2,
    this.atmosphereValue = 0.5,
    this.isSheetOpen = false,
    this.isRegenerating = false,
    this.currentImage,
  });

  EditorState copyWith({
    int? selectedStyleIndex,
    double? atmosphereValue,
    bool? isSheetOpen,
    bool? isRegenerating,
    Uint8List? currentImage,
  }) {
    return EditorState(
      selectedStyleIndex: selectedStyleIndex ?? this.selectedStyleIndex,
      atmosphereValue: atmosphereValue ?? this.atmosphereValue,
      isSheetOpen: isSheetOpen ?? this.isSheetOpen,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      currentImage: currentImage ?? this.currentImage,
    );
  }
}
