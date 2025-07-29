import 'package:json_schema/json_schema.dart';

import '../models/models.dart';

/// A service to validate data objects against JSON schemas.
class DataTypeValidator {
  /// Validates the given [data] against the schema defined for the [dataType].
  ///
  /// Returns `true` if the data is valid, `false` otherwise.
  bool validate({
    required String dataType,
    required Map<String, Object?> data,
    required WidgetCatalog catalog,
  }) {
    final schemaMap = catalog.dataTypes[dataType] as Map<String, Object?>?;
    if (schemaMap == null) {
      // If the data type is not defined in the catalog, we consider it valid.
      // A stricter implementation might throw an error here.
      return true;
    }

    final schema = JsonSchema.create(schemaMap);
    final validationResult = schema.validate(data);

    return validationResult.isValid;
  }
}
