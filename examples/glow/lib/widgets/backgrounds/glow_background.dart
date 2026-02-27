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
import 'package:glow/theme.dart';

/// A subtle wavy background with a gradient and animated-looking lines.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: GlowTheme.gradients.backgroundLight),
      child: CustomPaint(painter: WavyLinePainter()),
    );
  }
}

/// Custom painter for drawing subtle wavy lines on the background.
class WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Helper to draw a wave
    void drawWave(double offset, Color color) {
      paint.color = color;
      final path = Path();
      path.moveTo(0, size.height * 0.1 + offset);

      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.15 + offset + 50,
        size.width * 0.5,
        size.height * 0.1 + offset,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.05 + offset - 50,
        size.width,
        size.height * 0.1 + offset,
      );

      canvas.drawPath(path, paint);
    }

    // Top left subtle waves
    drawWave(0, GlowTheme.colors.waveTertiary);
    drawWave(20, GlowTheme.colors.wavePrimary);

    // Bottom left subtle waves
    final pathBottom = Path();
    paint.color = GlowTheme.colors.waveTertiaryWeak;
    pathBottom.moveTo(0, size.height * 0.85);
    pathBottom.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.95,
      size.width,
      size.height * 0.8,
    );
    canvas.drawPath(pathBottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
