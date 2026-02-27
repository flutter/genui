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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _apiKeyKey = 'gemini_api_key';

  static final SettingsViewModel instance = SettingsViewModel._();
  SettingsViewModel._() {
    loadSettings();
  }

  static const String _generationTimeKey = 'generation_time_ms';

  String? _apiKey;
  int _predictedGenerationTimeMs = 10000; // Default to 10 seconds
  bool _isLoaded = false;

  String? get apiKey => _apiKey;
  bool get isLoaded => _isLoaded;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  Duration get predictedGenerationDuration =>
      Duration(milliseconds: _predictedGenerationTimeMs);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);
    _predictedGenerationTimeMs = prefs.getInt(_generationTimeKey) ?? 10000;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
    _apiKey = key;
    notifyListeners();
  }

  Future<void> updateGenerationTime(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    // Simple moving average or direct update? User said "use that for the next".
    // Let's weighted average it to smooth out outliers: 70% old, 30% new
    final newTime =
        (0.7 * _predictedGenerationTimeMs + 0.3 * duration.inMilliseconds)
            .round();

    // Clamp to reasonable bounds (e.g. 8s to 30s)
    final clampedTime = newTime.clamp(8000, 30000);

    await prefs.setInt(_generationTimeKey, clampedTime);
    _predictedGenerationTimeMs = clampedTime;
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    _apiKey = null;
    notifyListeners();
  }
}
