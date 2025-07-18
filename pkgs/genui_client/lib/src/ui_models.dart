import 'dart:convert';

/// Extension to provide JSON stringification for map-based objects.
extension JsonEncodeMap on Map<String, Object?> {
  /// Converts this map object to a JSON string.
  ///
  /// - [indent]: If non-empty, the JSON output will be pretty-printed with
  ///   the given indent.
  String toJsonString({String indent = ''}) {
    if (indent.isNotEmpty) {
      return JsonEncoder.withIndent(indent).convert(this);
    }
    return const JsonEncoder().convert(this);
  }
}

extension type UiEvent.fromMap(Map<String, Object?> _json) {
  UiEvent({
    required String taskId,
    required String widgetId,
    required String eventType,
    required DateTime timestamp,
    Object? value,
  }) : _json = {
          'taskId': taskId,
          'widgetId': widgetId,
          'eventType': eventType,
          'timestamp': timestamp.toIso8601String(),
          if (value != null) 'value': value,
        };

  String? get taskId => _json['taskId'] as String?;
  String get widgetId => _json['widgetId'] as String;
  String get eventType => _json['eventType'] as String;
  Object? get value => _json['value'];
  DateTime get timestamp => DateTime.parse(_json['timestamp'] as String);

  Map<String, Object?> toMap() => _json;
}

extension type UiStateUpdate.fromMap(Map<String, Object?> _json) {
  String get widgetId => _json['widgetId'] as String;
  Map<String, Object?> get props => _json['props'] as Map<String, Object?>;
}

// --- Base Widget Definition Models ---

extension type UiDefinition.fromMap(Map<String, Object?> _json) {
  String get root => _json['root'] as String;
  Map<String, Map<String, Object?>> get widgets =>
      (_json['widgets'] as Map).cast<String, Map<String, Object?>>();
}

extension type WidgetDefinition.fromMap(Map<String, Object?> _json) {
  String get id => _json['id'] as String;
  String get type => _json['type'] as String;

  Map<String, Object?> get props =>
      _json['props'] as Map<String, Object?>? ?? {};
}

// --- Specific Widget Property Accessors ---

extension type UiText.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  String get data => _props['data'] as String? ?? '';
  double get fontSize => (_props['fontSize'] as num?)?.toDouble() ?? 14.0;
  String get fontWeight => _props['fontWeight'] as String? ?? 'normal';
}

extension type UiTextField.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;

  String get value => _props['value'] as String? ?? '';
  String? get hintText => _props['hintText'] as String?;
  bool get obscureText => _props['obscureText'] as bool? ?? false;
}

extension type UiCheckbox.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  bool get value => _props['value'] as bool? ?? false;
  String? get label => _props['label'] as String?;
}

extension type UiRadio.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  bool? get value => _props['value'] as bool?;
  bool? get groupValue => _props['groupValue'] as bool?;
  String? get label => _props['label'] as String?;
}

extension type UiSlider.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  double get value => (_props['value'] as num).toDouble();
  double get min => (_props['min'] as num?)?.toDouble() ?? 0.0;
  double get max => (_props['max'] as num?)?.toDouble() ?? 1.0;
  int? get divisions => _props['divisions'] as int?;
}

extension type UiAlign.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  String? get alignment => _props['alignment'] as String?;
  String? get child => _props['child'] as String?;
}

extension type UiContainer.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  String? get mainAxisAlignment => _props['mainAxisAlignment'] as String?;
  String? get crossAxisAlignment => _props['crossAxisAlignment'] as String?;
  List<String>? get children =>
      (_props['children'] as List<Object?>?)?.cast<String>();
}

extension type UiElevatedButton.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  String? get child => _props['child'] as String?;
}

extension type UiPadding.fromMap(Map<String, Object?> _json) {
  Map<String, Object?> get _props => _json['props'] as Map<String, Object?>;
  UiEdgeInsets get padding =>
      UiEdgeInsets.fromMap(_props['padding'] as Map<String, Object?>);
  String? get child => _props['child'] as String?;
}

extension type UiEdgeInsets.fromMap(Map<String, Object?> _json) {
  double get top => (_json['top'] as num?)?.toDouble() ?? 0.0;
  double get left => (_json['left'] as num?)?.toDouble() ?? 0.0;
  double get bottom => (_json['bottom'] as num?)?.toDouble() ?? 0.0;
  double get right => (_json['right'] as num?)?.toDouble() ?? 0.0;
}
