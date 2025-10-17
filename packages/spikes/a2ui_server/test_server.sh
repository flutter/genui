#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script sends a POST request to the GenUI server's startSession endpoint.

# Use | jq for pretty-printing the JSON response (optional, requires jq to be installed).
curl -s -X POST "http://127.0.0.1:3400/startSession" \
-H "Content-Type: application/json" \
-d '{
  "data": {
    "protocolVersion": "0.1.0",
    "catalog": {
      "description": "Represents a *single* widget in a UI widget tree. This widget could be one of many supported types.",
      "properties": {
        "id": {
          "type": "string"
        },
        "widget": {
          "description": "A wrapper object for a single widget definition. It MUST contain exactly one key, where the key is the name of a widget type (e.g., \"Column\", \"Text\", \"ElevatedButton\") from the list of allowed properties. The value is an object containing the definition of that widget using its properties. For example: `{\"TypeOfWidget\": {\"widget_property\": \"Value of property\"}}`",
          "anyOf": [
            {
              "properties": {
                "ElevatedButton": {
                  "properties": {
                    "child": {
                      "description": "The ID of a child widget. This should always be set, e.g. to the ID of a `Text` widget.",
                      "type": "string"
                    }
                  },
                  "required": [
                    "child"
                  ],
                  "type": "object"
                }
              },
              "required": [
                "ElevatedButton"
              ],
              "type": "object"
            },
            {
              "properties": {
                "Column": {
                  "properties": {
                    "mainAxisAlignment": {
                      "description": "How children are aligned on the main axis. See Flutter'\''s MainAxisAlignment for values.",
                      "enum": [
                        "start",
                        "center",
                        "end",
                        "spaceBetween",
                        "spaceAround",
                        "spaceEvenly"
                      ],
                      "type": "string"
                    },
                    "crossAxisAlignment": {
                      "description": "How children are aligned on the cross axis. See Flutter'\''s CrossAxisAlignment for values.",
                      "enum": [
                        "start",
                        "center",
                        "end",
                        "stretch",
                        "baseline"
                      ],
                      "type": "string"
                    },
                    "children": {
                      "description": "A list of widget IDs for the children.",
                      "items": {
                        "type": "string"
                      },
                      "type": "array"
                    },
                    "spacing": {
                      "description": "The spacing between children. Defaults to 8.0.",
                      "type": "number"
                    }
                  },
                  "type": "object"
                }
              },
              "required": [
                "Column"
              ],
              "type": "object"
            },
            {
              "properties": {
                "Text": {
                  "properties": {
                    "text": {
                      "description": "The text to display. This does *not* support markdown.",
                      "type": "string"
                    }
                  },
                  "required": [
                    "text"
                  ],
                  "type": "object"
                }
              },
              "required": [
                "Text"
              ],
              "type": "object"
            },
            {
              "properties": {
                "CheckboxGroup": {
                  "properties": {
                    "values": {
                      "description": "The values of the checkboxes.",
                      "items": {
                        "type": "boolean"
                      },
                      "type": "array"
                    },
                    "labels": {
                      "description": "A list of labels for the checkboxes.",
                      "items": {
                        "type": "string"
                      },
                      "type": "array"
                    }
                  },
                  "required": [
                    "values",
                    "labels"
                  ],
                  "type": "object"
                }
              },
              "required": [
                "CheckboxGroup"
              ],
              "type": "object"
            },
            {
              "properties": {
                "RadioGroup": {
                  "properties": {
                    "groupValue": {
                      "description": "The currently selected value for a group of radio buttons.",
                      "type": "string"
                    },
                    "labels": {
                      "description": "A list of labels for the radio buttons.",
                      "items": {
                        "type": "string"
                      },
                      "type": "array"
                    }
                  },
                  "required": [
                    "groupValue",
                    "labels"
                  ],
                  "type": "object"
                }
              },
              "required": [
                "RadioGroup"
              ],
              "type": "object"
            },
            {
              "properties": {
                "TextField": {
                  "properties": {
                    "value": {
                      "description": "The initial value of the text field.",
                      "type": "string"
                    },
                    "hintText": {
                      "description": "Hint text for the text field.",
                      "type": "string"
                    },
                    "obscureText": {
                      "description": "Whether the text should be obscured.",
                      "type": "boolean"
                    }
                  },
                  "type": "object"
                }
              },
              "required": [
                "TextField"
              ],
              "type": "object"
            },
            {
              "properties": {
                "Image": {
                  "properties": {
                    "url": {
                      "description": "The URL of the image to display. Only one of url or assetName may be specified.",
                      "type": "string"
                    },
                    "assetName": {
                      "description": "The name of the asset to display. Only one of assetName or url may be specified.",
                      "type": "string"
                    },
                    "fit": {
                      "description": "How the image should be inscribed into the box.",
                      "enum": [
                        "fill",
                        "contain",
                        "cover",
                        "fitWidth",
                        "fitHeight",
                        "none",
                        "scaleDown"
                      ],
                      "type": "string"
                    }
                  },
                  "type": "object"
                }
              },
              "required": [
                "Image"
              ],
              "type": "object"
            }
          ]
        }
      },
      "required": [
        "id",
        "widget"
      ],
      "type": "object"
    }
  }
}' | jq
