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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that displays an image with a custom shader effect overlay.
///
/// The shader effect (e.g., ripple and frost) is active when [isGenerating] is true.
/// It uses a smooth ramp-up/down animation for the effect intensity.
class GeneratingShaderImage extends StatefulWidget {
  /// The URL of the image to display.
  final String? imageUrl;

  /// The image data to display (takes precedence over imageUrl).
  final Uint8List? imageData;

  /// Whether the AI generation is in progress (enables the shader effect).
  final bool isGenerating;

  /// How the image should be inscribed into the box.
  final BoxFit fit;

  const GeneratingShaderImage({
    super.key,
    this.imageUrl,
    this.imageData,
    required this.isGenerating,
    this.fit = BoxFit.cover,
  });

  @override
  State<GeneratingShaderImage> createState() => _GeneratingShaderImageState();
}

class _GeneratingShaderImageState extends State<GeneratingShaderImage>
    with TickerProviderStateMixin {
  ui.FragmentProgram? _program;
  ui.Image? _image;

  // Controls the continuous ripple movement (phase)
  late final Ticker _ticker;
  double _time = 0.0;

  // Controls the fade in/out of the effect (intensity)
  late final AnimationController _intensityController;

  // Image Loading Helpers
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _loadImage(widget.imageUrl);

    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Smooth ramp up/down
    );

    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _time = elapsed.inMilliseconds / 1000.0;
        });
      }
    });

    if (widget.isGenerating) {
      _startEffect();
    }
  }

  @override
  void didUpdateWidget(covariant GeneratingShaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isGenerating != oldWidget.isGenerating) {
      if (widget.isGenerating) {
        _startEffect();
      } else {
        _stopEffect();
      }
    }

    if (widget.imageUrl != oldWidget.imageUrl ||
        widget.imageData != oldWidget.imageData) {
      _loadImage(widget.imageUrl);
    }
  }

  void _startEffect() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
    _intensityController.forward();
  }

  void _stopEffect() {
    _intensityController.reverse().then((_) {
      if (mounted && !widget.isGenerating) {
        _ticker.stop();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _intensityController.dispose();
    _stopImageStream();
    super.dispose();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/ripple_frost.frag',
      );
      setState(() => _program = program);
    } catch (e) {
      debugPrint("Shader Error: $e");
    }
  }

  void _loadImage(String? url) {
    ImageProvider provider;

    if (widget.imageData != null) {
      provider = MemoryImage(widget.imageData!);
    } else if (url != null) {
      provider = NetworkImage(url);
    } else {
      return;
    }

    _stopImageStream();

    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageStreamListener = ImageStreamListener((ImageInfo info, _) {
      if (mounted) {
        setState(() {
          _image = info.image;
        });
      }
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _stopImageStream() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RawImage(image: _image!, fit: widget.fit),
        if (_program != null)
          AnimatedBuilder(
            animation: _intensityController,
            builder: (context, child) {
              if (_intensityController.value == 0 && !widget.isGenerating) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: CustomPaint(
                  painter: _ShaderPainter(
                    shader: _program!.fragmentShader(),
                    image: _image!,
                    time: _time,
                    intensity: _intensityController.value,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final double time;
  final double intensity;

  _ShaderPainter({
    required this.shader,
    required this.image,
    required this.time,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, intensity);

    shader.setImageSampler(0, image);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.intensity != intensity;
  }
}
