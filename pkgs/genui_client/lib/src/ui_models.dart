import 'dart:convert';

/// Extension to provide JSON stringification for map-based objects.
extension JsonEncodeMap on Map<String, Object?> {
  /// Converts this map object to a JSON string.
  ///
  /// If an [indent] is provided, the output will be formatted with that indent.
  String toJsonString({String indent = ''}) {
    if (indent.isNotEmpty) {
      return JsonEncoder.withIndent(indent).convert(this);
    }
    return const JsonEncoder().convert(this);
  }
}

/// A data object that represents a user interaction event in the UI.
///
/// This is used to send information from the client to the AI about user
/// actions, such as tapping a button or entering text.
extension type UiEvent.fromMap(Map<String, Object?> _json) {
  /// Creates a [UiEvent] from a set of properties.
  UiEvent({
    required String widgetId,
    required String eventType,
    required DateTime timestamp,
    Object? value,
  }) : _json = {
          'widgetId': widgetId,
          'eventType': eventType,
          'timestamp': timestamp.toIso8601String(),
          if (value != null) 'value': value,
        };

  /// The ID of the widget that triggered the event.
  String get widgetId => _json['widgetId'] as String;

  /// The type of event that was triggered (e.g., 'onChanged', 'onTap').
  String get eventType => _json['eventType'] as String;

  /// The value associated with the event, if any (e.g., the text in a
  /// `TextField`, or the value of a `Checkbox`).
  Object? get value => _json['value'];

  /// The timestamp of when the event occurred.
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);

  /// Converts this event to a map, suitable for JSON serialization.
  Map<String, Object?> toMap() => _json;
}

/// A data object that represents a state update for a widget.
///
/// This is sent from the AI to the client to dynamically change the properties
/// of a widget that is already on screen.
extension type UiStateUpdate.fromMap(Map<String, Object?> _json) {
  /// The ID of the widget to update.
  String get widgetId => _json['widgetId'] as String;

  /// A map of the new properties to apply to the widget. These will be merged
  /// with the existing properties of the widget.
  Map<String, Object?> get props => _json['props'] as Map<String, Object?>;
}

// --- Base Widget Definition Models ---

/// A data object that represents the entire UI definition.
///
/// This is the root object that defines a complete UI to be rendered.
extension type UiDefinition.fromMap(Map<String, Object?> _json) {
  /// The ID of the root widget in the UI tree.
  String get root => _json['root'] as String;

  /// A map of all widget definitions in the UI, keyed by their ID.
  Map<String, Map<String, Object?>> get widgets =>
      (_json['widgets'] as Map).cast<String, Map<String, Object?>>();
}

/// A data object that represents a single widget definition.
///
/// This contains the basic information needed to render any widget, including
/// its ID, type, and properties.
extension type WidgetDefinition.fromMap(Map<String, Object?> _json) {
  /// The unique ID of the widget.
  String get id => _json['id'] as String;

  /// The type of the widget (e.g., 'Text', 'Column').
  String get type => _json['type'] as String;

  /// The map of properties for this widget, which are specific to the widget's
  /// [type].
  Map<String, Object?> get props =>
      _json['props'] as Map<String, Object?>? ?? {};
}

// --- Specific Widget Property Accessors ---

/// A data object for accessing the properties of a `Text` widget.
extension type UiText.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The string content of the text.
  String get data => _props['data'] as String? ?? '';

  /// The font size for the text.
  double get fontSize => (_props['fontSize'] as num?)?.toDouble() ?? 14.0;

  /// The font weight for the text (e.g., 'bold', 'normal').
  String get fontWeight => _props['fontWeight'] as String? ?? 'normal';
}

/// A data object for accessing the properties of a `TextField` widget.
extension type UiTextField.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The current text value of the text field.
  String get value => _props['value'] as String? ?? '';

  /// The hint text to display when the text field is empty.
  String? get hintText => _props['hintText'] as String?;

  /// Whether to obscure the text being entered (e.g., for a password).
  bool get obscureText => _props['obscureText'] as bool? ?? false;
}

/// A data object for accessing the properties of a `Checkbox` widget.
extension type UiCheckbox.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The current state of the checkbox (true if checked, false if unchecked).
  bool get value => _props['value'] as bool? ?? false;

  /// An optional label to display next to the checkbox.
  String? get label => _props['label'] as String?;
}

/// A data object for accessing the properties of a `Radio` widget.
extension type UiRadio.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The value that this radio button represents.
  Object? get value => _props['value'];

  /// The currently selected value for the group of radio buttons this button
  /// belongs to.
  Object? get groupValue => _props['groupValue'];

  /// An optional label to display next to the radio button.
  String? get label => _props['label'] as String?;
}

/// A data object for accessing the properties of a `Slider` widget.
extension type UiSlider.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The current value of the slider.
  double get value => (_props['value'] as num).toDouble();

  /// The minimum value of the slider.
  double get min => (_props['min'] as num?)?.toDouble() ?? 0.0;

  /// The maximum value of the slider.
  double get max => (_props['max'] as num?)?.toDouble() ?? 1.0;

  /// The number of discrete divisions on the slider.
  int? get divisions => _props['divisions'] as int?;
}

/// A data object for accessing the properties of an `Align` widget.
extension type UiAlign.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The alignment of the child widget within the `Align` widget.
  String? get alignment => _props['alignment'] as String?;

  /// The ID of the child widget to align.
  String? get child => _props['child'] as String?;
}

/// A data object for accessing the properties of a container widget like
/// `Column` or `Row`.
extension type UiContainer.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The alignment of the children along the main axis.
  String? get mainAxisAlignment => _props['mainAxisAlignment'] as String?;

  /// The alignment of the children along the cross axis.
  String? get crossAxisAlignment => _props['crossAxisAlignment'] as String?;

  /// The list of child widget IDs.
  List<String>? get children =>
      (_props['children'] as List<Object?>?)?.cast<String>();
}

/// A data object for accessing the properties of an `ElevatedButton` widget.
extension type UiElevatedButton.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The ID of the child widget to display inside the button.
  String? get child => _props['child'] as String?;
}

/// A data object for accessing the properties of a `Padding` widget.
extension type UiPadding.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  /// The padding to apply to the child widget.
  UiEdgeInsets get padding =>
      UiEdgeInsets.fromMap(_props['padding'] as Map<String, Object?>);

  /// The ID of the child widget to pad.
  String? get child => _props['child'] as String?;
}

/// A data object for representing edge insets (padding).
extension type UiEdgeInsets.fromMap(Map<String, Object?> _json) {
  /// The top padding value.
  double get top => (_json['top'] as num?)?.toDouble() ?? 0.0;

  /// The left padding value.
  double get left => (_json['left'] as num?)?.toDouble() ?? 0.0;

  /// The bottom padding value.
  double get bottom => (_json['bottom'] as num?)?.toDouble() ?? 0.0;

  /// The right padding value.
  double get right => (_json['right'] as num?)?.toDouble() ?? 0.0;
}
