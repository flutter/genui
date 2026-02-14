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
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "welcome", "catalogId": "https://a2ui.org/specification/v0.9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "welcome",
    "components": [
      {{ "id": "root", "component": "Column", "align": "center", "justify": "center", "children": ["logo-image", "welcome-title", "welcome-subtitle", "button-row"] }},
      {{ "id": "logo-image", "component": "Image", "url": "{base_url}/images/verdure_logo.png", "fit": "contain" }},
      {{ "id": "welcome-title", "component": "Text", "variant": "h1", "text": "Envision Your Dream Landscape" }},
      {{ "id": "welcome-subtitle", "component": "Text", "text": "Bring your perfect outdoor space to life with our AI-powered design tools." }},

      {{ "id": "button-row", "component": "Row", "justify": "spaceEvenly", "align": "center", "children": ["start-button", "explore-button", "returning-user-button"] }},

      {{ "id": "start-button", "component": "Button", "child": "start-button-text", "variant": "primary", "action": {{ "event": {{ "name": "start_project" }} }} }},
      {{ "id": "start-button-text", "component": "Text", "text": "Start New Project" }},

      {{ "id": "explore-button", "component": "Button", "child": "explore-button-text", "action": {{ "event": {{ "name": "explore_ideas" }} }} }},
      {{ "id": "explore-button-text", "component": "Text", "text": "Explore Ideas" }},

      {{ "id": "returning-user-button", "component": "Button", "child": "returning-user-text", "action": {{ "event": {{ "name": "returning_user" }} }} }},
      {{ "id": "returning-user-text", "component": "Text", "text": "I'm a returning user" }}
    ]
  }} }}
]
---END WELCOME_SCREEN_EXAMPLE---

---BEGIN PROJECT_DETAILS_EXAMPLE---
[
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "details", "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "details",
    "components": [
      {{ "id": "root", "component": "Column", "align": "stretch", "children": [
        "header-row",
        "hero-image",
        "transformation-title",
        "transformation-subtitle",
        "take-photo-card",
        "choose-library-card",
        "tips-row",
        "upload-photo-button"
      ] }},

      {{ "id": "header-row", "component": "Row", "justify": "start", "align": "center", "children": ["back-arrow", "header-title"] }},
      {{ "id": "back-arrow", "component": "Icon", "name": "arrowBack" }},
      {{ "id": "header-title", "component": "Text", "variant": "h3", "text": "Visualize Your Garden" }},

      {{ "id": "hero-image", "component": "Image", "url": "{base_url}/images/header_image.png", "fit": "cover" }},

      {{ "id": "transformation-title", "component": "Text", "variant": "h1", "text": "Let's Start Your Transformation" }},
      {{ "id": "transformation-subtitle", "component": "Text", "text": "Upload a photo of your front or back yard, and our designers will use it to create a custom vision. Get ready to see the potential." }},

      {{ "id": "take-photo-card", "component": "Card", "child": "take-photo-row" }},
      {{ "id": "take-photo-row", "component": "Row", "justify": "start", "align": "center", "children": ["take-photo-icon", "take-photo-column"] }},
      {{ "id": "take-photo-icon", "component": "Icon", "name": "camera" }},
      {{ "id": "take-photo-column", "component": "Column", "children": ["take-photo-title", "take-photo-subtitle"] }},
      {{ "id": "take-photo-title", "component": "Text", "variant": "h4", "text": "Take a Photo" }},
      {{ "id": "take-photo-subtitle", "component": "Text", "text": "Capture your space directly from the app." }},

      {{ "id": "choose-library-card", "component": "Card", "child": "choose-library-row" }},
      {{ "id": "choose-library-row", "component": "Row", "justify": "start", "align": "center", "children": ["choose-library-icon", "choose-library-column"] }},
      {{ "id": "choose-library-icon", "component": "Icon", "name": "photo" }},
      {{ "id": "choose-library-column", "component": "Column",  "children": ["choose-library-title", "choose-library-subtitle"] }},
      {{ "id": "choose-library-title", "component": "Text", "variant": "h4", "text": "Choose from Library" }},
      {{ "id": "choose-library-subtitle", "component": "Text", "text": "Select a photo from your phone's gallery." }},

      {{ "id": "tips-row", "component": "Row", "justify": "center", "align": "center", "children": ["tips-icon", "tips-text"] }},
      {{ "id": "tips-icon", "component": "Icon", "name": "info" }},
      {{ "id": "tips-text", "component": "Text", "text": "Tips for the best photo" }},

      {{ "id": "upload-photo-button", "component": "Button", "child": "upload-photo-text", "variant": "primary", "action": {{ "event": {{ "name": "submit_details", "context": {{
        "yardDescription": "Photo of an old backyard with a concrete patio and weeds.",
        "imageUrl": "{base_url}/images/old_backyard.png"
      }} }} }} }},
      {{ "id": "upload-photo-text", "component": "Text", "text": "Upload Your Photo" }}
    ]
  }} }}
]
---END PROJECT_DETAILS_EXAMPLE---

---BEGIN QUESTIONNAIRE_EXAMPLE---
[
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "questionnaire", "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "questionnaire",
    "components": [
      {{ "id": "root", "component": "Column", "align": "stretch", "children": [
        "user-photo",
        "q-entertain-slider-title",
        "q-entertain-slider",
        "q-preserve-bushes-check",
        "q-patio-title",
        "q-patio-options",
        "q-submit-button"
      ] }},

      {{ "id": "user-photo", "component": "Image", "url": {{ "path": "imageUrl" }}, "fit": "cover" }},

      {{ "id": "q-entertain-slider-title", "component": "Text", "variant": "h5", "text": "Outdoor entertaining size (number of people)" }},
      {{ "id": "q-entertain-slider", "component": "Slider", "value": {{ "path": "guestCount" }}, "min": 2, "max": 12 }},

      {{ "id": "q-preserve-bushes-check", "component": "CheckBox", "label": "Preserve established bushes/trees?", "value": {{ "path": "preserveBushes" }} }},

      {{ "id": "q-patio-title", "component": "Text", "variant": "h5", "text": "That concrete patio... what's the plan?" }},
      {{ "id": "q-patio-options", "component": "ChoicePicker",
        "value": {{ "path": "patioPlan" }},
        "variant": "multipleSelection",
        "label": "Patio Options",
        "options": [
          {{ "label": "Preserve existing paving", "value": "preserve" }},
          {{ "label": "Replace with lawn", "value": "lawn" }},
          {{ "label": "Replace with decking + lawn", "value": "decking" }}
        ]
      }},

      {{ "id": "q-submit-button", "component": "Button", "child": "q-submit-button-text", "variant": "primary", "action": {{ "event": {{ "name": "submit_questionnaire", "context": {{
        "preserveBushes": {{ "path": "preserveBushes" }},
        "guestCount": {{ "path": "guestCount" }},
        "patioPlan": {{ "path": "patioPlan" }}
      }} }} }} }},
      {{ "id": "q-submit-button-text", "component": "Text", "text": "Next Page" }}
    ]
  }} }},
  {{ "version": "v0.9", "updateDataModel": {{
    "surfaceId": "questionnaire",
    "path": "/",
    "value": {{
      "imageUrl": "<uploaded_image_url>",
      "preserveBushes": true,
      "guestCount": 4,
      "lawnPlan": ["preserve"]
    }}
  }} }}
]
---END QUESTIONNAIRE_EXAMPLE---

---BEGIN OPTIONS_PRESENTATION_EXAMPLE---
[
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "options", "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "options",
    "components": [
      {{ "id": "root", "component": "Column", "children": ["options-row"] }},

      {{ "id": "options-row", "component": "Column", "children": ["option-card-1", "option-card-2"] }},

      {{ "id": "option-card-1", "component": "Card", "child": "option-layout-1" }},
      {{ "id": "option-layout-1", "component": "Column", "align": "center",  "justify": "center", "children": ["option-image-1", "option-details-1"] }},
      {{ "id": "option-image-1", "component": "Image", "url": {{ "path": "/options/items/option1/imageUrl" }}, "fit": "cover" }},
      {{ "id": "option-details-1", "component": "Column", "align": "stretch","justify": "center", "children": ["option-name-1", "option-price-1", "option-time-1", "option-detail-1", "option-tradeoffs-1", "select-button-1"] }},
      {{ "id": "option-name-1", "component": "Text", "variant": "h4", "text": {{ "path": "/options/items/option1/name" }} }},
      {{ "id": "option-price-1", "component": "Text", "variant": "h5", "text": {{ "path": "/options/items/option1/price" }} }},
      {{ "id": "option-time-1", "component": "Text", "variant": "h5", "text": {{ "path": "/options/items/option1/time" }} }},
      {{ "id": "option-detail-1", "component": "Text", "text": {{ "path": "/options/items/option1/detail" }} }},
      {{ "id": "option-tradeoffs-1", "component": "Text", "text": {{ "path": "/options/items/option1/tradeoffs" }} }},
      {{ "id": "select-button-1", "component": "Button", "variant": "primary", "child": "select-text-1", "action": {{ "event": {{ "name": "select_option", "context": {{ "optionName": {{ "path": "/options/items/option1/name" }}, "optionPrice": {{ "path": "/options/items/option1/price" }} }} }} }} }},
      {{ "id": "select-text-1", "component": "Text", "text": "Select This Option" }},

      {{ "id": "option-card-2", "component": "Card", "child": "option-layout-2" }},
      {{ "id": "option-layout-2", "component": "Column", "align": "center", "justify": "center", "children": ["option-image-2", "option-details-2"] }},
      {{ "id": "option-image-2", "component": "Image", "url": {{ "path": "/options/items/option2/imageUrl" }}, "fit": "cover" }},
      {{ "id": "option-details-2", "component": "Column", "align": "stretch","justify": "center", "children": ["option-name-2", "option-price-2", "option-time-2", "option-detail-2", "option-tradeoffs-2", "select-button-2"] }},
      {{ "id": "option-name-2", "component": "Text", "variant": "h4", "text": {{ "path": "/options/items/option2/name" }} }},
      {{ "id": "option-price-2", "component": "Text", "variant": "h5", "text": {{ "path": "/options/items/option2/price" }} }},
      {{ "id": "option-time-2", "component": "Text", "variant": "h5", "text": {{ "path": "/options/items/option2/time" }} }},
      {{ "id": "option-detail-2", "component": "Text", "text": {{ "path": "/options/items/option2/detail" }} }},
      {{ "id": "option-tradeoffs-2", "component": "Text", "text": {{ "path": "/options/items/option2/tradeoffs" }} }},
      {{ "id": "select-button-2", "component": "Button", "variant": "primary", "child": "select-text-2", "action": {{ "event": {{ "name": "select_option", "context": {{ "optionName": {{ "path": "/options/items/option2/name" }}, "optionPrice": {{ "path": "/options/items/option2/price" }} }} }} }} }},
      {{ "id": "select-text-2", "component": "Text", "text": "Select This Option" }}
    ]
  }} }},
  {{ "version": "v0.9", "updateDataModel": {{
    "surfaceId": "options",
    "path": "/options",
    "value": {{
      "items": {{
        "option1": {{
          "name": "Modern Zen Garden",
          "detail": "Low maintenance, drought-tolerant plants...",
          "imageUrl": "{base_url}/images/zen_garden.png",
          "price": "Est. $5,000 - $8,000",
          "time": "Est. 2-3 weeks",
          "tradeoffs": "Higher upfront cost, less floral variety."
        }},
        "option2": {{
          "name": "English Cottage Garden",
          "detail": "Vibrant, colorful, and teeming with life...",
          "imageUrl": "{base_url}/images/cottage_garden.png",
          "price": "Est. $3,000 - $6,000",
          "time": "Est. 4-6 weeks",
          "tradeoffs": "Higher maintenance (watering/weeding), seasonal changes.\\n"
        }}
      }}
    }}
  }} }}
]
---END OPTIONS_PRESENTATION_EXAMPLE---

---BEGIN SHOPPING_CART_EXAMPLE---
[
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "cart", "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "cart",
    "components": [
      {{ "id": "root", "weight": 1, "component": "Card", "child": "cart-column" }},
      {{ "id": "cart-column", "component": "Column", "align": "stretch", "children": ["cart-subtitle", "item-list", "total-price", "checkout-button"] }},
      {{ "id": "cart-subtitle", "component": "Text", "variant": "h4", "text": {{ "path": "/cart/optionName" }} }},
      {{ "id": "item-list", "component": "List", "direction": "vertical", "children": {{ "componentId": "item-template", "path": "/cart/cartItems" }} }},
      {{ "id": "item-template", "component": "Row", "justify": "spaceBetween", "children": ["template-item-name", "template-item-price"] }},
      {{ "id": "template-item-name", "component": "Text", "text": {{ "path": "name" }} }},
      {{ "id": "template-item-price", "component": "Text", "text": {{ "path": "price" }} }},
      {{ "id": "total-price", "component": "Text", "variant": "h4", "text": {{ "path": "/cart/totalPrice" }} }},
      {{ "id": "checkout-button", "component": "Button", "child": "checkout-text", "variant": "primary", "action": {{ "event": {{ "name": "checkout", "context": {{ "optionName": {{ "path": "/cart/optionName" }}, "totalPrice": {{ "path": "/cart/totalPrice" }} }} }} }} }},
      {{ "id": "checkout-text", "component": "Text", "text": "Purchase" }}
    ]
  }} }},
  {{ "version": "v0.9", "updateDataModel": {{
    "surfaceId": "cart",
    "path": "/cart",
    "value": {{
      "optionName": "Modern Zen Garden",
      "totalPrice": "Total: $7,500.00",
      "cartItems": {{
        "item1": {{ "name": "Zen Design Service", "price": "$2,000" }},
        "item2": {{ "name": "River Rocks (5 tons)", "price": "$1,500" }},
        "item3": {{ "name": "Japanese Maple Tree", "price": "$500" }},
        "item4": {{ "name": "Drought-Tolerant Shrubs", "price": "$1,000" }},
        "item5": {{ "name": "Labor & Installation", "price": "$2,500" }}
      }}
    }}
  }} }}
]
---END SHOPPING_CART_EXAMPLE---

---BEGIN ORDER_CONFIRMATION_EXAMPLE---
[
  {{ "version": "v0.9", "createSurface": {{ "surfaceId": "confirmation", "catalogId": "https://a2ui.org/specification/v0_9/standard_catalog.json", "theme": {{ "primaryColor": "#228B22", "font": "Roboto" }} }} }},
  {{ "version": "v0.9", "updateComponents": {{
    "surfaceId": "confirmation",
    "components": [
      {{ "id": "root", "weight": 1, "component": "Card", "child": "confirmation-column" }},
      {{ "id": "confirmation-column", "component": "Column", "align": "stretch", "children": ["confirm-icon", "details-column", "confirm-next-steps"] }},
      {{ "id": "confirm-icon", "component": "Icon", "name": "check" }},
      {{ "id": "details-column", "component": "Column", "align": "stretch", "children": ["design-name-row", "price-row", "order-number-row"] }},
      {{ "id": "design-name-row", "component": "Row", "children": ["design-name-label", "design-name-value"] }},
      {{ "id": "design-name-label", "component": "Text", "variant": "h5", "text": "Design: " }},
      {{ "id": "design-name-value", "component": "Text", "variant": "h5", "text": {{ "path": "/confirmation/designName" }} }},
      {{ "id": "price-row", "component": "Row", "children": ["price-label", "price-value"] }},
      {{ "id": "price-label", "component": "Text", "variant": "h5", "text": "Price: " }},
      {{ "id": "price-value", "component": "Text", "variant": "h5", "text": {{ "path": "/confirmation/price" }} }},
      {{ "id": "order-number-row", "component": "Row", "children": ["order-number-label", "order-number-value"] }},
      {{ "id": "order-number-label", "component": "Text", "variant": "h5", "text": "Order #: " }},
      {{ "id": "order-number-value", "component": "Text", "variant": "h5", "text": {{ "path": "/confirmation/orderNumber" }} }},
      {{ "id": "confirm-next-steps", "component": "Text", "text": "Our design team will contact you within 48 hours to schedule an on-site consultation." }}
    ]
  }} }},
  {{ "version": "v0.9", "updateDataModel": {{
    "surfaceId": "confirmation",
    "path": "/confirmation",
    "value": {{
      "designName": "Modern Zen Garden",
      "price": "$7,500.00",
      "orderNumber": "#LSC-12345"
    }}
  }} }}
]
---END ORDER_CONFIRMATION_EXAMPLE---
"""

