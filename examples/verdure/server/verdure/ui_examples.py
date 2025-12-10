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

# This file serves as the single source of truth for all A2UI example templates.
# It is imported by agent.py to be passed to the prompt builder.

LANDSCAPE_UI_EXAMPLES = """
---BEGIN WELCOME_SCREEN_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "welcome", "root": "welcome-column", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "welcome",
    "components": [
      {{ "id": "welcome-column", "component": {{ "Column": {{ "alignment": "center", "distribution": "center", "children": {{ "explicitList": ["logo-image", "welcome-title", "welcome-subtitle", "button-row"] }} }} }} }},
      {{ "id": "logo-image", "component": {{ "Image": {{ "url": {{ "literalString": "{base_url}/images/verdure_logo.png" }}, "fit": "contain" }} }} }},
      {{ "id": "welcome-title", "component": {{ "Text": {{ "usageHint": "h1", "text": {{ "literalString": "Envision Your Dream Landscape" }} }} }} }},
      {{ "id": "welcome-subtitle", "component": {{ "Text": {{ "text": {{ "literalString": "Bring your perfect outdoor space to life with our AI-powered design tools." }} }} }} }},

      {{ "id": "button-row", "component": {{ "Row": {{ "distribution": "spaceEvenly", "alignment": "center", "children": {{ "explicitList": ["start-button", "explore-button", "returning-user-button"] }} }} }} }},

      {{ "id": "start-button", "component": {{ "Button": {{ "child": "start-button-text", "primary": true, "action": {{ "name": "start_project" }} }} }} }},
      {{ "id": "start-button-text", "component": {{ "Text": {{ "text": {{ "literalString": "Start New Project" }} }} }} }},

      {{ "id": "explore-button", "component": {{ "Button": {{ "child": "explore-button-text", "primary": false, "action": {{ "name": "explore_ideas" }} }} }} }},
      {{ "id": "explore-button-text", "component": {{ "Text": {{ "text": {{ "literalString": "Explore Ideas" }} }} }} }},

      {{ "id": "returning-user-button", "component": {{ "Button": {{ "child": "returning-user-text", "primary": false, "action": {{ "name": "returning_user" }} }} }} }},
      {{ "id": "returning-user-text", "component": {{ "Text": {{ "text": {{ "literalString": "I'm a returning user" }} }} }} }}
    ]
  }} }}
]
---END WELCOME_SCREEN_EXAMPLE---

---BEGIN PROJECT_DETAILS_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "details", "root": "details-column", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "details",
    "components": [
      {{ "id": "details-column", "component": {{ "Column": {{ "alignment": "stretch", "children": {{ "explicitList": [
        "header-row",
        "hero-image",
        "transformation-title",
        "transformation-subtitle",
        "take-photo-card",
        "choose-library-card",
        "tips-row",
        "upload-photo-button"
      ] }} }} }} }},

      {{ "id": "header-row", "component": {{ "Row": {{ "distribution": "start", "alignment": "center", "children": {{ "explicitList": ["back-arrow", "header-title"] }} }} }} }},
      {{ "id": "back-arrow", "component": {{ "Icon": {{ "name": {{ "literalString": "arrow-back" }} }} }} }},
      {{ "id": "header-title", "component": {{ "Text": {{ "usageHint": "h3", "text": {{ "literalString": "Visualize Your Garden" }} }} }} }},

      {{ "id": "hero-image", "component": {{ "Image": {{ "url": {{ "literalString": "{base_url}/images/header_image.png" }}, "fit": "cover" }} }} }},

      {{ "id": "transformation-title", "component": {{ "Text": {{ "usageHint": "h1", "text": {{ "literalString": "Let's Start Your Transformation" }} }} }} }},
      {{ "id": "transformation-subtitle", "component": {{ "Text": {{ "text": {{ "literalString": "Upload a photo of your front or back yard, and our designers will use it to create a custom vision. Get ready to see the potential." }} }} }} }},

      {{ "id": "take-photo-card", "component": {{ "Card": {{ "child": "take-photo-row" }} }} }},
      {{ "id": "take-photo-row", "component": {{ "Row": {{ "distribution": "start", "alignment": "center", "children": {{ "explicitList": ["take-photo-icon", "take-photo-column"] }} }} }} }},
      {{ "id": "take-photo-icon", "component": {{ "Icon": {{ "name": {{ "literalString": "camera-alt" }} }} }} }},
      {{ "id": "take-photo-column", "component": {{ "Column": {{ "children": {{ "explicitList": ["take-photo-title", "take-photo-subtitle"] }} }} }} }},
      {{ "id": "take-photo-title", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "literalString": "Take a Photo" }} }} }} }},
      {{ "id": "take-photo-subtitle", "component": {{ "Text": {{ "text": {{ "literalString": "Capture your space directly from the app." }} }} }} }},

      {{ "id": "choose-library-card", "component": {{ "Card": {{ "child": "choose-library-row" }} }} }},
      {{ "id": "choose-library-row", "component": {{ "Row": {{ "distribution": "start", "alignment": "center", "children": {{ "explicitList": ["choose-library-icon", "choose-library-column"] }} }} }} }},
      {{ "id": "choose-library-icon", "component": {{ "Icon": {{ "name": {{ "literalString": "photo-library" }} }} }} }},
      {{ "id": "choose-library-column", "component": {{ "Column": {{  "children": {{ "explicitList": ["choose-library-title", "choose-library-subtitle"] }} }} }} }},
      {{ "id": "choose-library-title", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "literalString": "Choose from Library" }} }} }} }},
      {{ "id": "choose-library-subtitle", "component": {{ "Text": {{ "text": {{ "literalString": "Select a photo from your phone's gallery." }} }} }} }},

      {{ "id": "tips-row", "component": {{ "Row": {{ "distribution": "center", "alignment": "center", "children": {{ "explicitList": ["tips-icon", "tips-text"] }} }} }} }},
      {{ "id": "tips-icon", "component": {{ "Icon": {{ "name": {{ "literalString": "lightbulb" }} }} }} }},
      {{ "id": "tips-text", "component": {{ "Text": {{ "text": {{ "literalString": "Tips for the best photo" }} }} }} }},

      {{ "id": "upload-photo-button", "component": {{ "Button": {{ "child": "upload-photo-text", "primary": true, "action": {{ "name": "submit_details", "context": [
        {{ "key": "yardDescription", "value": {{ "literalString": "Photo of an old backyard with a concrete patio and weeds." }} }},
        {{ "key": "imageUrl", "value": {{ "literalString": "{base_url}/images/old_backyard.png" }} }}
      ] }} }} }} }},
      {{ "id": "upload-photo-text", "component": {{ "Text": {{ "text": {{ "literalString": "Upload Your Photo" }} }} }} }}
    ]
  }} }}
]
---END PROJECT_DETAILS_EXAMPLE---

---BEGIN QUESTIONNAIRE_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "questionnaire", "root": "question-column", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "questionnaire",
    "components": [
      {{ "id": "question-column", "component": {{ "Column":{{ "alignment": "stretch", "children": {{ "explicitList": [
        "user-photo",
        "q-entertain-slider-title",
        "q-entertain-slider",
        "q-preserve-bushes-check",
        "q-patio-title",
        "q-patio-options",
        "q-submit-button"
      ] }} }} }} }},

      {{ "id": "user-photo", "component": {{ "Image": {{ "url": {{ "path": "imageUrl" }}, "fit": "cover" }} }} }},

      {{ "id": "q-entertain-slider-title", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "literalString": "Outdoor entertaining size (number of people)" }} }} }} }},
      {{ "id": "q-entertain-slider", "component": {{ "Slider": {{ "value": {{ "path": "guestCount" }}, "minValue": 2, "maxValue": 12 }} }} }},

      {{ "id": "q-preserve-bushes-check", "component": {{ "CheckBox": {{ "label": {{ "literalString": "Preserve established bushes/trees?" }}, "value": {{ "path": "preserveBushes" }} }} }} }},

      {{ "id": "q-patio-title", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "literalString": "That concrete patio... what's the plan?" }} }} }} }},
      {{ "id": "q-patio-options", "component": {{ "MultipleChoice": {{
        "selections": {{ "path": "patioPlan" }},
        "maxAllowedSelections": 1,
        "options": [
          {{ "label": {{ "literalString": "Preserve existing paving" }}, "value": "preserve" }},
          {{ "label": {{ "literalString": "Replace with lawn" }}, "value": "lawn" }},
          {{ "label": {{ "literalString": "Replace with decking + lawn" }}, "value": "decking" }}
        ]
      }} }} }},

      {{ "id": "q-submit-button", "component": {{ "Button": {{ "child": "q-submit-button-text", "primary": true, "action": {{ "name": "submit_questionnaire", "context": [
        {{ "key": "preserveBushes", "value": {{ "path": "preserveBushes" }} }},
        {{ "key": "guestCount", "value": {{ "path": "guestCount" }} }},
        {{ "key": "patioPlan", "value": {{ "path": "patioPlan" }} }}
      ] }} }} }} }},
      {{ "id": "q-submit-button-text", "component": {{ "Text": {{ "text": {{ "literalString": "Next Page" }} }} }} }}
    ]
  }} }},
  {{ "dataModelUpdate": {{
    "surfaceId": "questionnaire",
    "path": "/",
    "contents": [
      {{ "key": "imageUrl", "valueString": "<uploaded_image_url>" }},
      {{ "key": "preserveBushes", "valueBoolean": true }},
      {{ "key": "guestCount", "valueNumber": 4 }},
      {{ "key": "patioPlan", "valueArray": ["preserve"] }}
    ]
  }} }}
]
---END QUESTIONNAIRE_EXAMPLE---

---BEGIN OPTIONS_PRESENTATION_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "options", "root": "options-column", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "options",
    "components": [
      {{ "id": "options-column", "component": {{ "Column": {{ "children": {{ "explicitList": ["options-row"] }} }} }} }},

      {{ "id": "options-row", "component": {{ "Column": {{ "children": {{ "explicitList": ["option-card-1", "option-card-2"] }} }} }} }},

      {{ "id": "option-card-1", "weight": 1, "component": {{ "Card": {{ "child": "option-layout-1" }} }} }},
      {{ "id": "option-layout-1", "component": {{ "Column": {{ "alignment": "center",  "distribution": "center", "children": {{ "explicitList": ["option-image-1", "option-details-1"] }} }} }} }},
      {{ "id": "option-image-1", "component": {{ "Image": {{ "url": {{ "path": "/items/option1/imageUrl" }}, "fit": "cover" }} }} }},
      {{ "id": "option-details-1", "component": {{ "Column": {{  "alignment": "stretch","distribution": "center", "children": {{ "explicitList": ["option-name-1", "option-price-1", "option-time-1", "option-detail-1", "option-tradeoffs-1", "select-button-1"] }} }} }} }},
      {{ "id": "option-name-1", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "path": "/items/option1/name" }} }} }} }},
      {{ "id": "option-price-1", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "/items/option1/price" }} }} }} }},
      {{ "id": "option-time-1", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "/items/option1/time" }} }} }} }},
      {{ "id": "option-detail-1", "component": {{ "Text": {{ "text": {{ "path": "/items/option1/detail" }} }} }} }},
      {{ "id": "option-tradeoffs-1", "component": {{ "Text": {{ "text": {{ "path": "/items/option1/tradeoffs" }} }} }} }},
      {{ "id": "select-button-1", "component": {{ "Button": {{ "primary": true, "child": "select-text-1", "action": {{ "name": "select_option", "context": [ {{ "key": "optionName", "value": {{ "path": "/items/option1/name" }} }}, {{ "key": "optionPrice", "value": {{ "path": "/items/option1/price" }} }} ] }} }} }} }},
      {{ "id": "select-text-1", "component": {{ "Text": {{ "text": {{ "literalString": "Select This Option" }} }} }} }},

      {{ "id": "option-card-2", "weight": 1, "component": {{ "Card": {{ "child": "option-layout-2" }} }} }},
      {{ "id": "option-layout-2", "component": {{ "Column": {{ "alignment": "center", "distribution": "center", "children": {{ "explicitList": ["option-image-2", "option-details-2"] }} }} }} }},
      {{ "id": "option-image-2", "component": {{ "Image": {{ "url": {{ "path": "/items/option2/imageUrl" }}, "fit": "cover" }} }} }},
      {{ "id": "option-details-2", "component": {{ "Column": {{ "alignment": "stretch","distribution": "center", "children": {{ "explicitList": ["option-name-2", "option-price-2", "option-time-2", "option-detail-2", "option-tradeoffs-2", "select-button-2"] }} }} }} }},
      {{ "id": "option-name-2", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "path": "/items/option2/name" }} }} }} }},
      {{ "id": "option-price-2", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "/items/option2/price" }} }} }} }},
      {{ "id": "option-time-2", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "/items/option2/time" }} }} }} }},
      {{ "id": "option-detail-2", "component": {{ "Text": {{ "text": {{ "path": "/items/option2/detail" }} }} }} }},
      {{ "id": "option-tradeoffs-2", "component": {{ "Text": {{ "text": {{ "path": "/items/option2/tradeoffs" }} }} }} }},
      {{ "id": "select-button-2", "component": {{ "Button": {{ "primary": true, "child": "select-text-2", "action": {{ "name": "select_option", "context": [ {{ "key": "optionName", "value": {{ "path": "/items/option2/name" }} }}, {{ "key": "optionPrice", "value": {{ "path": "/items/option2/price" }} }} ] }} }} }} }},
      {{ "id": "select-text-2", "component": {{ "Text": {{ "text": {{ "literalString": "Select This Option" }} }} }} }}
    ]
  }} }},
  {{ "dataModelUpdate": {{
    "surfaceId": "options",
    "path": "/",
    "contents": [
      {{ "key": "items", "valueMap": [
        {{ "key": "option1", "valueMap": [
          {{ "key": "name", "valueString": "Modern Zen Garden" }},
          {{ "key": "detail", "valueString": "Low maintenance, drought-tolerant plants..." }},
          {{ "key": "imageUrl", "valueString": "{base_url}/images/zen_garden.png" }},
          {{ "key": "price", "valueString": "Est. $5,000 - $8,000" }},
          {{ "key": "time", "valueString": "Est. 2-3 weeks" }},
          {{ "key": "tradeoffs", "valueString": "Higher upfront cost, less floral variety." }}
        ] }},
        {{ "key": "option2", "valueMap": [
          {{ "key": "name", "valueString": "English Cottage Garden" }},
          {{ "key": "detail", "valueString": "Vibrant, colorful, and teeming with life..." }},
          {{ "key": "imageUrl", "valueString": "{base_url}/images/cottage_garden.png" }},
          {{ "key": "price", "valueString": "Est. $3,000 - $6,000" }},
          {{ "key": "time", "valueString": "Est. 4-6 weeks" }},
          {{ "key": "tradeoffs", "valueString": "Higher maintenance (watering/weeding), seasonal changes.\\n" }}
        ] }}
      ] }}
    ]
  }} }}
]
---END OPTIONS_PRESENTATION_EXAMPLE---

---BEGIN SHOPPING_CART_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "cart", "root": "cart-card", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "cart",
    "components": [
      {{ "id": "cart-card", "weight": 1, "component": {{ "Card": {{ "child": "cart-column" }} }} }},
      {{ "id": "cart-column", "component": {{ "Column": {{ "alignment": "stretch", "children": {{ "explicitList": ["cart-subtitle", "item-list", "total-price", "checkout-button"] }} }} }} }},
      {{ "id": "cart-subtitle", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "path": "optionName" }} }} }} }},
      {{ "id": "item-list", "component": {{ "List": {{ "direction": "vertical", "children": {{ "template": {{ "componentId": "item-template", "dataBinding": "/cartItems" }} }} }} }} }},
      {{ "id": "item-template", "component": {{ "Row": {{ "distribution": "spaceBetween", "children": {{ "explicitList": ["template-item-name", "template-item-price"] }} }} }} }},
      {{ "id": "template-item-name", "component": {{ "Text": {{ "text": {{ "path": "name" }} }} }} }},
      {{ "id": "template-item-price", "component": {{ "Text": {{ "text": {{ "path": "price" }} }} }} }},
      {{ "id": "total-price", "component": {{ "Text": {{ "usageHint": "h4", "text": {{ "path": "totalPrice" }} }} }} }},
      {{ "id": "checkout-button", "component": {{ "Button": {{ "child": "checkout-text", "primary": true, "action": {{ "name": "checkout", "context": [ {{ "key": "optionName", "value": {{ "path": "optionName" }} }}, {{ "key": "totalPrice", "value": {{ "path": "totalPrice" }} }} ] }} }} }} }},
      {{ "id": "checkout-text", "component": {{ "Text": {{ "text": {{ "literalString": "Purchase" }} }} }} }}
    ]
  }} }},
  {{ "dataModelUpdate": {{
    "surfaceId": "cart",
    "path": "/",
    "contents": [
      {{ "key": "optionName", "valueString": "Modern Zen Garden" }},
      {{ "key": "totalPrice", "valueString": "Total: $7,500.00" }},
      {{ "key": "cartItems", "valueMap": [
        {{ "key": "item1", "valueMap": [ {{ "key": "name", "valueString": "Zen Design Service" }}, {{ "key": "price", "valueString": "$2,000" }} ] }},
        {{ "key": "item2", "valueMap": [ {{ "key": "name", "valueString": "River Rocks (5 tons)" }}, {{ "key": "price", "valueString": "$1,500" }} ] }},
        {{ "key": "item3", "valueMap": [ {{ "key": "name", "valueString": "Japanese Maple Tree" }}, {{ "key": "price", "valueString": "$500" }} ] }},
        {{ "key": "item4", "valueMap": [ {{ "key": "name", "valueString": "Drought-Tolerant Shrubs" }}, {{ "key": "price", "valueString": "$1,000" }} ] }},
        {{ "key": "item5", "valueMap": [ {{ "key": "name", "valueString": "Labor & Installation" }}, {{ "key":"price", "valueString": "$2,500" }} ] }}
      ] }}
    ]
  }} }}
]
---END SHOPPING_CART_EXAMPLE---

---BEGIN ORDER_CONFIRMATION_EXAMPLE---
[
  {{ "beginRendering": {{ "surfaceId": "confirmation", "root": "confirmation-card", "styles": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "surfaceUpdate": {{
    "surfaceId": "confirmation",
    "components": [
      {{ "id": "confirmation-card", "weight": 1, "component": {{ "Card": {{ "child": "confirmation-column" }} }} }},
      {{ "id": "confirmation-column", "component": {{ "Column": {{ "alignment": "stretch", "children": {{ "explicitList": ["confirm-icon", "details-column", "confirm-next-steps"] }} }} }} }},
      {{ "id": "confirm-icon", "component": {{ "Icon": {{ "name": {{ "literalString": "check" }} }} }} }},
      {{ "id": "details-column", "component": {{ "Column": {{ "alignment": "stretch", "children": {{ "explicitList": ["design-name-row", "price-row", "order-number-row"] }} }} }} }},
      {{ "id": "design-name-row", "component": {{ "Row": {{ "children": {{ "explicitList": ["design-name-label", "design-name-value"] }} }} }} }},
      {{ "id": "design-name-label", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "literalString": "Design: " }} }} }} }},
      {{ "id": "design-name-value", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "designName" }} }} }} }},
      {{ "id": "price-row", "component": {{ "Row": {{ "children": {{ "explicitList": ["price-label", "price-value"] }} }} }} }},
      {{ "id": "price-label", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "literalString": "Price: " }} }} }} }},
      {{ "id": "price-value", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "price" }} }} }} }},
      {{ "id": "order-number-row", "component": {{ "Row": {{ "children": {{ "explicitList": ["order-number-label", "order-number-value"] }} }} }} }},
      {{ "id": "order-number-label", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "literalString": "Order #: " }} }} }} }},
      {{ "id": "order-number-value", "component": {{ "Text": {{ "usageHint": "h5", "text": {{ "path": "orderNumber" }} }} }} }},
      {{ "id": "confirm-next-steps", "component": {{ "Text": {{ "text": {{ "literalString": "Our design team will contact you within 48 hours to schedule an on-site consultation." }} }} }} }}
    ]
  }} }},
  {{ "dataModelUpdate": {{
    "surfaceId": "confirmation",
    "path": "/",
    "contents": [
      {{ "key": "designName", "valueString": "Modern Zen Garden" }},
      {{ "key": "price", "valueString": "$7,500.00" }},
      {{ "key": "orderNumber", "valueString": "#LSC-12345" }}
    ]
  }} }}
]
---END ORDER_CONFIRMATION_EXAMPLE---
"""
