// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The tag that opens an Express payload block.
const String expressOpenTag = '<a2ui-express>';

/// The tag that closes an Express payload block.
const String expressCloseTag = '</a2ui-express>';

/// The variable that names the entry point of the component tree.
const String expressRootVariable = 'root';

/// The surface used when a block does not call `surface(...)`.
const String expressDefaultSurfaceId = 'default_surface';

/// The helper that binds a child slot to a data-driven list template.
const String expressTemplateHelper = '_template';

/// The call that declares a server-side event action.
const String expressEventCall = 'Event';

/// The call that targets a surface.
const String expressSurfaceCall = 'surface';

/// The call that deletes a surface.
const String expressDeleteSurfaceCall = 'deleteSurface';

/// The placeholder for a skipped optional positional argument.
const String expressSkipPlaceholder = '_';

/// Names that the compiler reserves and never resolves against a catalog.
const Set<String> expressReservedNames = {
  expressTemplateHelper,
  expressEventCall,
  expressSurfaceCall,
  expressDeleteSurfaceCall,
};
