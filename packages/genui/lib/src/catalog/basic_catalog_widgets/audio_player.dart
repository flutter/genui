// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
// ignore: deprecated_member_use, see https://github.com/a2ui-project/a2ui/issues/3235
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';
import 'format_duration.dart';

final _schema = S.object(
  description: 'An audio player component that plays audio from a given URL.',
  properties: {
    'url': A2uiSchemas.stringReference(
      description: 'The URL of the audio to play.',
    ),
    'description': A2uiSchemas.stringReference(
      description: 'A description of the audio, such as a title or summary.',
    ),
  },
  required: ['url'],
);

/// A simple audio player.
///
/// ## Parameters:
///
/// - `url`: The URL of the audio to play.
/// - `description`: An optional description of the audio.
final audioPlayer = CatalogItem(
  name: 'AudioPlayer',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final Object? url = data['url'];
    final Object? description = data['description'];

    return BoundString(
      dataContext: itemContext.dataContext,
      value: url,
      builder: (context, urlValue) {
        return BoundString(
          dataContext: itemContext.dataContext,
          value: description,
          builder: (context, descriptionValue) {
            return _AudioPlayerWidget(
              url: urlValue,
              description: descriptionValue,
            );
          },
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "AudioPlayer",
          "url": "https://upload.wikimedia.org/wikipedia/commons/d/db/Minuet_in_G_%28Beethoven%29%2C_piano.ogg",
          "description": "Beethoven — Minuet in G (public domain)"
        }
      ]
    ''',
  ],
);

/// The padding inside the player's card.
const _contentPadding = EdgeInsets.all(12);

/// The space between the time labels and the volume controls.
const double _volumeGap = 12;

/// The size of the volume icon.
const double _volumeIconSize = 20;

/// The width of the inline volume slider.
const double _volumeSliderWidth = 100;

/// The narrowest the seek bar gets before the controls wrap.
const double _minSeekBarWidth = 96;

/// Matches one digit of a time label.
final _digit = RegExp(r'\d');

class _AudioPlayerWidget extends StatefulWidget {
  const _AudioPlayerWidget({required this.url, this.description});

  final String? url;
  final String? description;

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late final ap.AudioPlayer _player;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.5;

  /// The last measured time label, cached by [_measureTime] because the
  /// position changes many times a second during playback.
  TextPainter? _timePainter;

  @override
  void initState() {
    super.initState();
    _player = ap.AudioPlayer();
    _player.setVolume(_volume);

    void onStreamError(Object error, StackTrace stackTrace) {
      genUiLogger.warning('Audio player stream error', error, stackTrace);
    }

    _subscriptions = [
      _player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == ap.PlayerState.playing;
          });
        }
      }, onError: onStreamError),
      _player.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      }, onError: onStreamError),
      _player.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() => _duration = duration);
        }
      }, onError: onStreamError),
    ];

    _setSource();
  }

  @override
  void didUpdateWidget(_AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _player.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _setSource();
    }
  }

  void _setSource() {
    final String? url = widget.url;
    if (url != null && url.isNotEmpty) {
      _player.setSource(ap.UrlSource(url)).catchError((Object error) {
        genUiLogger.warning('Failed to set audio source: $url', error);
      });
    }
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    _timePainter?.dispose();
    super.dispose();
  }

  /// Whether all the controls fit on one row [maxWidth] wide.
  ///
  /// The row holds the play button, both times, a seek bar at least
  /// [_minSeekBarWidth] wide, and the volume controls. The times are measured
  /// with the ambient text scaler, so large text wraps the controls too.
  ///
  /// Both times are measured as the longer of the two, which is the duration
  /// once it is known, with every digit as `0`, so the layout doesn't change
  /// while the audio plays, even with proportional digits.
  bool _fitsOnOneRow(BuildContext context, double maxWidth, TextStyle style) {
    final Duration longest = _position > _duration ? _position : _duration;
    final String label = formatDuration(longest).replaceAll(_digit, '0');
    final double timeWidth = _measureTime(context, label, style);

    final double width =
        kMinInteractiveDimension +
        2 * timeWidth +
        _minSeekBarWidth +
        _volumeGap +
        _volumeIconSize +
        _volumeSliderWidth +
        _contentPadding.right;
    return width <= maxWidth;
  }

  /// The width of [label] in [style], laid out again only when the label,
  /// style, text direction or text scaler changes.
  double _measureTime(BuildContext context, String label, TextStyle style) {
    final span = TextSpan(text: label, style: style);
    final TextDirection direction = Directionality.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextPainter? cached = _timePainter;
    if (cached != null &&
        cached.text == span &&
        cached.textDirection == direction &&
        cached.textScaler == scaler) {
      return cached.width;
    }
    cached?.dispose();
    final painter = TextPainter(
      text: span,
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    _timePainter = painter;
    return painter.width;
  }

  Widget _buildPlayButton() {
    return IconButton(
      tooltip: _isPlaying ? 'Pause' : 'Play',
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: widget.url != null && widget.url!.isNotEmpty
          ? () {
              if (_isPlaying) {
                _player.pause();
              } else {
                _player.resume();
              }
            }
          : null,
    );
  }

  Widget _buildSeekBar() {
    return MergeSemantics(
      child: Semantics(
        label: 'Playback position',
        child: Slider(
          value: _duration.inMilliseconds > 0
              ? _position.inMilliseconds
                    .clamp(0, _duration.inMilliseconds)
                    .toDouble()
              : 0,
          max: _duration.inMilliseconds > 0
              ? _duration.inMilliseconds.toDouble()
              : 1,
          onChanged: (value) {
            _player.seek(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );
  }

  List<Widget> _buildVolumeControls(BuildContext context) {
    return [
      const SizedBox(width: _volumeGap),
      Icon(
        _volume == 0
            ? Icons.volume_off
            : _volume < 0.5
            ? Icons.volume_down
            : Icons.volume_up,
        size: _volumeIconSize,
      ),
      SizedBox(
        width: _volumeSliderWidth,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: SliderComponentShape.noOverlay,
            padding: EdgeInsets.zero,
          ),
          child: MergeSemantics(
            child: Semantics(
              label: 'Volume',
              child: Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() => _volume = value);
                  _player.setVolume(value);
                },
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: _contentPadding.right),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle timeStyle = DefaultTextStyle.of(
      context,
    ).style.merge(theme.textTheme.bodySmall);

    return Card(
      child: Padding(
        padding: _contentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.description != null && widget.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.description!,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final position = Text(
                  formatDuration(_position),
                  style: timeStyle,
                );
                final duration = Text(
                  formatDuration(_duration),
                  style: timeStyle,
                );
                if (_fitsOnOneRow(context, constraints.maxWidth, timeStyle)) {
                  return Row(
                    children: [
                      _buildPlayButton(),
                      position,
                      Expanded(child: _buildSeekBar()),
                      duration,
                      ..._buildVolumeControls(context),
                    ],
                  );
                }
                // Too narrow for one row: the times go under the seek bar,
                // and the volume is left to the device's own controls.
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildPlayButton(),
                        Expanded(child: _buildSeekBar()),
                      ],
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      children: [position, duration],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
