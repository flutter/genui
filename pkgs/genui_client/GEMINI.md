# CatalogItem

A CatalogItem is an object which represents a widget that can be instantiated by an LLM. It centralizes the builder function for the widget along with the data schema and name.

The codebase is in the process of migrating from an older structure where building logic for a widget was defined in lib/src/dynamic_ui.dart and the schema was defined in lib/src/ui_schema.dart and the deserialization logic was in lib/src/ui_models.dart. These lines may be commented out, but you can still read them. In the new structure, we instead want to have a file for each CatalogItem in lib/src/widgets/ that contains the builder logic, schema and deserialization logic together.

Also, in the old structure, the schema represented each widget with a single object type that had many optional properties - see lib/src/ui_schema.dart. In the new approach, we will have a separate object for each widget type, with only relevant properties, mostly required. See lib/src/schema_generator.dart.

## Structure of a CatalogItem

- CatalogItems should *not* depend on ui_models.dart. Instead, they should include a builder function that inlines all the map access logic.
- Only the variable that defines the CatalogItem should be public. Everything else should be private.
- The Schema must be defined as a Schema object. Look at lib/src/widgets/elevated_button.dart as a guide. Remember to use `Schema.object` and `Schema.enumString` etc. Specify `optionalProperties` rather than `required`.
- The Schema should *not* have a "props" member or an "id" member, as those will be injected at a higher level. The schema should just be an object that includes all the properties that are specific to this widget, e.g. content to display.
- The only imports should be 'package:firebase_ai/firebase_ai.dart', 'package:flutter/material.dart' and '../catalog_item.dart'. Any other utilities etc that are needed should be inlined into the file.
- The name of the CatalogItem should be in lower camel case.
- Widgets that require controllers or state in order to instantly reflect user inputs (e.g. Radio buttons, checkboxes, text fields) should be implemented as StatefulWidgets which maintain internal UI state. Look at libs/src/widgets/radio_group.dart as an example. There should be a private StatefulWidget class definition in the file.

## How to migrate an existing supported widget to a CatalogItem

To migrate an existing supported widget using the older structure to a new CatalogItem:

1. Look at the existing definition of the widget in lib/src/ui_schema.dart and lib/src/dynamic_ui.dart.

2. Understand the structure of a CatalogItem by looking at lib/src/catalog_item.dart for the type, and lib/src/widgets/elevated_button.dart as an example to follow.

3. Create a new file under lib/src/widgets which contains a declaration of a global variable with a CatalogItem. The item should use a schema that includes all the relevant fields from ui_schema.dart, and a builder function which correctly accesses the data according to the schema.

4. Add the new CatalogItem to lib/src/core_catalog.dart

Note: don't delete any of the code that the new CatalogItem is based on. We will delete it all later once all the widgets are migrated.
