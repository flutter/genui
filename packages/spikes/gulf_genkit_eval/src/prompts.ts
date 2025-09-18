// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export interface TestPrompt {
  promptText: string;
  description: string;
  name: string;
  schema: string;
}

export const prompts: TestPrompt[] = [
  {
    name: 'dogBreedGenerator',
    description: 'A prompt to generate a UI for a dog breed information and generator tool.',
    schema: 'component_update.json',
    promptText: `Generate a JSON conforming to the schema to describe the following UI:

A root node has already been created with ID "root". You need to create a ComponentUpdate message now.

A vertical list with:
Dog breed information
Dog generator

The dog breed information is a card, which contains a title “Famous Dog breeds”, a header image, and a carousel of different dog breeds. The carousel information should be in the data model at /carousel.

The dog generator is another card which is a form that generates a fictional dog breed with a description
- Title
- Description text explaining what it is
- Dog breed name (text input)
- Number of legs (number input)
- Skills (checkboxes)
- Button called “Generate” which takes the data above and generates a new dog description
- A divider
- A section which shows the generated content
`,
  },
  {
    name: 'loginForm',
    description: 'A simple login form with username, password, a "remember me" checkbox, and a submit button.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a login form. It should have a "Login" heading, two text fields for username and password (bound to /login/username and /login/password), a checkbox for "Remember Me" (bound to /login/rememberMe), and a "Sign In" button. The button should trigger a 'login' action, passing the username, password, and rememberMe status in the dynamicContext.`
  },
  {
    name: 'productGallery',
    description: 'A gallery of products using a list with a template.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a product gallery. It should display a list of products from the data model at '/products'. Use a template for the list items. Each item should be a Card containing an Image (from '/products/item/imageUrl'), a Text component for the product name (from '/products/item/name'), and a Button labeled "Add to Cart". The button's action should be 'addToCart' and include a staticContext with the product ID, for example, 'productId': 'product123'. You should create a template component and then a list that uses it.`
  },
  {
    name: 'settingsPage',
    description: 'A settings page with tabs and a modal dialog.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a user settings page. Use a Tabs component with two tabs: "Profile" and "Notifications". The "Profile" tab should contain a simple column with a text field for the user's name. The "Notifications" tab should contain a checkbox for "Enable email notifications". Also, include a Modal component. The modal's entry point should be a button labeled "Delete Account", and its content should be a column with a confirmation text and two buttons: "Confirm Deletion" and "Cancel".`
  },
  {
    name: 'streamHeader',
    description: 'A StreamHeader message to initialize the UI stream.',
    schema: 'stream_header.json',
    promptText: `Generate a JSON StreamHeader message. This is the very first message in a UI stream, used to establish the protocol version. The version should be "1.0.0".`
  },
  {
    name: 'dataModelUpdate',
    description: 'A DataModelUpdate message to update user data.',
    schema: 'data_model_update.json',
    promptText: `Generate a JSON DataModelUpdate message. This is used to update the client's data model. The scenario is that a user has just logged in, and we need to populate their profile information. Create a single data model update message to set '/user/name' to "John Doe" and '/user/email' to "john.doe@example.com".`
  },
  {
    name: 'uiRoot',
    description: 'A UIRoot message to set the initial UI and data roots.',
    schema: 'begin_rendering.json',
    promptText: `Generate a JSON UIRoot message. This message tells the client where to start rendering the UI and where the root of the data model is. Set the UI root to a component with ID "mainLayout" and the data model root to a node with ID "dataRoot".`
  }
]
