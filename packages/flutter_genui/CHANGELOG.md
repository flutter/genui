# Flutter GenUI Changelog

## 0.2.0

- **BREADKIGN**: Replaced `ElevatedButton` with a more generic `Button` component.
- **BREAKING**: Removed `CheckboxGroup` and `RadioGroup` from the core catalog. The `MultipleChoice` or `CheckBox` widgets can be used as replacements. See [migration guide](./.guides/docs/migration_from_0.1.0_to_0.2.0.md) for details.
- **Feature**: Added an `obscured` property to `TextInputChip` to allow for password style inputs.
- **Feature**: Added many new components to the core catalog: `AudioPlayer` (placeholder), `Button`, `Card`, `CheckBox`, `DateTimeInput`, `Divider`, `Heading`, `List`, `Modal`, `MultipleChoice`, `Row`, `Slider`, `Tabs`, and `Video` (placeholder).
- **Fix**: Corrected the action key from `actionName` to `name` in `Trailhead` and `TravelCarousel`.
- **Fix**: Corrected the image property from `location` to `url` in `TravelCarousel`.

## 0.1.0

- Initial Release
