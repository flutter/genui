// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:genui_express_platform_interface/genui_express_platform_interface.dart';

@JS('window')
external JSObject get _window;

/// The web-specific implementation of the GenuiExpress plugin.
///
/// Connects directly to Chrome's Built-in AI (Prompt API / Gemini Nano)
/// using browser-native JS interop.
class GenuiExpressWeb extends GenuiExpressPlatform {
  /// Registers this class as the active instance of [GenuiExpressPlatform].
  static void registerWith(Registrar registrar) {
    GenuiExpressPlatform.instance = GenuiExpressWeb();
  }

  @override
  Future<bool> checkAvailability() async {
    // 1. Check modern WICG global LanguageModel standard (Chrome 140+)
    if (_window.has('LanguageModel')) {
      return true;
    }

    // 2. Fallback to legacy window.ai.languageModel (Chrome 127-139)
    if (_window.has('ai')) {
      final ai = _window['ai'] as JSObject?;
      if (ai == null || !ai.has('languageModel')) return false;
      final languageModel = ai['languageModel'] as JSObject?;
      if (languageModel == null) return false;

      try {
        final capabilitiesPromise =
            languageModel.callMethod('capabilities'.toJS) as JSPromise;
        final capabilities = await capabilitiesPromise.toDart as JSObject?;
        if (capabilities == null) return false;
        final available = capabilities['available'] as JSString?;
        return available?.toDart != 'no';
      } catch (_) {}
    }

    return false;
  }

  @override
  Stream<String> generateStream(String prompt, String? systemPrompt) async* {
    JSObject? session;

    if (systemPrompt != null) {
      // ignore: avoid_print
      print('[GenuiExpressWeb] Creating session with System Prompt sections:');
      final List<String> sections = systemPrompt.split(
        '-------------------------------------',
      );
      for (var i = 0; i < sections.length; i++) {
        final String cleanSection = sections[i].trim();
        if (cleanSection.isNotEmpty) {
          // ignore: avoid_print
          print(
            '[GenuiExpressWeb] System Prompt Section ${i + 1}:\n$cleanSection',
          );
        }
      }
    } else {
      // ignore: avoid_print
      print('[GenuiExpressWeb] Creating session without System Prompt');
    }

    if (_window.has('LanguageModel')) {
      final languageModel = _window['LanguageModel'] as JSObject;
      final options = JSObject();

      // Suppress browser warning by explicitly specifying English language
      options['expectedLanguage'] = 'en'.toJS;
      options['language'] = 'en'.toJS;

      if (systemPrompt != null) {
        // Provide multiple potential system instruction formats
        // for broad compatibility.
        options['systemPrompt'] = systemPrompt.toJS;
        final JSArray initialPrompts = JSArray();
        final sysPromptObj = JSObject();
        sysPromptObj['role'] = 'system'.toJS;
        sysPromptObj['content'] = systemPrompt.toJS;
        initialPrompts.callMethod('push'.toJS, [sysPromptObj].toJS);
        options['initialPrompts'] = initialPrompts;
      }

      final sessionPromise =
          languageModel.callMethod('create'.toJS, [options].toJS) as JSPromise;
      session = await sessionPromise.toDart as JSObject;
    }
    // 2. Fallback to legacy window.ai.languageModel (Chrome 127-139)
    else if (_window.has('ai')) {
      final ai = _window['ai'] as JSObject;
      final languageModel = ai['languageModel'] as JSObject;
      final options = JSObject();

      // Suppress browser warning by explicitly specifying English language
      options['expectedLanguage'] = 'en'.toJS;
      options['language'] = 'en'.toJS;

      if (systemPrompt != null) {
        options['systemPrompt'] = systemPrompt.toJS;
      }

      final sessionPromise =
          languageModel.callMethod('create'.toJS, [options].toJS) as JSPromise;
      session = await sessionPromise.toDart as JSObject;
    }

    if (session == null) {
      throw StateError('Chrome Built-in AI is not available on this browser.');
    }

    // ignore: avoid_print
    print('[GenuiExpressWeb] Session active. Prompting model with: "$prompt"');

    final bool isModern = _window.has('LanguageModel');
    final JSAny input;
    if (isModern) {
      final messageObj = JSObject();
      messageObj['role'] = 'user'.toJS;
      messageObj['content'] = prompt.toJS;
      input = messageObj;
    } else {
      input = prompt.toJS;
    }

    try {
      final stream =
          session.callMethod('promptStreaming'.toJS, [input].toJS) as JSObject;
      final reader = stream.callMethod('getReader'.toJS) as JSObject;

      // PromptStreaming in Chrome returns cumulative text inside each chunk.
      // Support both cumulative and delta stream formats seamlessly.
      var previousChunk = '';

      while (true) {
        final readPromise = reader.callMethod('read'.toJS) as JSPromise;
        final result = await readPromise.toDart as JSObject;
        final bool done = (result['done'] as JSBoolean).toDart;
        if (done) {
          break;
        }
        final String chunk = (result['value'] as JSString).toDart;
        final String delta = chunk.startsWith(previousChunk)
            ? chunk.substring(previousChunk.length)
            : chunk;

        previousChunk = chunk;

        if (delta.isNotEmpty) {
          yield delta;
        }
      }
    } finally {
      session.callMethod('destroy'.toJS);
    }
  }
}
