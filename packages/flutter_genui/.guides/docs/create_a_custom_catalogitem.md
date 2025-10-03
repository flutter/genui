---
title: Connecting to an agent provider
description: |
  Instructions for creating a custom widget and adding it to the agent's
  catalog.
---

Follow these steps to create your own, custom widgets and make them available
to the agent for generation.

## 1. Import `dart_schema_builder`

Add the `dart_schema_builder` package as a dependency in `pubspec.yaml`. Use the
same commit reference as the one for `flutter_genui`.

```yaml
dart_schema_builder:
  git:
    url: https://github.com/flutter/genui.git
    path: packages/dart_schema_builder
    ref: 6e472cf0f7416c31a1de6af9a0d1b4cc37188989
```

## 2. Create the new widget's schema

Each catalog item needs a schema that defines the data required to populate it.
Using the `dart_schema_builder` package, define one for the new widget.

```dart
import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'question': S.string(description: 'The question part of a riddle.'),
    'answer': S.string(description: 'The answer part of a riddle.'),
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
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final json = data as Map<String, Object?>;
        final question = json['question'] as String;
        final answer = json['answer'] as String;

        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(border: Border.all()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8.0),
              Text(answer, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        );
      },
);
```

## 4. Add the `CatalogItem` to the catalog

Include your catalog items when instantiating `GenUiManager`.

```dart
final genUiManager = GenUiManager(
  catalog: CoreCatalogItems.asCatalog().copyWith([riddleCard]),
```

## 5. Update the system instruction to use the new widget

In order to make sure the agent knows to use your new widget, use the system
instruction to explicitly tell it how and when to do so. Provide the name from
the CatalogItem when you do.

The following example shows how to instruct an agent provided by Firebase AI
Login to generate a RiddleCard in response to user messages.

```dart
final aiClient = FirebaseAiClient(
  systemInstruction: '''
      You are an expert in creating funny riddles. Every time I give you a word,
      you should generate a RiddleCard that displays one new riddle related to that word.
      Each riddle should have both a question and an answer.
      ''',
  tools: genUiManager.getTools(),
);
```
