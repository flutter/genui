// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { ComponentUpdateSchemaMatcher } from './component_update_schema_matcher';

export interface TestPrompt {
  promptText: string;
  description: string;
  name: string;
  schema: string;
  matchers?: ComponentUpdateSchemaMatcher[];
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
    matchers: [
      new ComponentUpdateSchemaMatcher('Card'),
      new ComponentUpdateSchemaMatcher('Image'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'Dog breed name'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'Number of legs'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Generate'),
      new ComponentUpdateSchemaMatcher('Divider'),
    ],
  },
  {
    name: 'loginForm',
    description: 'A simple login form with username, password, a "remember me" checkbox, and a submit button.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a login form. It should have a "Login" heading, two text fields for username and password (bound to /login/username and /login/password), a checkbox for "Remember Me" (bound to /login/rememberMe), and a "Sign In" button. The button should trigger a 'login' action, passing the username, password, and rememberMe status in the dynamicContext.`,
    matchers: [
      new ComponentUpdateSchemaMatcher('Heading', 'text', 'Login'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'username'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'password'),
      new ComponentUpdateSchemaMatcher('CheckBox', 'label', 'Remember Me'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Sign In'),
    ],
  },
  {
    name: 'productGallery',
    description: 'A gallery of products using a list with a template.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a product gallery. It should display a list of products from the data model at '/products'. Use a template for the list items. Each item should be a Card containing an Image (from '/products/item/imageUrl'), a Text component for the product name (from '/products/item/name'), and a Button labeled "Add to Cart". The button's action should be 'addToCart' and include a staticContext with the product ID, for example, 'productId': 'product123'. You should create a template component and then a list that uses it.`,
    matchers: [
      new ComponentUpdateSchemaMatcher('List'),
      new ComponentUpdateSchemaMatcher('Card'),
      new ComponentUpdateSchemaMatcher('Image'),
      new ComponentUpdateSchemaMatcher('Text', 'text', 'name'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Add to Cart'),
    ],
  },
  {
    name: 'settingsPage',
    description: 'A settings page with tabs and a modal dialog.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a user settings page. Use a Tabs component with two tabs: "Profile" and "Notifications". The "Profile" tab should contain a simple column with a text field for the user's name. The "Notifications" tab should contain a checkbox for "Enable email notifications". Also, include a Modal component. The modal's entry point should be a button labeled "Delete Account", and its content should be a column with a confirmation text and two buttons: "Confirm Deletion" and "Cancel".`,
    matchers: [
      new ComponentUpdateSchemaMatcher('Tabs'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'name'),
      new ComponentUpdateSchemaMatcher('CheckBox', 'label', 'Enable email notifications'),
      new ComponentUpdateSchemaMatcher('Modal'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Delete Account'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Confirm Deletion'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Cancel'),
    ],
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
  },
  {
    name: 'animalKingdomExplorer',
    description: 'A complex UI with deep nesting and many components to represent the animal kingdom.',
    schema: 'component_update.json',
    promptText: `Generate a JSON ComponentUpdate message for a UI explorer for the Animal Kingdom.

The UI should have a main 'Heading' with the text "The Animal Kingdom Explorer".

Below the heading, use a 'Tabs' component with 5 tabs: "Mammals", "Reptiles", "Birds", "Fish", and "Insects".

Each tab's content should be a 'Column'. The first item in the column is a 'Row' for filtering options:
- A 'TextField' with the label "Search Species".
- A 'MultipleChoice' component for "Filter by Continent" with options like Africa, Asia, Europe, North America, South America, Australia, Antarctica.

Below the filters, display the hierarchy. Use nested 'Card' components to create the structure. The hierarchy should be 4 levels deep. For example:
1. Kingdom: Animalia (Card)
2. Class: Mammalia (Card inside Animalia)
3. Order: Carnivora (Card inside Mammalia)
4. Species: Panthera leo (Lion) (Card inside Carnivora) - This card should contain a 'Row' with an 'Image', a 'Text' for the name, and a 'Button' to trigger a modal.

Create a hierarchy for a total of around 30 species across all tabs (6 per tab). For example:
- Mammals: Lion, Tiger, Wolf, Elephant, Giraffe, Panda.
- Reptiles: Nile Crocodile, Ball Python, Komodo Dragon, Green Sea Turtle, Chameleon, Gecko.
- Birds: Bald Eagle, Ostrich, Penguin, Peacock, Parrot, Owl.
- Fish: Great White Shark, Clownfish, Pufferfish, Tuna, Goldfish, Anglerfish.
- Insects: Monarch Butterfly, Honey Bee, Ant, Grasshopper, Dragonfly, Ladybug.

Finally, include a 'Modal' component. The entry point for the modal should be the button inside each species' details card. The modal content should be a 'Column' containing:
- A 'Heading' for the species name.
- A 'Video' component showing a clip of the animal.
- A 'Text' component with a detailed description.
- A 'Button' to "Close".`,
    matchers: [
      new ComponentUpdateSchemaMatcher('Heading', 'text', 'The Animal Kingdom Explorer'),
      new ComponentUpdateSchemaMatcher('Tabs'),
      new ComponentUpdateSchemaMatcher('TextField', 'label', 'Search Species'),
      new ComponentUpdateSchemaMatcher('MultipleChoice'),
      new ComponentUpdateSchemaMatcher('Card', 'child', 'Animalia'),
      new ComponentUpdateSchemaMatcher('Card', 'child', 'Mammalia'),
      new ComponentUpdateSchemaMatcher('Card', 'child', 'Carnivora'),
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Panthera leo'), // Lion
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Panthera tigris'), // Tiger
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Canis lupus'), // Wolf
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Loxodonta africana'), // Elephant
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Giraffa camelopardalis'), // Giraffe
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Ailuropoda melanoleuca'), // Panda
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Crocodylus niloticus'), // Nile Crocodile
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Python regius'), // Ball Python
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Varanus komodoensis'), // Komodo Dragon
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Chelonia mydas'), // Green Sea Turtle
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Chamaeleonidae'), // Chameleon
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Gekkota'), // Gecko
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Haliaeetus leucocephalus'), // Bald Eagle
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Struthio camelus'), // Ostrich
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Aptenodytes forsteri'), // Penguin
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Pavo cristatus'), // Peacock
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Psittaciformes'), // Parrot
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Strigiformes'), // Owl
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Carcharodon carcharias'), // Great White Shark
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Amphiprioninae'), // Clownfish
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Tetraodontidae'), // Pufferfish
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Thunnus'), // Tuna
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Carassius auratus'), // Goldfish
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Lophiiformes'), // Anglerfish
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Danaus plexippus'), // Monarch Butterfly
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Apis mellifera'), // Honey Bee
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Formicidae'), // Ant
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Caelifera'), // Grasshopper
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Anisoptera'), // Dragonfly
      new ComponentUpdateSchemaMatcher('Text', 'text', 'Coccinellidae'), // Ladybug
      new ComponentUpdateSchemaMatcher('Modal'),
      new ComponentUpdateSchemaMatcher('Video'),
      new ComponentUpdateSchemaMatcher('Button', 'label', 'Close'),
    ],
  }
]
