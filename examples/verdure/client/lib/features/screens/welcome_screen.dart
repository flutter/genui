// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/welcome_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          const Icon(Icons.eco, color: Colors.white, size: 32),
                          Text(
                            'Verdure',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontFamily: 'SpaceGrotesk',
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        spacing: 16,
                        children: [
                          Text(
                            'Envision Your Dream Landscape',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bring your perfect outdoor space to life with '
                            'our suite of AI design agents.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              spacing: 16,
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/upload_photo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start New Project'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Explore Ideas'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('I\'m a returning user'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
