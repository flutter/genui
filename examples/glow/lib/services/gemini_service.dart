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
import 'package:glow/constants.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';

class GeminiService {
  late GenerativeService model;

  /// The default model to use for generating content.
  String defaultModel = GlowConstants.defaultModel;
  String defaultImageModel = GlowConstants.defaultImageModel;

  GeminiService({String? apiKey})
    : model = GenerativeService.fromApiKey(apiKey);

  Future<String> generateText(String prompt, {String? model}) async {
    model ??= defaultModel;
    final response = await this.model.generateContent(
      GenerateContentRequest(
        model: model,
        contents: [
          Content(parts: [Part(text: prompt)]),
        ],
      ),
    );
    return response.text ?? '';
  }

  Future<Uint8List> generateImage(String prompt, {String? model}) async {
    model ??= defaultImageModel;
    final response = await this.model.generateContent(
      GenerateContentRequest(
        model: model,
        contents: [
          Content(parts: [Part(text: prompt)]),
        ],
      ),
    );
    return response.image ?? Uint8List.fromList([]);
  }
}

extension on GenerateContentResponse {
  String? get text {
    for (final canidate in candidates) {
      if (canidate.content != null) {
        final parts = canidate.content!.parts;
        for (final part in parts) {
          if (part.text != null) {
            return part.text!;
          }
        }
      }
    }
    return null;
  }

  Uint8List? get image {
    for (final canidate in candidates) {
      if (canidate.content != null) {
        final parts = canidate.content!.parts;
        for (final part in parts) {
          if (part.inlineData != null) {
            return part.inlineData!.data;
          }
        }
      }
    }
    return null;
  }
}
