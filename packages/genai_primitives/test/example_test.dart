// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../example/main.dart' as example;

void main() {
  test('runExample', () {
    final output = StringBuffer();
    example.main(output: (object) => output.writeln(object.toString()));

    // If the test fails update expected output, and check diff for this file.
    expect(output.toString(), _expectedOutput);
  });
}

const _expectedOutput = '''
--- GenAI Primitives Example ---

[Tool Definition]
{
  "name": "get_weather",
  "description": "Get the current weather for a location",
  "inputSchema": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "The city and state, e.g. San Francisco, CA"
      },
      "unit": {
        "type": "string",
        "description": "The unit of temperature",
        "enum": [
          "celsius",
          "fahrenheit"
        ]
      }
    },
    "required": [
      "location"
    ]
  }
}

[Initial Conversation]
system: You are a helpful weather assistant. Use the get_weather tool when needed.
user: What is the weather in London?

[Model Response with Tool Call]
Tool Call: get_weather({location: London, unit: celsius})

[Tool Result]
Result: {temperature: 15, condition: Cloudy}

[Final Model Response with Data]
Text: Here is a chart of the weather trend:
Attachment: weather_chart.png (image/png, 4 bytes)

[Full History JSON]
[
  {
    "parts": [
      {
        "type": "Text",
        "content": "You are a helpful weather assistant. Use the get_weather tool when needed."
      }
    ],
    "metadata": {},
    "role": "system"
  },
  {
    "parts": [
      {
        "type": "Text",
        "content": "What is the weather in London?"
      }
    ],
    "metadata": {},
    "role": "user"
  },
  {
    "parts": [
      {
        "type": "Text",
        "content": "Thinking: User wants weather for London..."
      },
      {
        "type": "Tool",
        "content": {
          "id": "call_123",
          "name": "get_weather",
          "arguments": {
            "location": "London",
            "unit": "celsius"
          }
        }
      }
    ],
    "metadata": {},
    "role": "model"
  },
  {
    "parts": [
      {
        "type": "Tool",
        "content": {
          "id": "call_123",
          "name": "get_weather",
          "result": {
            "temperature": 15,
            "condition": "Cloudy"
          }
        }
      }
    ],
    "metadata": {},
    "role": "user"
  },
  {
    "parts": [
      {
        "type": "Text",
        "content": "Here is a chart of the weather trend:"
      },
      {
        "type": "Data",
        "content": {
          "name": "weather_chart.png",
          "mimeType": "image/png",
          "bytes": "data:image/png;base64,iVBORw=="
        }
      }
    ],
    "metadata": {},
    "role": "model"
  }
]
''';
