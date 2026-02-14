---
name: genui-helper
description: >
  Development helper for the GenUI repository. Use this skill when the user asks
  about GenUI workflows, running tests, creating components, finding A2UI or
  Dart references, or adhering to repository standards.
---

# GenUI Development Helper

This skill provides workflows and best practices specific to the `genui` repository.

## Workflows

### 1. Running Tests and Fixes

The repository uses a custom tool to run tests, apply fixes, and format code before committing.
It should typically only be run before committing, since it is inefficient and slow to run it on every change.

It will run `dart fix --apply`, `dart format`, and `flutter test` on all packages in the repository.

**Command:**
```bash
dart run tool/test_and_fix/bin/test_and_fix.dart
```

**When to use:**
- Before committing changes, to ensure project health.
- Instead of running `flutter test` manually for each project in the repo.

### 2. Creating a New Component in the genui package

When creating a new UI component in `genui`:

1.  **Location**: Place component files in `packages/genui/lib/src/components/`.
2.  **Inheritance**: Components must extend `UiComponent`.
3.  **A2UI Compliance**: Ensure the component matches the A2UI specification.
4.  **Documentation**: Follow strict Dart documentation standards.

### 3. Updating Documentation

- Documentation source of truth is in `docs/`.
- Use `mkdocs` context if mentioned, but primarily edit the markdown files directly.
- Ensure strict adherence to "Natural Writing" standards (no AI-isms).

## Key Constants & Patterns

- **Current A2UI Version**: v0.9
- **State Management**: Uses `SurfaceController` from `genui`.

## References

- A2UI Specification
  - Available in the submodule at @packages/genui/submodules/a2ui
  - The specification documentation is available in @packages/genui/submodules/a2ui/specification/v0.9/docs
  - The specification schemas are available in @packages/genui/submodules/a2ui/specification/v0.9/json
  - Because it is a submodule, you may need to update the submodule to get the latest specification.
- To find out details of a specific dart compiler diagnostic message, use the following url format to look up the details:
  - https://dart.dev/tools/diagnostics/<message_id>
  - Example: https://dart.dev/tools/diagnostics/ambiguous_import
- To find out details of a specific analyzer lint message, use the following url format to look up the details:
  - https://dart.dev/tools/linter-rules/<lint_rule_id>
  - Example: https://dart.dev/tools/linter-rules/always_declare_return_types