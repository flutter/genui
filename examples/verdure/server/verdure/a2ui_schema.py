# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json

# This file serves as the single source of truth for the A2UI Schema.
# It is imported by agent.py (for validation) and prompt_builder.py (for prompting).
# The schema is dynamically built from the three constituent JSON schemas below.

_SERVER_TO_CLIENT_JSON = r"""
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://a2ui.org/specification/v0_9/server_to_client.json",
  "title": "A2UI Message Schema",
  "description": "Describes a JSON payload for an A2UI (Agent to UI) message, which is used to dynamically construct and update user interfaces.",
  "type": "object",
  "oneOf": [
    { "$ref": "#/$defs/CreateSurfaceMessage" },
    { "$ref": "#/$defs/UpdateComponentsMessage" },
    { "$ref": "#/$defs/UpdateDataModelMessage" },
    { "$ref": "#/$defs/DeleteSurfaceMessage" }
  ],
  "$defs": {
    "CreateSurfaceMessage": {
      "type": "object",
      "properties": {
        "version": {
          "const": "v0.9"
        },
        "createSurface": {
          "type": "object",
          "description": "Signals the client to create a new surface and begin rendering it. When this message is sent, the client will expect 'updateComponents' and/or 'updateDataModel' messages for the same surfaceId that define the component tree.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be rendered."
            },
            "catalogId": {
              "description": "A string that uniquely identifies this catalog. It is recommended to prefix this with an internet domain that you own, to avoid conflicts e.g. mycompany.com:somecatalog'.",
              "type": "string"
            },
            "theme": {
              "type": "object",
              "description": "Initial theme parameters for the surface (e.g., {'primaryColor': '#FF0000'}). These must validate against the 'theme' schema defined in the catalog.",
              "additionalProperties": true
            },
            "sendDataModel": {
              "type": "boolean",
              "description": "If true, the client will send the full data model of this surface in the metadata of every A2A message sent to the server that created the surface. Defaults to false."
            }
          },
          "required": ["surfaceId", "catalogId"],
          "additionalProperties": false
        }
      },
      "required": ["createSurface", "version"],
      "additionalProperties": false
    },
    "UpdateComponentsMessage": {
      "type": "object",
      "properties": {
        "version": {
          "const": "v0.9"
        },
        "updateComponents": {
          "type": "object",
          "description": "Updates a surface with a new set of components. This message can be sent multiple times to update the component tree of an existing surface. One of the components in one of the components lists MUST have an 'id' of 'root' to serve as the root of the component tree. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be updated."
            },

            "components": {
              "type": "array",
              "description": "A list containing all UI components for the surface.",
              "minItems": 1,
              "items": {
                "$ref": "catalog.json#/$defs/anyComponent"
              }
            }
          },
          "required": ["surfaceId", "components"],
          "additionalProperties": false
        }
      },
      "required": ["updateComponents", "version"],
      "additionalProperties": false
    },
    "UpdateDataModelMessage": {
      "type": "object",
      "properties": {
        "version": {
          "const": "v0.9"
        },
        "updateDataModel": {
          "type": "object",
          "description": "Updates the data model for an existing surface. This message can be sent multiple times to update the data model. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface this data model update applies to."
            },
            "path": {
              "type": "string",
              "description": "An optional path to a location within the data model (e.g., '/user/name'). If omitted, or set to '/', refers to the entire data model."
            },
            "value": {
              "description": "The data to be updated in the data model. If present, the value at 'path' is replaced (or created). If omitted, the key at 'path' is removed.",
              "additionalProperties": true
            }
          },
          "required": ["surfaceId"],
          "additionalProperties": false
        }
      },
      "required": ["updateDataModel", "version"],
      "additionalProperties": false
    },
    "DeleteSurfaceMessage": {
      "type": "object",
      "properties": {
        "version": {
          "const": "v0.9"
        },
        "deleteSurface": {
          "type": "object",
          "description": "Signals the client to delete the surface identified by 'surfaceId'. The createSurface message MUST have been previously sent with the 'catalogId' that is in this message.",
          "properties": {
            "surfaceId": {
              "type": "string",
              "description": "The unique identifier for the UI surface to be deleted."
            }
          },
          "required": ["surfaceId"],
          "additionalProperties": false
        }
      },
      "required": ["deleteSurface", "version"],
      "additionalProperties": false
    }
  }
}
"""

_COMMON_TYPES_JSON = r"""
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://a2ui.org/specification/v0_9/common_types.json",
  "title": "A2UI Common Types",
  "description": "Common type definitions used across A2UI schemas.",
  "$defs": {
    "ComponentId": {
      "type": "string",
      "description": "The unique identifier for a component, used for both definitions and references within the same surface."
    },
    "AccessibilityAttributes": {
      "type": "object",
      "description": "Attributes to enhance accessibility when using assistive technologies like screen readers.",
      "properties": {
        "label": {
          "$ref": "#/$defs/DynamicString",
          "description": "A short string, typically 1 to 3 words, used by assistive technologies to convey the purpose or intent of an element. For example, an input field might have an accessible label of 'User ID' or a button might be labeled 'Submit'."
        },
        "description": {
          "$ref": "#/$defs/DynamicString",
          "description": "Additional information provided by assistive technologies about an element such as instructions, format requirements, or result of an action. For example, a mute button might have a label of 'Mute' and a description of 'Silences notifications about this conversation'."
        }
      }
    },
    "ComponentCommon": {
      "type": "object",
      "properties": {
        "id": {
          "$ref": "#/$defs/ComponentId"
        },
        "accessibility": {
          "$ref": "#/$defs/AccessibilityAttributes"
        }
      },
      "required": ["id"]
    },
    "ChildList": {
      "oneOf": [
        {
          "type": "array",
          "items": {
            "$ref": "#/$defs/ComponentId"
          },
          "description": "A static list of child component IDs."
        },
        {
          "type": "object",
          "description": "A template for generating a dynamic list of children from a data model list. The `componentId` is the component to use as a template.",
          "properties": {
            "componentId": {
              "$ref": "#/$defs/ComponentId"
            },
            "path": {
              "type": "string",
              "description": "The path to the list of component property objects in the data model."
            }
          },
          "required": ["componentId", "path"],
          "additionalProperties": false
        }
      ]
    },
    "DataBinding": {
      "type": "object",
      "properties": {
        "path": {
          "type": "string",
          "description": "A JSON Pointer path to a value in the data model."
        }
      },
      "required": ["path"],
      "additionalProperties": false
    },
    "DynamicValue": {
      "description": "A value that can be a literal, a path, or a function call returning any type.",
      "oneOf": [
        {
          "type": "string"
        },
        {
          "type": "number"
        },
        {
          "type": "boolean"
        },
        {
          "$ref": "#/$defs/DataBinding"
        },
        {
          "$ref": "#/$defs/FunctionCall"
        }
      ]
    },
    "DynamicString": {
      "description": "Represents a string",
      "oneOf": [
        {
          "type": "string"
        },
        {
          "$ref": "#/$defs/DataBinding"
        },
        {
          "allOf": [
            {
              "$ref": "#/$defs/FunctionCall"
            },
            {
              "properties": {
                "returnType": {
                  "const": "string"
                }
              },
              "required": ["returnType"]
            }
          ]
        }
      ]
    },
    "DynamicNumber": {
      "description": "Represents a value that can be either a literal number, a path to a number in the data model, or a function call returning a number.",
      "oneOf": [
        {
          "type": "number"
        },
        {
          "$ref": "#/$defs/DataBinding"
        },
        {
          "allOf": [
            {
              "$ref": "#/$defs/FunctionCall"
            },
            {
              "properties": {
                "returnType": {
                  "const": "number"
                }
              },
              "required": ["returnType"]
            }
          ]
        }
      ]
    },
    "DynamicBoolean": {
      "description": "A boolean value that can be a literal, a path, or a logic expression (including function calls returning boolean).",
      "oneOf": [
        {
          "type": "boolean"
        },
        {
          "$ref": "#/$defs/DataBinding"
        },
        {
          "$ref": "#/$defs/LogicExpression"
        }
      ]
    },
    "DynamicStringList": {
      "description": "Represents a value that can be either a literal array of strings, a path to a string array in the data model, or a function call returning a string array.",
      "oneOf": [
        {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        {
          "$ref": "#/$defs/DataBinding"
        },
        {
          "allOf": [
            {
              "$ref": "#/$defs/FunctionCall"
            },
            {
              "properties": {
                "returnType": {
                  "const": "array"
                }
              },
              "required": ["returnType"]
            }
          ]
        }
      ]
    },
    "FunctionCall": {
      "type": "object",
      "description": "Invokes a named function on the client.",
      "properties": {
        "call": {
          "type": "string",
          "description": "The name of the function to call."
        },
        "args": {
          "type": "object",
          "description": "Arguments passed to the function.",
          "additionalProperties": {
            "anyOf": [
              {
                "$ref": "#/$defs/DynamicValue"
              },
              {
                "type": "object",
                "description": "A literal object argument (e.g. configuration)."
              }
            ]
          }
        },
        "returnType": {
          "type": "string",
          "description": "The expected return type of the function call.",
          "enum": [
            "string",
            "number",
            "boolean",
            "array",
            "object",
            "any",
            "void"
          ],
          "default": "boolean"
        }
      },
      "required": ["call"]
    },
    "LogicExpression": {
      "type": "object",
      "description": "A boolean expression used for conditional state (e.g. 'enabled').",
      "oneOf": [
        {
          "properties": {
            "and": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/LogicExpression"
              },
              "minItems": 1
            }
          },
          "required": ["and"]
        },
        {
          "properties": {
            "or": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/LogicExpression"
              },
              "minItems": 1
            }
          },
          "required": ["or"]
        },
        {
          "properties": {
            "not": {
              "$ref": "#/$defs/LogicExpression"
            }
          },
          "required": ["not"]
        },
        {
          "allOf": [
            {
              "$ref": "#/$defs/FunctionCall"
            },
            {
              "properties": {
                "returnType": {
                  "const": "boolean"
                }
              }
            }
          ]
        },
        {
          "properties": {
            "true": {
              "const": true
            }
          },
          "required": ["true"]
        },
        {
          "properties": {
            "false": {
              "const": false
            }
          },
          "required": ["false"]
        }
      ]
    },
    "CheckRule": {
      "type": "object",
      "description": "A single validation rule applied to an input component.",
      "unevaluatedProperties": false,
      "allOf": [
        {
          "$ref": "#/$defs/LogicExpression"
        },
        {
          "type": "object",
          "properties": {
            "message": {
              "type": "string",
              "description": "The error message to display if the check fails."
            }
          },
          "required": ["message"]
        }
      ]
    },
    "Checkable": {
      "description": "Properties for components that support client-side checks.",
      "type": "object",
      "properties": {
        "checks": {
          "type": "array",
          "description": "A list of checks to perform. These are function calls that must return a boolean indicating validity.",
          "items": {
            "$ref": "#/$defs/CheckRule"
          }
        }
      }
    },
    "Action": {
      "description": "Defines an interaction handler that can either trigger a server-side event or execute a local client-side function.",
      "oneOf": [
        {
          "type": "object",
          "description": "Triggers a server-side event.",
          "properties": {
            "event": {
              "type": "object",
              "description": "The event to dispatch to the server.",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "The name of the action to be dispatched to the server."
                },
                "context": {
                  "type": "object",
                  "description": "A JSON object containing the key-value pairs for the action context. Values can be literals or paths. Use literal values unless the value must be dynamically bound to the data model. Do NOT use paths for static IDs.",
                  "additionalProperties": {
                    "$ref": "#/$defs/DynamicValue"
                  }
                }
              },
              "required": ["name"],
              "additionalProperties": false
            }
          },
          "required": ["event"],
          "additionalProperties": false
        },
        {
          "type": "object",
          "description": "Executes a local client-side function.",
          "properties": {
            "functionCall": {
              "$ref": "#/$defs/FunctionCall"
            }
          },
          "required": ["functionCall"],
          "additionalProperties": false
        }
      ]
    }
  }
}
"""

_STANDARD_CATALOG_JSON = r"""
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://a2ui.org/specification/v0_9/standard_catalog.json",
  "title": "A2UI Standard Catalog",
  "description": "Unified catalog of standard A2UI components and functions.",
  "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json",
  "components": {
    "Text": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Text" },
            "text": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The text content to display. While simple Markdown formatting is supported (i.e. without HTML, images, or links), utilizing dedicated UI components is generally preferred for a richer and more structured presentation."
            },
            "variant": {
              "type": "string",
              "description": "A hint for the base text style.",
              "enum": ["h1", "h2", "h3", "h4", "h5", "caption", "body"]
            }
          },
          "required": ["component", "text"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Image": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Image" },
            "url": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The URL of the image to display."
            },
            "fit": {
              "type": "string",
              "description": "Specifies how the image should be resized to fit its container. This corresponds to the CSS 'object-fit' property.",
              "enum": ["contain", "cover", "fill", "none", "scale-down"]
            },
            "variant": {
              "type": "string",
              "description": "A hint for the image size and style.",
              "enum": [
                "icon",
                "avatar",
                "smallFeature",
                "mediumFeature",
                "largeFeature",
                "header"
              ]
            }
          },
          "required": ["component", "url"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Icon": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Icon" },
            "name": {
              "description": "The name of the icon to display.",
              "oneOf": [
                {
                  "type": "string",
                  "enum": [
                    "accountCircle",
                    "add",
                    "arrowBack",
                    "arrowForward",
                    "attachFile",
                    "calendarToday",
                    "call",
                    "camera",
                    "check",
                    "close",
                    "delete",
                    "download",
                    "edit",
                    "event",
                    "error",
                    "fastForward",
                    "favorite",
                    "favoriteOff",
                    "folder",
                    "help",
                    "home",
                    "info",
                    "locationOn",
                    "lock",
                    "lockOpen",
                    "mail",
                    "menu",
                    "moreVert",
                    "moreHoriz",
                    "notificationsOff",
                    "notifications",
                    "pause",
                    "payment",
                    "person",
                    "phone",
                    "photo",
                    "play",
                    "print",
                    "refresh",
                    "rewind",
                    "search",
                    "send",
                    "settings",
                    "share",
                    "shoppingCart",
                    "skipNext",
                    "skipPrevious",
                    "star",
                    "starHalf",
                    "starOff",
                    "stop",
                    "upload",
                    "visibility",
                    "visibilityOff",
                    "volumeDown",
                    "volumeMute",
                    "volumeOff",
                    "volumeUp",
                    "warning"
                  ]
                },
                {
                  "type": "object",
                  "properties": {
                    "path": { "type": "string" }
                  },
                  "required": ["path"],
                  "additionalProperties": false
                }
              ]
            }
          },
          "required": ["component", "name"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Video": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Video" },
            "url": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The URL of the video to display."
            }
          },
          "required": ["component", "url"]
        }
      ],
      "unevaluatedProperties": false
    },
    "AudioPlayer": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "AudioPlayer" },
            "url": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The URL of the audio to be played."
            },
            "description": {
              "description": "A description of the audio, such as a title or summary.",
              "$ref": "common_types.json#/$defs/DynamicString"
            }
          },
          "required": ["component", "url"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Row": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "description": "A layout component that arranges its children horizontally. To create a grid layout, nest Columns within this Row.",
          "properties": {
            "component": { "const": "Row" },
            "children": {
              "description": "Defines the children. Use an array of strings for a fixed set of children, or a template object to generate children from a data list. Children cannot be defined inline, they must be referred to by ID.",
              "$ref": "common_types.json#/$defs/ChildList"
            },
            "justify": {
              "type": "string",
              "description": "Defines the arrangement of children along the main axis (horizontally). Use 'spaceBetween' to push items to the edges, or 'start'/'end'/'center' to pack them together.",
              "enum": [
                "center",
                "end",
                "spaceAround",
                "spaceBetween",
                "spaceEvenly",
                "start",
                "stretch"
              ]
            },
            "align": {
              "type": "string",
              "description": "Defines the alignment of children along the cross axis (vertically). This is similar to the CSS 'align-items' property, but uses camelCase values (e.g., 'start').",
              "enum": ["start", "center", "end", "stretch"]
            }
          },
          "required": ["component", "children"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Column": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "description": "A layout component that arranges its children vertically. To create a grid layout, nest Rows within this Column.",
          "properties": {
            "component": { "const": "Column" },
            "children": {
              "description": "Defines the children. Use an array of strings for a fixed set of children, or a template object to generate children from a data list. Children cannot be defined inline, they must be referred to by ID.",
              "$ref": "common_types.json#/$defs/ChildList"
            },
            "justify": {
              "type": "string",
              "description": "Defines the arrangement of children along the main axis (vertically). Use 'spaceBetween' to push items to the edges (e.g. header at top, footer at bottom), or 'start'/'end'/'center' to pack them together.",
              "enum": [
                "start",
                "center",
                "end",
                "spaceBetween",
                "spaceAround",
                "spaceEvenly",
                "stretch"
              ]
            },
            "align": {
              "type": "string",
              "description": "Defines the alignment of children along the cross axis (horizontally). This is similar to the CSS 'align-items' property.",
              "enum": ["center", "end", "start", "stretch"]
            }
          },
          "required": ["component", "children"]
        }
      ],
      "unevaluatedProperties": false
    },
    "List": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "List" },
            "children": {
              "description": "Defines the children. Use an array of strings for a fixed set of children, or a template object to generate children from a data list.",
              "$ref": "common_types.json#/$defs/ChildList"
            },
            "direction": {
              "type": "string",
              "description": "The direction in which the list items are laid out.",
              "enum": ["vertical", "horizontal"]
            },
            "align": {
              "type": "string",
              "description": "Defines the alignment of children along the cross axis.",
              "enum": ["start", "center", "end", "stretch"]
            }
          },
          "required": ["component", "children"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Card": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Card" },
            "child": {
              "$ref": "common_types.json#/$defs/ComponentId",
              "description": "The ID of the single child component to be rendered inside the card. To display multiple elements, you MUST wrap them in a layout component (like Column or Row) and pass that container's ID here. Do NOT pass multiple IDs or a non-existent ID. Do NOT define the child component inline."
            }
          },
          "required": ["component", "child"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Tabs": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Tabs" },
            "tabs": {
              "type": "array",
              "description": "An array of objects, where each object defines a tab with a title and a child component.",
              "items": {
                "type": "object",
                "properties": {
                  "title": {
                    "description": "The tab title.",
                    "$ref": "common_types.json#/$defs/DynamicString"
                  },
                  "child": {
                    "$ref": "common_types.json#/$defs/ComponentId",
                    "description": "The ID of the child component. Do NOT define the component inline."
                  }
                },
                "required": ["title", "child"],
                "additionalProperties": false
              }
            }
          },
          "required": ["component", "tabs"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Modal": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Modal" },
            "trigger": {
              "$ref": "common_types.json#/$defs/ComponentId",
              "description": "The ID of the component that opens the modal when interacted with (e.g., a button). Do NOT define the component inline."
            },
            "content": {
              "$ref": "common_types.json#/$defs/ComponentId",
              "description": "The ID of the component to be displayed inside the modal. Do NOT define the component inline."
            }
          },
          "required": ["component", "trigger", "content"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Divider": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Divider" },
            "axis": {
              "type": "string",
              "description": "The orientation of the divider.",
              "enum": ["horizontal", "vertical"],
              "default": "horizontal"
            }
          },
          "required": ["component"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Button": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Button" },
            "child": {
              "$ref": "common_types.json#/$defs/ComponentId",
              "description": "The ID of the child component. Use a 'Text' component for a labeled button. Only use an 'Icon' if the requirements explicitly ask for an icon-only button. Do NOT define the child component inline."
            },
            "variant": {
              "type": "string",
              "description": "A hint for the button style. If omitted, a default button style is used. 'primary' indicates this is the main call-to-action button. 'borderless' means the button has no visual border or background, making its child content appear like a clickable link.",
              "enum": ["primary", "borderless"]
            },
            "action": {
              "$ref": "common_types.json#/$defs/Action"
            }
          },
          "required": ["component", "child", "action"]
        }
      ],
      "unevaluatedProperties": false
    },
    "TextField": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "TextField" },
            "label": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The text label for the input field."
            },
            "value": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The value of the text field."
            },
            "variant": {
              "type": "string",
              "description": "The type of input field to display.",
              "enum": ["longText", "number", "shortText", "obscured"]
            }
          },
          "required": ["component", "label"]
        }
      ],
      "unevaluatedProperties": false
    },
    "CheckBox": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "CheckBox" },
            "label": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The text to display next to the checkbox."
            },
            "value": {
              "$ref": "common_types.json#/$defs/DynamicBoolean",
              "description": "The current state of the checkbox (true for checked, false for unchecked)."
            }
          },
          "required": ["component", "label", "value"]
        }
      ],
      "unevaluatedProperties": false
    },
    "ChoicePicker": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "description": "A component that allows selecting one or more options from a list.",
          "properties": {
            "component": { "const": "ChoicePicker" },
            "label": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The label for the group of options."
            },
            "variant": {
              "type": "string",
              "description": "A hint for how the choice picker should be displayed and behave.",
              "enum": ["multipleSelection", "mutuallyExclusive"]
            },
            "options": {
              "type": "array",
              "description": "The list of available options to choose from.",
              "items": {
                "type": "object",
                "properties": {
                  "label": {
                    "description": "The text to display for this option.",
                    "$ref": "common_types.json#/$defs/DynamicString"
                  },
                  "value": {
                    "type": "string",
                    "description": "The stable value associated with this option."
                  }
                },
                "required": ["label", "value"],
                "additionalProperties": false
              }
            },
            "value": {
              "$ref": "common_types.json#/$defs/DynamicStringList",
              "description": "The list of currently selected values. This should be bound to a string array in the data model."
            }
          },
          "required": ["component", "options", "value"]
        }
      ],
      "unevaluatedProperties": false
    },
    "Slider": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "Slider" },
            "label": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The label for the slider."
            },
            "min": {
              "type": "number",
              "description": "The minimum value of the slider."
            },
            "max": {
              "type": "number",
              "description": "The maximum value of the slider."
            },
            "value": {
              "$ref": "common_types.json#/$defs/DynamicNumber",
              "description": "The current value of the slider."
            }
          },
          "required": ["component", "value", "min", "max"]
        }
      ],
      "unevaluatedProperties": false
    },
    "DateTimeInput": {
      "type": "object",
      "allOf": [
        { "$ref": "common_types.json#/$defs/ComponentCommon" },
        { "$ref": "#/$defs/CatalogComponentCommon" },
        { "$ref": "common_types.json#/$defs/Checkable" },
        {
          "type": "object",
          "properties": {
            "component": { "const": "DateTimeInput" },
            "value": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The selected date and/or time value in ISO 8601 format. If not yet set, initialize with an empty string."
            },
            "enableDate": {
              "type": "boolean",
              "description": "If true, allows the user to select a date."
            },
            "enableTime": {
              "type": "boolean",
              "description": "If true, allows the user to select a time."
            },
            "min": {
              "allOf": [
                {
                  "$ref": "common_types.json#/$defs/DynamicString"
                },
                {
                  "if": {
                    "type": "string"
                  },
                  "then": {
                    "oneOf": [
                      {
                        "format": "date"
                      },
                      {
                        "format": "time"
                      },
                      {
                        "format": "date-time"
                      }
                    ]
                  }
                }
              ],
              "description": "The minimum allowed date/time in ISO 8601 format."
            },
            "max": {
              "allOf": [
                {
                  "$ref": "common_types.json#/$defs/DynamicString"
                },
                {
                  "if": {
                    "type": "string"
                  },
                  "then": {
                    "oneOf": [
                      {
                        "format": "date"
                      },
                      {
                        "format": "time"
                      },
                      {
                        "format": "date-time"
                      }
                    ]
                  }
                }
              ],
              "description": "The maximum allowed date/time in ISO 8601 format."
            },
            "label": {
              "$ref": "common_types.json#/$defs/DynamicString",
              "description": "The text label for the input field."
            }
          },
          "required": ["component", "value"]
        }
      ],
      "unevaluatedProperties": false
    }
  },
  "functions": [
    {
      "name": "required",
      "description": "Checks that the value is not null, undefined, or empty.",
      "returnType": "boolean",
      "parameters": {
        "type": "object",
        "properties": {
          "value": {
            "description": "The value to check."
          }
        },
        "required": ["value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "regex",
      "description": "Checks that the value matches a regular expression string.",
      "returnType": "boolean",
      "parameters": {
        "type": "object",
        "properties": {
          "value": { "$ref": "common_types.json#/$defs/DynamicString" },
          "pattern": {
            "type": "string",
            "description": "The regex pattern to match against."
          }
        },
        "required": ["value", "pattern"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "length",
      "description": "Checks string length constraints.",
      "returnType": "boolean",
      "parameters": {
        "type": "object",
        "properties": {
          "value": { "$ref": "common_types.json#/$defs/DynamicString" },
          "min": {
            "type": "integer",
            "minimum": 0,
            "description": "The minimum allowed length."
          },
          "max": {
            "type": "integer",
            "minimum": 0,
            "description": "The maximum allowed length."
          }
        },
        "required": ["value"],
        "anyOf": [{ "required": ["min"] }, { "required": ["max"] }],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "numeric",
      "description": "Checks numeric range constraints.",
      "returnType": "boolean",
      "parameters": {
        "type": "object",
        "properties": {
          "value": { "$ref": "common_types.json#/$defs/DynamicNumber" },
          "min": {
            "type": "number",
            "description": "The minimum allowed value."
          },
          "max": {
            "type": "number",
            "description": "The maximum allowed value."
          }
        },
        "required": ["value"],
        "anyOf": [{ "required": ["min"] }, { "required": ["max"] }],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "email",
      "description": "Checks that the value is a valid email address.",
      "returnType": "boolean",
      "parameters": {
        "type": "object",
        "properties": {
          "value": { "$ref": "common_types.json#/$defs/DynamicString" }
        },
        "required": ["value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "formatString",
      "description": "Performs string interpolation of data model values and other functions in the catalog functions list and returns the resulting string. The value string can contain interpolated expressions in the `${data.path}` format. Supported expression types include: JSON Pointer paths to the data model (e.g., `${/absolute/path}` or `${relative/path}`), and client-side function calls (e.g., `${now()}`). Function arguments must be named (e.g., `${formatDate(value:${/currentDate}, format:'MM-dd')}`). To include a literal `${` sequence, escape it as `\\${`.",
      "returnType": "string",
      "parameters": {
        "type": "object",
        "properties": {
          "value": { "$ref": "common_types.json#/$defs/DynamicString" }
        },
        "required": ["value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "formatNumber",
      "description": "Formats a number with the specified grouping and decimal precision.",
      "returnType": "string",
      "parameters": {
        "type": "object",
        "properties": {
          "value": {
            "$ref": "common_types.json#/$defs/DynamicNumber",
            "description": "The number to format."
          },
          "decimals": {
            "$ref": "common_types.json#/$defs/DynamicNumber",
            "description": "Optional. The number of decimal places to show. Defaults to 0 or 2 depending on locale."
          },
          "grouping": {
            "$ref": "common_types.json#/$defs/DynamicBoolean",
            "description": "Optional. If true, uses locale-specific grouping separators (e.g. '1,000'). If false, returns raw digits (e.g. '1000'). Defaults to true."
          }
        },
        "required": ["value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "formatCurrency",
      "description": "Formats a number as a currency string.",
      "returnType": "string",
      "parameters": {
        "type": "object",
        "properties": {
          "value": {
            "$ref": "common_types.json#/$defs/DynamicNumber",
            "description": "The monetary amount."
          },
          "currency": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "The ISO 4217 currency code (e.g., 'USD', 'EUR')."
          },
          "decimals": {
            "$ref": "common_types.json#/$defs/DynamicNumber",
            "description": "Optional. The number of decimal places to show. Defaults to 0 or 2 depending on locale."
          },
          "grouping": {
            "$ref": "common_types.json#/$defs/DynamicBoolean",
            "description": "Optional. If true, uses locale-specific grouping separators (e.g. '1,000'). If false, returns raw digits (e.g. '1000'). Defaults to true."
          }
        },
        "required": ["currency", "value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "formatDate",
      "description": "Formats a timestamp into a string using a pattern.",
      "returnType": "string",
      "parameters": {
        "type": "object",
        "properties": {
          "value": {
            "$ref": "common_types.json#/$defs/DynamicValue",
            "description": "The date to format."
          },
          "format": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "A Unicode TR35 date pattern string.\n\nToken Reference:\n- Year: 'yy' (26), 'yyyy' (2026)\n- Month: 'M' (1), 'MM' (01), 'MMM' (Jan), 'MMMM' (January)\n- Day: 'd' (1), 'dd' (01), 'E' (Tue), 'EEEE' (Tuesday)\n- Hour (12h): 'h' (1-12), 'hh' (01-12) - requires 'a' for AM/PM\n- Hour (24h): 'H' (0-23), 'HH' (00-23) - Military Time\n- Minute: 'mm' (00-59)\n- Second: 'ss' (00-59)\n- Period: 'a' (AM/PM)\n\nExamples:\n- 'MMM dd, yyyy' -> 'Jan 16, 2026'\n- 'HH:mm' -> '14:30' (Military)\n- 'h:mm a' -> '2:30 PM'\n- 'EEEE, d MMMM' -> 'Friday, 16 January'"
          }
        },
        "required": ["format", "value"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "pluralize",
      "description": "Returns a localized string based on the Common Locale Data Repository (CLDR) plural category of the count (zero, one, two, few, many, other). Requires an 'other' fallback. For English, just use 'one' and 'other'.",
      "returnType": "string",
      "parameters": {
        "type": "object",
        "properties": {
          "value": {
            "$ref": "common_types.json#/$defs/DynamicNumber",
            "description": "The numeric value used to determine the plural category."
          },
          "zero": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "String for the 'zero' category (e.g., 0 items)."
          },
          "one": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "String for the 'one' category (e.g., 1 item)."
          },
          "two": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "String for the 'two' category (used in Arabic, Welsh, etc.)."
          },
          "few": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "String for the 'few' category (e.g., small groups in Slavic languages)."
          },
          "many": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "String for the 'many' category (e.g., large groups in various languages)."
          },
          "other": {
            "$ref": "common_types.json#/$defs/DynamicString",
            "description": "The default/fallback string (used for general plural cases)."
          }
        },
        "required": ["value", "other"],
        "unevaluatedProperties": false
      }
    },
    {
      "name": "openUrl",
      "description": "Opens the specified URL in a browser or handler. This function has no return value.",
      "returnType": "void",
      "parameters": {
        "allOf": [
          {
            "type": "object",
            "properties": {
              "url": {
                "type": "string",
                "format": "uri",
                "description": "The URL to open."
              }
            },
            "required": ["url"]
          }
        ],
        "unevaluatedProperties": false
      }
    }
  ],
  "theme": {
    "primaryColor": {
      "type": "string",
      "description": "The primary brand color used for highlights (e.g., primary buttons, active borders). Renderers may generate variants of this color for different contexts. Format: Hexadecimal code (e.g., '#00BFFF').",
      "pattern": "^#[0-9a-fA-F]{6}$"
    },
    "iconUrl": {
      "type": "string",
      "format": "uri",
      "description": "A URL for an image that identifies the agent or tool associated with the surface."
    },
    "agentDisplayName": {
      "type": "string",
      "description": "Text to be displayed next to the surface to identify the agent or tool that created it."
    }
  },
  "$defs": {
    "CatalogComponentCommon": {
      "type": "object",
      "properties": {
        "weight": {
          "type": "number",
          "description": "The relative weight of this component within a Row or Column. This is similar to the CSS 'flex-grow' property. Note: this may ONLY be set when the component is a direct descendant of a Row or Column."
        }
      }
    },
    "anyComponent": {
      "oneOf": [
        { "$ref": "#/components/Text" },
        { "$ref": "#/components/Image" },
        { "$ref": "#/components/Icon" },
        { "$ref": "#/components/Video" },
        { "$ref": "#/components/AudioPlayer" },
        { "$ref": "#/components/Row" },
        { "$ref": "#/components/Column" },
        { "$ref": "#/components/List" },
        { "$ref": "#/components/Card" },
        { "$ref": "#/components/Tabs" },
        { "$ref": "#/components/Modal" },
        { "$ref": "#/components/Divider" },
        { "$ref": "#/components/Button" },
        { "$ref": "#/components/TextField" },
        { "$ref": "#/components/CheckBox" },
        { "$ref": "#/components/ChoicePicker" },
        { "$ref": "#/components/Slider" },
        { "$ref": "#/components/DateTimeInput" }
      ],
      "discriminator": {
        "propertyName": "component"
      }
    }
  }
}
"""

def _build_unified_schema():
    server_schema = json.loads(_SERVER_TO_CLIENT_JSON)
    common_schema = json.loads(_COMMON_TYPES_JSON)
    catalog_schema = json.loads(_STANDARD_CATALOG_JSON)

    # Initialize $defs if not present
    if "$defs" not in server_schema:
        server_schema["$defs"] = {}

    # 1. Merge common types $defs
    if "$defs" in common_schema:
        server_schema["$defs"].update(common_schema["$defs"])

    # 2. Merge catalog $defs (e.g. CatalogComponentCommon, anyComponent)
    if "$defs" in catalog_schema:
        server_schema["$defs"].update(catalog_schema["$defs"])

    # 3. Add catalog definitions (components, functions, theme) to appropriate places.
    # The unified schema should ideally look like it has all definitions.
    # "anyComponent" refers to "#/components/Text", so we need "components" at root.
    if "components" in catalog_schema:
        server_schema["components"] = catalog_schema["components"]

    # We might also want "functions" and "theme" if there are any refs or just for completeness.
    # Though validation primarily checks against "oneOf" messages.
    if "functions" in catalog_schema:
        server_schema["functions"] = catalog_schema["functions"]
    if "theme" in catalog_schema:
        server_schema["theme"] = catalog_schema["theme"]

    # 4. Rewrite References
    # Recursively traverse and replace:
    # "common_types.json#" -> "#"
    # "catalog.json#" -> "#"

    def _rewrite_refs(obj):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k == "$ref" and isinstance(v, str):
                    v = v.replace("common_types.json#", "#")
                    v = v.replace("catalog.json#", "#")
                    # Also handle if standard_catalog self-refs using just relative paths if any,
                    # but usually they are #/$defs or json file refs.
                    obj[k] = v
                else:
                    _rewrite_refs(v)
        elif isinstance(obj, list):
            for item in obj:
                _rewrite_refs(item)

    _rewrite_refs(server_schema)

    return json.dumps(server_schema, indent=2)

A2UI_SCHEMA = _build_unified_schema()
