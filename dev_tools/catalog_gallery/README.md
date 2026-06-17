# catalog_gallery

A developer tool for visualizing and testing the basic widget catalog. Displays all available `BasicCatalogItems` widgets and allows interaction testing.

**Key Features:**
- Browse all basic catalog widgets
- Interactive widget testing with event logging
- Sample file loading support

## Getting Started

This is a standard Flutter app that needs the
[Flutter SDK](https://docs.flutter.dev/get-started/install). The sample files
are bundled with the app as assets, so it runs on any target — web and desktop
included.

**Run:**
```bash
cd dev_tools/catalog_gallery
flutter run
```

Pass a device to `-d` to target a specific platform, for example
`flutter run -d chrome` (web) or `flutter run -d macos` (desktop). Run
`flutter devices` to list what is available.

### Loading samples from a custom directory (desktop only)

On desktop/mobile you can override the bundled samples with a directory on
disk:

```bash
flutter run -d macos --samples /path/to/samples
```

This option reads from the local filesystem and is not available on web.
