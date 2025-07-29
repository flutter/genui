/// A client for the Flutter Composition Protocol (FCP).
///
/// This library provides the necessary components to render a Flutter UI
/// from a JSON-based definition provided by a server.
library;

// The service for loading the widget catalog.
export 'src/core/catalog_service.dart';
// The registry for custom widget builders.
export 'src/core/widget_catalog_registry.dart'
    show CatalogWidgetBuilder, WidgetCatalogRegistry;
export 'src/core/widget_catalog_registry.dart';
// --- Data Models ---

// Public data models used in the FCP.
export 'src/models/models.dart';
export 'src/widgets/fcp_provider.dart';
export 'src/widgets/fcp_view.dart';
export 'src/widgets/fcp_view_controller.dart';
