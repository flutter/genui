// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class JumpingDots extends StatefulWidget {
  const JumpingDots({
    super.key,
    this.numberOfDots = 3,
    this.color = Colors.black,
    this.radius = 2.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final int numberOfDots;
  final Color color;
  final double radius;
  final Duration animationDuration;

  @override
  State<JumpingDots> createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.numberOfDots,
      (index) =>
          AnimationController(vsync: this, duration: widget.animationDuration),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -6.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (final controller in _controllers) {
      // Stagger the animations
      if (!mounted) return;
      controller.forward().then((_) {
        if (mounted) {
          controller.reverse();
        }
      });
      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      ); // Stagger delay
    }
    await Future<void>.delayed(
      const Duration(milliseconds: 1000),
    ); // Delay between loops
    if (mounted) _startAnimations(); // Loop
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.end, // Align dots to bottom of text
      children: List.generate(_controllers.length, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: widget.color,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
