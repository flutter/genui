---
title: Create a custom widget and add it to the agent's catalog
description: |
  Instructions for creating a custom widget and adding it to the agent's
  catalog.
---

Follow these steps to create your own, custom widgets and make them available
to the agent for generation.

## 1. Import `json_schema_builder`

Add the `json_schema_builder` package as a dependency in `pubspec.yaml`. Use the
same commit reference as the one for `genui`.

```yaml
dependencies:
  json_schema_builder: ^0.1.3
```

## 2. Create the new widget's schema

Each catalog item needs a schema that defines the data required to populate it.
Using the `json_schema_builder` package, define one for the new widget.

```dart
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

final _schema = S.object(
  properties: {
    'question': A2uiSchemas.stringReference(description: 'The question part of a riddle.'),
    'answer': A2uiSchemas.stringReference(description: 'The answer part of a riddle.'),
  },
  required: ['question', 'answer'],
);
```

## 3. Create a `CatalogItem`

Each `CatalogItem` represents a type of widget that the agent is allowed to
generate. To do that, combines a name, a schema, and a builder function that
produces the widgets that compose the generated UI.

The following example creates a `CatalogItem` that displays the question and
answer for a riddle.

```dart
final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required dataContext,
  }) {
    final json = data as Map<String, Object?>;

    final questionNotifier =
        dataContext.subscribeToString(json['question'] as Map<String, Object?>?);
    final answerNotifier =
        dataContext.subscribeToString(json['answer'] as Map<String, Object?>?);

    // 3. Use ValueListenableBuilder to build the UI reactively
    return ValueListenableBuilder<String?>(
      valueListenable: questionNotifier,
      builder: (context, question, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: answerNotifier,
          builder: (context, answer, _) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(border: Border.all()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question ?? '',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8.0),
                  Text(answer ?? '',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            );
          },
        );
      },
    );
  },
);
```

## 4. Add the `CatalogItem` to the catalog

Include your catalog items when instantiating `GenUiManager`.

```dart
final genUiManager = GenUiManager(
  catalog: CoreCatalogItems.asCatalog().copyWith([riddleCard]),
);
```

## 5. Update the system instruction to use the new widget

In order to make sure the agent knows to use your new widget, use the system
instruction to explicitly tell it how and when to do so. Provide the name from
the CatalogItem when you do.

The following example shows how to instruct an agent provided by Firebase AI
Login to generate a RiddleCard in response to user messages.

```dart
// In your ContentGenerator implementation (e.g., YourContentGenerator):
final contentGenerator = YourContentGenerator(
  systemInstruction: '''
      You are an expert in creating funny riddles. Every time I give you a word,
      you should generate a RiddleCard that displays one new riddle related to that word.
      Each riddle should have both a question and an answer.
      ''',
  // Pass any necessary tools to your ContentGenerator
);
```

## 6. Using the Data Model

Your custom widget can also participate in the reactive data model. This allows the AI to create UIs where the state is centralized and can be updated dynamically.

With the schema and widget builder defined as above, the AI can now generate a `RiddleCard` with either literal values:

```json
{
  "RiddleCard": {
    "question": { "literalString": "What has an eye, but cannot see?" },
    "answer": { "literalString": "A needle." }
  }
}
```

...or with paths that bind to the data model:

```json
{
  "RiddleCard": {
    "question": { "path": "/riddle/currentQuestion" },
    "answer": { "path": "/riddle/currentAnswer" }
  }
}
```

When a `path` is used, the `ValueListenableBuilder` in the widget will automatically listen for changes to that path in the `DataModel` and rebuild the widget whenever the data changes.
