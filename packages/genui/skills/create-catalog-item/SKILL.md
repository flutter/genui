---
name: create-catalog-item
description: Use this skill when the user asks to create a new CatalogItem, data class, and/or widget class based on a JSON Schema definition in an application that uses Flutter's `genui` package.
---

# Create CatalogItem

## Goal
To correctly implement a GenUI CatalogItem based on a provided json_schema_builder Schema, including its corresponding data class, CatalogItem instance, and Widget class. This ensures the AI model can properly generate and interact with the UI component.

## Instructions
When tasked with creating a CatalogItem from a `Schema`, follow these steps:

1. **Create the Data Class**:
   - Name it `_<SchemaName>Data` (e.g., if schema is `myCardSchema`, data class is `_MyCardData`).
   - Add final fields for each property defined in the schema.
   - Create a `factory _<SchemaName>Data.fromJson(Map<String, Object?> json)` method.
   - Use a `try-catch` block to parse the properties and return a new instance.
   - Cast each property from the `json` map to its expected type, e.g., `title: json['title'] as String,` or `action: json['action'] as JsonMap?,`.
   - Throw an `Exception('Invalid JSON for _<SchemaName>Data')` in the `catch` block if an error occurs.

2. **Create the CatalogItem Instance**:
   - Name it identical to the schema name but without the "Schema" suffix (e.g., `myCard` for `myCardSchema`).
   - Declare as a `final CatalogItem`.
   - Set `name` to the capitalized version of the name (e.g., `'MyCard'`).
   - Set `dataSchema` to the provided schema.
   - Implement the `widgetBuilder: (itemContext)`:
     - Cast `itemContext.data` to `Map<String, Object?>`.
     - Parse the data using the data class `fromJson` method: `_<SchemaName>Data.fromJson(json)`.
     - Return the corresponding Widget class and pass the required data.
     - If the schema includes an action callback (like `onCompleted`), implement it here. You must parse the action context using `resolveContext` and dispatch an event using `itemContext.dispatchEvent(...)`.

3. **Create the Widget Class**:
   - Name it `_<CapitalizedSchemaName>` (e.g., `_MyCard`).
   - Inherit from `StatelessWidget` or `StatefulWidget` depending on state requirements.
   - Add the Data Class as a required property (e.g., `final _<SchemaName>Data data;`).
   - Add any required callback properties (e.g., `final void Function(int) onCompleted;`).
   - Implement the `build` method using Flutter Material components (e.g., Card, Column, Text). Make sure each data field in the data class is displayed, and that actions are represented by buttons or other interactive elements.

## Examples
### Input Schema
```dart
final basicCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['BasicCard']),
    'title': S.string(),
    'description': 
    'action': A2uiSchemas.action(),
  },
  required: ['title'],
);
```

### Expected Output
```dart
class _BasicCardData {
  final String title;
  final JsonMap? action;

  _BasicCardData({required this.title, this.action});

  factory _BasicCardData.fromJson(Map<String, Object?> json) {
    try {
      return _BasicCardData(
        title: json['title'] as String,
        action: json['action'] as JsonMap?,
      );
    } catch (e) {
      throw Exception('Invalid JSON for _BasicCardData: $e');
    }
  }
}

final basicCard = CatalogItem(
  name: 'BasicCard',
  dataSchema: basicCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _BasicCardData.fromJson(json);

    return _BasicCard(
      data: data,
      onTap: () async {
        final action = data.action;
        if (action == null) return;
        final event = action['event'] as JsonMap?;
        final name = (event?['name'] as String?) ?? '';
        final JsonMap contextDefinition =
            (event?['context'] as JsonMap?) ?? <String, Object?>{};
        final JsonMap resolvedContext = await resolveContext(
          itemContext.dataContext,
          contextDefinition,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: name,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      }
    );
  },
);

class _BasicCard extends StatelessWidget {
  final _BasicCardData data;
  final VoidCallback onTap;

  const _BasicCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(data.title),
        onTap: onTap,
      ),
    );
  }
}
```

## Constraints
- Ensure proper use of `try-catch` blocks and type casting when parsing JSON in `fromJson`.
- Make sure action resolution accurately fetches variables via `resolveContext` and uses `itemContext.dispatchEvent` when actions are present in the Schema.
