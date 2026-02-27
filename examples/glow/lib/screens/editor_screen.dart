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
import 'package:glow/theme.dart';
import 'package:glow/view_models/editor_view_model.dart';
import 'package:glow/widgets/images/generating_shader_image.dart';
import 'package:glow/widgets/backgrounds/glow_orb.dart';
import 'package:glow/widgets/navigation/glass_top_bar.dart';
import 'package:glow/widgets/panels/glass_properties_panel.dart';
import 'package:genui/genui.dart';
import 'package:glow/genui/editor_catalog.dart';

class GlowEditorScreen extends StatefulWidget {
  const GlowEditorScreen({super.key});

  @override
  State<GlowEditorScreen> createState() => _GlowEditorScreenState();
}

class _GlowEditorScreenState extends State<GlowEditorScreen>
    with TickerProviderStateMixin {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  // ignore: unused_field
  late final EditorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Use the singleton instance
    _viewModel = EditorViewModel.instance;
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    _viewModel.setSheetOpen(_sheetController.size > 0.15);
  }

  void _toggleSheet() {
    if (_sheetController.size < 0.2) {
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
      );
    } else {
      _sheetController.animateTo(
        0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
      );
    }
  }

  void _closeSheet() {
    _sheetController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        // 1. BACKGROUND Layer
        Widget backgroundLayer = const _BackgroundLayer();

        // 2. THE GLASS PANEL CONTENT Helper
        Widget propertiesContent(
          ScrollController? scrollController,
          VoidCallback? onClose, {
          bool showDragHandle = true,
        }) {
          // If we have no controls surface yet, show loading
          if (_viewModel.controlsSurfaceId == null) {
            return GlassPropertiesPanel(
              scrollController: scrollController,
              onClose: onClose,
              showDragHandle: showDragHandle,
              // Fallback / Loading Mode
              selectedIndex: 0,
              atmosphere: 0,
              onStyleSelected: (_) {},
              onAtmosphereChanged: (_) {},
              onRegenerate: _viewModel.regenerateImage,
              isRegenerating: true, // Only show spinner
            );
          }

          // We wrap the surface in EditorControlScope to use the mechanisms we built for the editor
          // This allows us to use `EditorControl` widgets (sliders, toggles)
          // that call `handler.setValue` -> `EditorViewModel.setControlValue`.
          return EditorControlScope(
            handler: _EditorBinding(_viewModel),
            child: GlassPropertiesPanel(
              scrollController: scrollController,
              onClose: onClose,
              showDragHandle: showDragHandle,
              // We override the child of GlassPropertiesPanel to show GenUiSurface instead of static controls
              selectedIndex: 0,
              atmosphere: 0,
              onStyleSelected: (_) {},
              onAtmosphereChanged: (_) {},
              onRegenerate: _viewModel.regenerateImage,
              isRegenerating: state.isRegenerating,
              onSave: () {
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                _viewModel.saveImage('glow_wallpaper_$timestamp');
              },
              customContent: GenUiSurface(
                surfaceId: _viewModel.controlsSurfaceId!,
                host: _viewModel.genUiService!.conversation.host,
              ),
            ),
          );
        }
        // ...
        // (Middle of file unchanged, we use replace_file_content for chunks)

        return Scaffold(
          backgroundColor: GlowTheme.colors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              backgroundLayer,
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 800;

                  if (isTablet) {
                    return Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 500,
                                    maxHeight: 650,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 600 / 800,
                                    child: Container(
                                      margin: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: GlowTheme
                                                .colors
                                                .surfacePrimaryLow,
                                            blurRadius: 40,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: GeneratingShaderImage(
                                          imageUrl:
                                              "https://picsum.photos/seed/89/600/800",
                                          imageData: state.currentImage,
                                          isGenerating: state.isRegenerating,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: GlassTopBar(isTablet: true),
                              ),
                            ],
                          ),
                        ),
                        ClipRect(
                          child: Container(
                            width: 400,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: GlowTheme.colors.surfaceContainer,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 20,
                                    sigmaY: 20,
                                  ),
                                  child: Container(
                                    color: GlowTheme.colors.scrim,
                                  ),
                                ),
                                propertiesContent(
                                  null,
                                  null,
                                  showDragHandle: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Stack(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 500,
                              maxHeight: 650,
                            ),
                            child: AspectRatio(
                              aspectRatio: 600 / 800,
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GlowTheme.colors.surfacePrimaryLow,
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: GeneratingShaderImage(
                                    imageUrl:
                                        "https://picsum.photos/seed/89/600/800",
                                    imageData: state.currentImage,
                                    isGenerating: state.isRegenerating,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: GlassTopBar(
                            isTablet: false,
                            onMenuTap: _toggleSheet,
                            isMenuOpen: state.isSheetOpen,
                          ),
                        ),
                        DraggableScrollableSheet(
                          controller: _sheetController,
                          initialChildSize: 0.15,
                          minChildSize: 0.0,
                          maxChildSize: 0.9,
                          snap: true,
                          builder: (context, scrollController) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 25,
                                  sigmaY: 25,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: GlowTheme.colors.surfaceVariant,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(30),
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color: GlowTheme.colors.outlineMedium,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(
                                          dragDevices: {
                                            ui.PointerDeviceKind.touch,
                                            ui.PointerDeviceKind.mouse,
                                          },
                                        ),
                                    child: propertiesContent(
                                      scrollController,
                                      _closeSheet,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: GlowTheme.gradients.backgroundDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: GlowOrb(color: GlowTheme.colors.secondary, size: 400),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: GlowOrb(color: GlowTheme.colors.primary, size: 300),
          ),
        ],
      ),
    );
  }
}

class _EditorBinding implements EditorControlHandler {
  final EditorViewModel vm;
  _EditorBinding(this.vm);

  @override
  void setValue(String id, dynamic value) {
    vm.setControlValue(id, value);
  }

  @override
  dynamic getValue(String id) {
    return vm.getControlValue(id);
  }
}
