// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../core/logging.dart';
import '../../core/theme/theme.dart';
import '../ai/ai_provider.dart';
import '../state/loading_state.dart';

class UploadPhotoScreen extends ConsumerWidget {
  const UploadPhotoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Visualize Your Garden'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/upload_yard_photo_header.png',
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s Start Your Transformation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload a photo of your front or back yard, '
                'and our designers will use it to create a custom vision. '
                'Get ready to see the potential.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              InfoCard(
                icon: Icons.photo_library,
                title: 'Choose from Library',
                subtitle: 'Select an existing photo from your gallery.',
                onTap: () async {
                  appLogger.info(
                    'UploadPhotoScreen: Choose from Library button tapped',
                  );
                  LoadingState.instance.setMessages([
                    'Connecting to landscape design agent...',
                  ]);
                  await _pickAndSendImage(ref, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
              InfoCard(
                icon: Icons.photo_camera,
                title: 'Take a Photo',
                subtitle: 'Show us your space.',
                onTap: () async {
                  appLogger.info('UploadPhotoScreen: Take Photo button tapped');
                  LoadingState.instance.setMessages([
                    'Connecting to landscape design agent...',
                  ]);
                  await _pickAndSendImage(ref, ImageSource.camera);
                },
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.lightbulb),
                label: const Text('Tips for the best photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final String mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      ref.read(aiProvider).whenData((aiState) {
        aiState.conversation.sendRequest(
          UserMessage([
            const DataPart({
              'userAction': {
                'name': 'submit_details',
                'sourceComponentId': 'upload_button',
                'context': <String, Object?>{},
              },
            }),
            ImagePart.fromBytes(bytes, mimeType: mimeType),
          ]),
        );
      });
    }
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              CircleAvatar(
                maxRadius: 25,
                child: Icon(icon, size: 25, color: const Color(0xff15a34a)),
              ),
              if (title != null || subtitle != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      if (title case final title?)
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      if (subtitle case final subtitle?)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
