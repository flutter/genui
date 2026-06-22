// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veo_chat/agent/ai_client.dart';

import '../test_infra/test_data_dir.dart';

void main() {
  test('Gemini Veo API generates a video from a text prompt.', () async {
    final client = GeminiDartanticAiClient();
    addTearDown(client.dispose);

    // Read the story to visualize from script.txt in this test's data folder.
    final Directory outputDir = currentTestDataDir();
    final scriptFile = File('${outputDir.path}/script.txt');
    expect(
      scriptFile.existsSync(),
      isTrue,
      reason: 'script.txt with the story to visualize should exist at '
          '${scriptFile.path}.',
    );
    final String prompt = scriptFile.readAsStringSync().trim();
    expect(
      prompt,
      isNotEmpty,
      reason: 'script.txt should contain a story to visualize.',
    );
    print('Generating video from script:\n$prompt');

    final GeneratedVideo video = await client.generateVideo(
      prompt,
      aspectRatio: '16:9',
    );

    print('Generated video:');
    print('  uri: ${video.uri}');
    print('  mimeType: ${video.mimeType}');
    print('  bytes: ${video.bytes?.length ?? 0}');

    expect(
      video.isEmpty,
      isFalse,
      reason: 'Veo should return a non-empty video.',
    );
    expect(
      video.bytes,
      isNotNull,
      reason: 'The generated video bytes should be downloaded.',
    );
    expect(
      video.bytes!.length,
      greaterThan(1024),
      reason: 'A real video should be more than a kilobyte.',
    );

    // Save the generated video into this test's data folder, with a
    // timestamp suffix so repeated runs do not overwrite each other.
    final String timestamp = DateTime.now().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final outputFile = File('${outputDir.path}/generated_video_$timestamp.mp4');
    outputFile.writeAsBytesSync(video.bytes!);
    print('Saved generated video to ${outputFile.absolute.path}');

    expect(
      outputFile.existsSync(),
      isTrue,
      reason: 'The video file should be written to disk.',
    );
  }, timeout: const Timeout(Duration(minutes: 8)));
}
