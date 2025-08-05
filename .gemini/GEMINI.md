# CatalogItem

A CatalogItem is an object which represents a widget that can be instantiated by an LLM. It centralizes the widgetBuilder function for the widget along with the data schema and name.

## Structure of a CatalogItem

- Only the variable that defines the CatalogItem should be public. Everything else should be private.
- The dataSchema must be defined as a Schema object. Look at `pkgs/flutter_genui/lib/src/catalog/core_widgets/elevated_button.dart` as a guide.
- Remember to use `Schema.object` and `Schema.enumString` etc.
- The Schema should _not_ have a "props" member or an "id" member, as those will be injected at a higher level. The schema should just be an object that includes all the properties that are specific to this widget, e.g. content to display.
- The only imports should be 'package:firebase_ai/firebase_ai.dart', 'package:flutter/material.dart' and the import for CatalogItem - this will be '../../model/catalog_item.dart' for the SDK, or 'package:flutter_genui/flutter_genui.dart' for the example apps. Any other utilities etc that are needed should be inlined into the file.
- The name of the CatalogItem should be in lower camel case.
- Widgets that require controllers or state in order to instantly reflect user inputs (e.g. Radio buttons, checkboxes, text fields) should be implemented as StatefulWidgets which maintain internal UI state. Look at `libs/src/widgets/radio_group.dart` as an example. There should be a private StatefulWidget class definition in the file.
- The input schema for CatalogItems should not include parallel lists of data - instead use a single list of object where it makes sense.
- If you are implementing a CatalogItem that needs to compose other CatalogItems, include a "child" or "children" parameter of String type, which will contain the ID of the child to reference. When building the child or children, use the buildChild function and pass in the string. See `pkgs/flutter_genui/lib/src/catalog/elevated_button.dart` and `pkgs/flutter_genui/lib/src/catalog/column.dart` as examples.
- All interactive UI elements where the user can input data e.g. by typing or selecting from options, or take action by clicking buttons etc, should handle those actions by calling the `dispatchEvent` callback, and including all the context needed for the LLM to understand what the user has done. E.g. if they have selected a specific option, the handler call should include the name of the selected option as the value.
- IMPORTANT: `required` is _not_ a parameter of Schema.object! For this Schema class, all parameters are required by default. Instead, there is an `optionalProperties` which you specify if there are any optional parameters.
- When parsing a catalog item in the widgetBuilder, use extension types for the data required by the catalog item, similar to `examples/travel_app/lib/src/catalog/travel_carousel.dart`.

## How to create a new a CatalogItem

1. Understand the structure of a CatalogItem by looking at `pkgs/flutter_genui/lib/src/model/catalog_item.dart` for the type, and `pkgs/flutter_genui/lib/src/catalog/elevated_button.dart` as an example to follow.
2. Create a new file in the relevant app, which contains a declaration of a global variable with a CatalogItem. The location of the file should be:

- For the generic flutter_genui SDK: `pkgs/flutter_genui/lib/src/catalog/`
- For an example app, at `examples/[MY_APP]/lib/src/catalog/` e.g. for the travel_app: `examples/travel_app/lib/src/catalog/`

3. Review your implementation and compare it to the examples, to ensure that the use of parameters matches and the structure of the code is similar. Fix any mistakes.
4. Write a test for the CatalogItem and run it, fixing any mistakes.
5. Update the Catalog definition for the app or SDK to include the new item.

## How to update the CatalogItem API

When the CatalogItem API changes, it is necessary to update all the existing catalog items to match.

1. Understand the change that has been requested, and carefully update the code at `pkgs/flutter_genui/lib/src/model/catalog_item.dart`.
2. Update all places that create and use CatalogItems e.g. `pkgs/flutter_genui/lib/src/model/catalog.dart`. Consider all the code at `pkgs/flutter_genui/lib/*` when doing this.
3. Find all CatalogItem implementations which will be at `examples/travel_app/lib/src/catalog/*`, `pkgs/flutter_genui/lib/src/catalog/*` etc. Update each of them to match the changes in the API.

## How to update every CatalogItem

1. Find all CatalogItem implementations which will be at `examples/travel_app/lib/src/catalog/*`, `pkgs/flutter_genui/lib/src/catalog/*` etc. Update each of them.

## Folder `spikes`

The folder `spikes` contains experiments and proof of concepts,
that does not have to be of good quality.

Skip this folder when reviewing code.
