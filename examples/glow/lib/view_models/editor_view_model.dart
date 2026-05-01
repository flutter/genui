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

import 'dart:async';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:glow/models/editor_state.dart';
import 'package:glow/services/gemini_service.dart';
import 'package:glow/services/genui_service.dart';
import 'package:glow/view_models/settings_view_model.dart';
import 'package:glow/genui/editor_catalog.dart'; // Use Editor Catalog
import 'package:logging/logging.dart';
import 'package:genui/genui.dart';

class EditorViewModel extends ChangeNotifier {
  static final EditorViewModel instance = EditorViewModel._();
  final Logger _log = Logger('EditorViewModel');

  EditorViewModel._();

  EditorState _state = const EditorState();
  EditorState get state => _state;

  // GenUI for Dynamic Controls
  GenUiService? _genUiService;
  GenUiService? get genUiService => _genUiService;
  String? _controlsSurfaceId;
  String? get controlsSurfaceId => _controlsSurfaceId;

  // Track prompt context
  String? _basePrompt;

  final Map<String, dynamic> _controlValues = {};

  Future<void> initialize(String prompt) async {
    _basePrompt = prompt;
    _disposeGenUi();

    _log.info('Initializing Dynamic Editor with prompt: $prompt');

    // Do NOT auto-regenerate image here. The image is passed from GenerationScreen.

    final completer = Completer<void>();

    // Initialize GenUI for Controls
    final apiKey = SettingsViewModel.instance.apiKey;
    const systemInstruction = '''
    You are an expert UI designer for a Wallpaper Editor.
    Based on the user's wallpaper description, generate a set of PARAMETER CONTROLS using the 'EditorControl' tool.
    
    Example Controls:
    - If prompt is "Cyberpunk City", generate:
      - EditorControl(id="neon", label="Neon Intensity", type="slider", min=0, max=100, defaultValue=80)
      - EditorControl(id="rain", label="Rain Amount", type="slider", min=0, max=100)
    
    Action: Generate a surface with 3-5 relevant controls.
    IMPORTANT: vary the control types!
    - Use 'slider' for intensity/amount values.
    - Use 'toggle' for binary on/off features (e.g., "Neon Flicker", "HDR Mode").
    - Use 'dropdown' for selecting styles/variants (e.g., "Color Palette" -> ["Cyber", "Vapor", "Noir"]).
    ''';

    _genUiService = GenUiService(
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      additionalItems: editorCatalogItems, // Use Editor Catalog
      onSurfaceAdded: (surface) {
        _log.info('Controls Surface Added: ${surface.surfaceId}');
        _controlsSurfaceId = surface.surfaceId;
        if (!completer.isCompleted) completer.complete();
        notifyListeners();
      },
      onSurfaceUpdated: (update) {
        _log.info('Controls Surface Updated: ${update.surfaceId}');
      },
    );

    // Send initial request for controls
    _genUiService?.sendRequest(
      UserMessage.text("Generate controls for this wallpaper: $prompt"),
    );

    return completer.future;
  }

  void _disposeGenUi() {
    _genUiService?.dispose();
    _genUiService = null;
    _controlsSurfaceId = null;
    _controlValues.clear();
  }

  // Handle Updates from Dynamic Controls
  // This mimics QuizViewModel's apiSetAnswer but for controls
  void setControlValue(String id, dynamic value) {
    _controlValues[id] = value;
    notifyListeners();
  }

  dynamic getControlValue(String id) => _controlValues[id];

  void setImage(Uint8List? image) {
    if (image != null) {
      _state = _state.copyWith(currentImage: image, isRegenerating: false);
      notifyListeners();
    }
  }

  // Standard UI actions
  void setSheetOpen(bool isOpen) {
    if (_state.isSheetOpen != isOpen) {
      _state = _state.copyWith(isSheetOpen: isOpen);
      notifyListeners();
    }
  }

  Future<void> regenerateImage() async {
    if (_state.isRegenerating || _basePrompt == null) return;

    _state = _state.copyWith(isRegenerating: true);
    notifyListeners();

    try {
      final apiKey = SettingsViewModel.instance.apiKey;
      final service = GeminiService(apiKey: apiKey);

      // Construct prompt with dynamic control values
      final StringBuffer modifiedPrompt = StringBuffer(_basePrompt!);
      if (_controlValues.isNotEmpty) {
        modifiedPrompt.write(" Adjusted with: ");
        _controlValues.forEach((key, value) {
          modifiedPrompt.write("$key: $value, ");
        });
      }

      _log.info('Regenerating with prompt: ${modifiedPrompt.toString()}');
      final image = await service.generateImage(modifiedPrompt.toString());

      _state = _state.copyWith(isRegenerating: false, currentImage: image);

      // Trigger GenUI Update for Controls
      if (_genUiService != null) {
        final updateMessage =
            "I have updated the wallpaper based on the following adjustments: ${_controlValues.toString()}. Please update the available controls to be relevant to this new state. For example, if 'Rain' was increased, maybe offer 'Lightning' or 'Puddle Reflections' next. Maintain a diverse set of controls.";

        final parts = <MessagePart>[
          TextPart(updateMessage),
          if (_state.currentImage != null)
            DataPart({'mime_type': 'image/png', 'data': _state.currentImage!}),
        ];
        _genUiService!.sendRequest(UserMessage(parts));
      }
    } catch (e) {
      _log.severe("Regeneration Error: $e");
      _state = _state.copyWith(isRegenerating: false);
    }
    notifyListeners();
  }

  Future<void> saveImage(String filename) async {
    if (_state.currentImage == null) return;

    try {
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: _state.currentImage!,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      _log.info('Image saved successfully: $filename');
    } catch (e) {
      _log.severe('Error saving image: $e');
    }
  }

  @override
  void dispose() {
    _disposeGenUi();
    super.dispose();
  }
}
