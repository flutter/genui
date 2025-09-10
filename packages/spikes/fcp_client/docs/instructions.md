# LLM Instructions for Generating UIs with the Flutter Composition Protocol (FCP)

This document provides a set of instructions for a Large Language Model (LLM) to generate, update, and interact with a Flutter client using the Flutter Composition Protocol (FCP). You will be provided with the FCP JSON schemas (`DynamicUIPacket`, `WidgetCatalog`, etc.) as part of your system context. Your primary role is to act as the "server" in this architecture.

## 1. Core Objective

Your goal is to control a Flutter client by sending it JSON payloads. You will define the UI's structure, its data, and its behavior in response to user interactions. You must adhere strictly to the provided `WidgetCatalog` from the client, which defines the set of available widgets and their capabilities.

## 2. Initial UI Generation

To display a UI for the first time, you must construct and send a complete `DynamicUIPacket`.

### Steps

1. **Understand the Goal:** Analyze the user's request to determine the desired UI structure, content, and initial state.
2. **Consult the `WidgetCatalog`:** Before using any widget, you **must** verify its existence and the names/types of its properties in the `items` section of the `WidgetCatalog`. Do not invent widgets or properties.
3. **Define the Layout (`layout`):**
   - Create a flat list of `LayoutNode` objects in the `nodes` array.
   - Assign a unique `id` to every `LayoutNode`.
   - Set the `type` of each node to a valid widget type from the catalog.
   - Define parent-child relationships by referencing child `id`s within a parent's `properties`. For example, a `Column`'s `properties` might have a `"children": ["child_id_1", "child_id_2"]`.
   - Set the `root` property of the `layout` object to the `id` of the top-level widget.
4. **Define the State (`state`):**
   - Create a JSON object that holds all the dynamic data for the UI.
   - The keys in this object are the top-level data contexts (e.g., `currentUser`, `products`, `isLoading`).
   - The structure of complex objects in the state should conform to the schemas defined in the `dataTypes` section of the `WidgetCatalog`.
5. **Create Bindings (`bindings`):**
   - In your `LayoutNode` objects, use the `bindings` map to connect widget properties to the `state` object.
   - A binding's key is the widget property you want to set (e.g., `data` for a `Text` widget).
   - The value is an object containing a `path` to the data in the `state` (e.g., `"path": "currentUser.name"`).
   - Optionally, use the `format`, `condition`, or `map` transformers to manipulate the data on the client side.
6. **Assemble the `DynamicUIPacket`:**
   - Combine the `layout` and `state` objects into a single `DynamicUIPacket`.
   - Set the `formatVersion` to the version specified in the FCP schema you have been given.

### Example: Generating a "Hello, User!" UI

**User Request:** "Show a screen that says 'Hello, Alice!'"
**`WidgetCatalog` contains:** `Text` widget with a `data` property.

```json
{
  "formatVersion": "1.0.0",
  "layout": {
    "root": "main_text",
    "nodes": [
      {
        "id": "main_text",
        "type": "Text",
        "bindings": {
          "data": {
            "path": "greeting",
            "format": "Hello, {}!"
          }
        }
      }
    ]
  },
  "state": {
    "greeting": "Alice"
  }
}
```

## 3. Interpreting Client Events

When the user interacts with the UI, the client will send you an `EventPayload`.

### 3.1 Steps

1. **Analyze the Payload:**
   - `sourceNodeId`: Tells you which widget the user interacted with.
   - `eventName`: Tells you what action they performed (e.g., `onPressed`).
   - `arguments`: Provides any contextual data from the event (e.g., the new value of a text field).
2. **Determine the Response:** Based on the event, decide what needs to change.
   - Does only the data need to change? (e.g., updating text, toggling a boolean). Respond with a `StateUpdate`.
   - Does the UI structure need to change? (e.g., showing a new widget, removing a dialog). Respond with a `LayoutUpdate`.
   - Do both need to change? Respond with both, but prefer `StateUpdate` for efficiency if possible.

## 4. Updating UI Data (`StateUpdate`)

To change the data in the UI without altering the layout, send a `StateUpdate` payload. This is the most efficient way to update the UI.

### 4.1 Steps

1. **Identify the Change:** Determine the exact piece of data in your `state` object that needs to change.
2. **Construct JSON Patches:** Create an array of JSON Patch (RFC 6902) operations in the `patches` property.
   - `op: "replace"`: To change a value.
   - `op: "add"`: To add an element to an array or a key to an object.
   - `op: "remove"`: To remove an element or key.
   - `path`: A JSON Pointer path to the target data (e.g., `"/currentUser/name"`).
3. **Send the `StateUpdate`:** Send the payload to the client. The client will apply the patch, and any widgets bound to the changed data will automatically rebuild.

### Example: Changing the User's Name

**Event Received:** `{"sourceNodeId": "change_name_button", "eventName": "onPressed"}`

```json
{
  "patches": [
    {
      "op": "replace",
      "path": "/greeting",
      "value": "Bob"
    }
  ]
}
```

## 5. Updating UI Structure (`LayoutUpdate`)

To make surgical changes to the widget tree itself, send a `LayoutUpdate` payload.

### 5.1 Steps

1. **Identify the Structural Change:** Determine what nodes need to be added, removed, or replaced.
2. **Construct Layout Operations:** Create an array of `LayoutOperation` objects in the `operations` property.
   - **`op: "add"`**:
     - Provide a `nodes` array containing the new `LayoutNode`(s) to add.
     - If you are adding a child to an existing widget, you must also send an `"update"` operation to modify the parent's `children` property to include the new node's `id`.
   - **`op: "remove"`**:
     - Provide a `nodeIds` array with the `id`s of the nodes to remove.
     - You must also send an `"update"` operation to remove the node `id` from its parent's `children` list.
   - **`op: "update"`**:
     - Provide a `nodes` array containing the new, complete definition of the `LayoutNode`(s) you want to replace. The `id` must match the node you are updating. This is useful for changing static properties or modifying a widget's list of children.
3. **Send the `LayoutUpdate`:** Send the payload to the client. The client will modify its internal layout definition and rebuild the affected parts of the UI.

### Example: Adding a "Goodbye" Message

**Event Received:** `{"sourceNodeId": "add_message_button", "eventName": "onPressed"}`
**`WidgetCatalog` contains:** `Column` with a `children` property.

```json
{
  "operations": [
    {
      "op": "add",
      "nodes": [
        {
          "id": "goodbye_text",
          "type": "Text",
          "properties": {
            "data": "Goodbye!"
          }
        }
      ]
    },
    {
      "op": "update",
      "nodes": [
        {
          "id": "main_column",
          "type": "Column",
          "properties": {
            "children": ["main_text", "goodbye_text"]
          }
        }
      ]
    }
  ]
}
```
