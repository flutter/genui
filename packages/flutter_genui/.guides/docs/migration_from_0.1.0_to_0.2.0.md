---
title: How migrate client code from v0.1.0 to v0.2.0
description: |
  Instructions for migrating a client that depended upon version 0.1.0 to
  version 0.2.0.
---

This document provides instructions for migrating between version 0.1.0 and version 0.2.0 of the flutter_genui library.

## 2.0.0 to 2.1.0

### Core Catalog Component Changes

The core widget catalog has been updated with new components, and some existing components have been removed or replaced.

#### Replacements

- **`ElevatedButton` -> `Button`**: The `ElevatedButton` component has been replaced by a more generic `Button` component. The schema remains similar, but you should update the component name in your UI definitions.

#### Removals

- **`CheckboxGroup` and `RadioGroup`**: These components have been removed.
  - For multi-selection, use the new `MultipleChoice` widget.
  - For single boolean selection, use the `CheckBox` widget.

#### Additions

The following new components have been added to the core catalog and are now available for use:

- `AudioPlayer`
- `Button`
- `Card`
- `CheckBox`
- `DateTimeInput`
- `Divider`
- `Heading`
- `List`
- `Modal`
- `MultipleChoice`
- `Row`
- `Slider`
- `Tabs`
- `Video`

### `actionName` -> `name`

The `actionName` property in action schemas has been renamed to `name`. You will need to update your code to use the new property name. This affects widgets that take an `action` parameter, such as `Button`.

**Before:**

```json
{
  "actionName": "my-action"
}
```

**After:**

```json
{
  "name": "my-action"
}
```

### `location` -> `url`

The `location` property in the `Image` widget has been renamed to `url`. You will need to update your code to use the new property name.

**Before:**

```json
{
  "location": "https://example.com/image.png"
}
```

**After:**

```json
{
  "url": "https://example.com/image.png"
}
```
