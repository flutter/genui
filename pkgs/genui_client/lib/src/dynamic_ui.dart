import 'package:flutter/material.dart';
import 'ui_models.dart';

/// A widget that builds a UI dynamically from a JSON-like definition.
///
/// It takes an initial [definition] and reports user interactions
/// via the [onEvent] callback.
class DynamicUi extends StatefulWidget {
  const DynamicUi({
    super.key,
    required this.surfaceId,
    required this.definition,
    required this.onEvent,
  });

  /// The ID of the surface that this UI belongs to.
  final String surfaceId;

  /// The initial UI structure.
  final Map<String, Object?> definition;

  /// A callback for when a user interacts with a widget.
  final void Function(Map<String, Object?> event) onEvent;

  @override
  State<DynamicUi> createState() => _DynamicUiState();
}

class _DynamicUiState extends State<DynamicUi> {
  /// Stores the current props for every widget, keyed by widget ID.
  /// This allows for efficient state updates.
  late final Map<String, Map<String, Object?>> _widgetStates;
  final Map<String, TextEditingController> _textControllers = {};
  late final UiDefinition _uiDefinition;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  /// When the widget is replaced with a new one (e.g., due to a key change),
  /// we must re-initialize its state.
  @override
  void didUpdateWidget(covariant DynamicUi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.definition != oldWidget.definition) {
      _cleanupState();
      _initializeState();
    }
  }

  void _initializeState() {
    final definition = Map<String, Object?>.from(widget.definition);
    final widgets = definition['widgets'];

    // The schema defines `widgets` as a list of widget definitions, but this
    // class expects `widgets` to be a map from widget ID to widget definition,
    // so we convert the list to a map here.
    if (widgets is List) {
      definition['widgets'] = {
        for (final widgetDef in widgets)
          if (widgetDef is Map<String, Object?> && widgetDef['id'] is String)
            widgetDef['id'] as String: widgetDef,
      };
    }

    _uiDefinition = UiDefinition.fromMap(definition);
    _widgetStates = {};
    _populateInitialStates();
  }

  void _cleanupState() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _widgetStates.clear();
  }

  @override
  void dispose() {
    _cleanupState();
    super.dispose();
  }

  /// Traverses the initial UI definition to populate the
  /// [_widgetStates] map and create TextEditingControllers.
  void _populateInitialStates() {
    for (final widgetDefEntry in _uiDefinition.widgets.entries) {
      final widgetDef = WidgetDefinition.fromMap(widgetDefEntry.value);
      final id = widgetDef.id;
      // Make a mutable copy
      final props = Map<String, Object?>.from(widgetDef.props);

      _widgetStates[id] = props;

      if (widgetDef.type == 'TextField') {
        final textField = UiTextField.fromMap({'props': props});
        final controller = TextEditingController(text: textField.value);
        _textControllers[id] = controller;
      }
    }
  }

  /// Dispatches an event by calling the public [DynamicUi.onEvent] callback.
  void _dispatchEvent(String widgetId, String eventType, Object? value) {
    final event = UiEvent(
      surfaceId: widget.surfaceId,
      widgetId: widgetId,
      eventType: eventType,
      value: value,
      timestamp: DateTime.now().toUtc(),
    );
    widget.onEvent(event.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final rootId = _uiDefinition.root;
    if (_uiDefinition.widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildWidget(rootId);
  }

  /// The main recursive build function.
  /// It reads a widget definition and its current state from [_widgetStates]
  /// and constructs the corresponding Flutter widget.
  Widget _buildWidget(String widgetId) {
    final widgetDefMap = _uiDefinition.widgets[widgetId];
    if (widgetDefMap == null) {
      return Text('Unknown widget ID: $widgetId');
    }
    final widgetDef = WidgetDefinition.fromMap(widgetDefMap);
    final id = widgetDef.id;
    final type = widgetDef.type;

    // Always get the latest props from our state map.
    final props = _widgetStates[id] ?? widgetDef.props;

    switch (type) {
      case 'Text':
        final text = UiText.fromMap({'props': props});
        return Text(
          text.data,
          style: TextStyle(
            fontSize: text.fontSize,
            fontWeight:
                text.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          ),
        );
      case 'TextField':
        final textField = UiTextField.fromMap({'props': props});
        final controller = _textControllers[id]!;
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: textField.hintText),
            obscureText: textField.obscureText,
            onChanged: (value) => _dispatchEvent(id, 'onChanged', value),
            onSubmitted: (value) => _dispatchEvent(id, 'onSubmitted', value),
          ),
        );
      case 'Checkbox':
        final checkbox = UiCheckbox.fromMap({'props': props});
        if (checkbox.label != null) {
          return CheckboxListTile(
            title: Text(checkbox.label!),
            value: checkbox.value,
            onChanged: (value) => _dispatchEvent(id, 'onChanged', value),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }
        return Checkbox(
          value: checkbox.value,
          onChanged: (value) => _dispatchEvent(id, 'onChanged', value),
        );
      case 'Radio':
        final radio = UiRadio.fromMap({'props': props});
        void changedCallback(Object? newValue) {
          if (newValue == null) return;
          _dispatchEvent(id, 'onChanged', newValue);
        }

        if (radio.label != null) {
          return RadioListTile<Object?>(
            title: Text(radio.label!),
            value: radio.value,
            // ignore: deprecated_member_use
            groupValue: radio.groupValue,
            // ignore: deprecated_member_use
            onChanged: changedCallback,
          );
        }
        return Radio<Object?>(
          value: radio.value,
          // ignore: deprecated_member_use
          groupValue: radio.groupValue,
          // ignore: deprecated_member_use
          onChanged: changedCallback,
        );
      case 'Slider':
        final slider = UiSlider.fromMap({'props': props});
        return Slider(
          value: slider.value,
          min: slider.min,
          max: slider.max,
          divisions: slider.divisions,
          label: slider.value.round().toString(),
          onChanged: (value) => _dispatchEvent(id, 'onChanged', value),
        );
      case 'Align':
        final align = UiAlign.fromMap({'props': props});
        return Align(
          alignment: _parseAlignment(align.alignment),
          child: align.child != null ? _buildWidget(align.child!) : null,
        );
      case 'Column':
        final column = UiContainer.fromMap({'props': props});
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(column.mainAxisAlignment),
          crossAxisAlignment:
              _parseCrossAxisAlignment(column.crossAxisAlignment),
          children: (column.children ?? []).map(_buildWidget).toList(),
        );
      case 'Row':
        final row = UiContainer.fromMap({'props': props});
        return Row(
          mainAxisAlignment: _parseMainAxisAlignment(row.mainAxisAlignment),
          crossAxisAlignment: _parseCrossAxisAlignment(row.crossAxisAlignment),
          children: (row.children ?? []).map(_buildWidget).toList(),
        );
      case 'ElevatedButton':
        final button = UiElevatedButton.fromMap({'props': props});
        return ElevatedButton(
          onPressed: () => _dispatchEvent(id, 'onTap', null),
          child: button.child != null ? _buildWidget(button.child!) : null,
        );
      case 'Padding':
        final padding = UiPadding.fromMap({'props': props});
        return Padding(
          padding: _parseEdgeInsets(padding.padding),
          child: padding.child != null ? _buildWidget(padding.child!) : null,
        );
      default:
        return Text('Unknown widget type: $type');
    }
  }

  // --- Parsing Helper Functions ---

  /// Parses a [UiEdgeInsets] object into a Flutter [EdgeInsets] object.
  EdgeInsets _parseEdgeInsets(UiEdgeInsets edgeInsets) {
    return EdgeInsets.fromLTRB(
      edgeInsets.left,
      edgeInsets.top,
      edgeInsets.right,
      edgeInsets.bottom,
    );
  }

  /// Parses a string representation of an alignment into a Flutter
  /// [Alignment] object.
  Alignment _parseAlignment(String? alignment) {
    switch (alignment) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  /// Parses a string representation of a main axis alignment into a Flutter
  /// [MainAxisAlignment] object.
  MainAxisAlignment _parseMainAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  /// Parses a string representation of a cross axis alignment into a Flutter
  /// [CrossAxisAlignment] object.
  CrossAxisAlignment _parseCrossAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }
}
