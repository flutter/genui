# Gemini Schema Validation Logic

This document outlines the validation rules that should be implemented in the `validateSchema` function. The purpose of this validator is to check for constraints that are not easily expressed in the JSON schema itself, such as conditional requirements and reference integrity.

Each message corresponds to one of the four message schemas: `stream_header.json`, `component_update.json`, `data_model_update.json`, or `begin_rendering.json`.

## `ComponentUpdate` Message Rules

### 1. Component ID Integrity

*   **Uniqueness**: All component `id`s within the `components` array must be unique.
*   **Reference Validity**: Any property that references a component ID (e.g., `child`, `children`, `entryPointChild`, `contentChild`) must point to an ID that actually exists in the `components` array.

### 2. Component-Specific Property Rules

For each component in the `components` array, the following rules apply based on its `type`:

*   **General**:
    *   A component must have an `id` and a `type`.

*   **Value Components** (`Heading`, `Text`, `Image`, `Video`, `AudioPlayer`, `TextField`, `CheckBox`, `DateTimeInput`, `MultipleChoice`, `Slider`):
    *   **Required**: Must have a `value` property.

*   **Container Components** (`Row`, `Column`, `List`):
    *   **Required**: Must have a `children` property.
    *   The `children` object must contain *either* `explicitList` *or* `template`, but not both.

*   **Card**:
    *   **Required**: Must have a `child` property.

*   **Tabs**:
    *   **Required**: Must have a `tabItems` property, which must be an array.
    *   Each item in `tabItems` must have a `title` and a `child`.

*   **Modal**:
    *   **Required**: Must have both `entryPointChild` and `contentChild` properties.

*   **Button**:
    *   **Required**: Must have `label` and `action` properties.

*   **CheckBox**:
    *   **Required**: Must have `label` and `value` properties.

## `DataModelUpdate` Message Rules

*   **Path and Contents**: A `DataModelUpdate` message must have a `contents` property. The `path` property is optional.
*   If `path` is not present, the `contents` object will replace the entire data model.
*   If `path` is present, the `contents` will be set at that location in the data model.

## `BeginRendering` Message Rules

*   **Root Presence**: Must have a `root` property.
