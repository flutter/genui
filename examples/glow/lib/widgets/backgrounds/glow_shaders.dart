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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Painter for an animated glowing orb using a fragment shader.
class OrbShaderPainter extends CustomPainter {
  final ui.FragmentProgram shaderProgram;
  final double time;

  OrbShaderPainter({required this.shaderProgram, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final shader = shaderProgram.fragmentShader();

    // Pass Uniforms matches the order in .frag file
    // 1. uSize (vec2) -> floats 0, 1
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // 2. uTime (float) -> float 2
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant OrbShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

/// Painter for a mesh gradient background using a fragment shader.
class MeshGradientPainter extends CustomPainter {
  final ui.FragmentProgram shaderProgram;
  final double time;
  final List<Color> colors;

  MeshGradientPainter({
    required this.shaderProgram,
    required this.time,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = shaderProgram.fragmentShader();

    // 1. uSize (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // 2. uTime (float)
    shader.setFloat(2, time);

    // 3. uColors (vec3 * 4)
    // Flatten colors to r, g, b floats
    int floatIndex = 3;
    for (final color in colors) {
      shader.setFloat(floatIndex++, color.r);
      shader.setFloat(floatIndex++, color.g);
      shader.setFloat(floatIndex++, color.b);
    }

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
