# Contributing to this repository

This folder provides guidance for contributors,
targeted at both AI models and human developers.

## Index of specifications

This directory contains the following specifications:

- [Style guide](styleguide.md)
- [Design](design.md)
- [Pull requests](pull_requests.md)
- [Publishing](publishing.md)
- [Examples](../../examples/README.md)

## Note for AI models

If you are an AI model, please read all the specifications in this folder, and follow them carefully.
To signal, that you have read and understood the specifications, please start your reviews and responses with the following text:

```
I have read and understood ./docs/contributing/README.md.
```

## Documentation

1. Documentation in the repository (all .md files) should be clear, consistent, concise and up-to-date.
2. Documentation should not contain details that are easy to infer from the code.
3. If code does not match the documentation, there should be TODO comments in the code to signal the discrepancy should be resolved.
4. For documentation use [sentence case for headings](https://developers.google.com/style/capitalization#capitalization-in-titles-and-headings).

## Shell scripts

To run a script in `tool/`, open the script in VSCode and press ⇧⌘B.

## Versioning

We use [Semver] for package versioning, although before 1.0.0, we will be
incrementing only the minor number for breaking changes and the patch number for
non-breaking changes. After 1.0.0, we will be using standard Semver, bumping the
major number for breaking changes.

We release the following packages in lock step,
with the same version number, so when one is released, they are all released:

* `genui`
* `genui_a2a`
* `genui_firebase_ai`
* `genui_google_generative_ui`

These packages are released independently on their own schedule, with their
own version number:

* `genai_primitives`
* `json_schema_builder`

## pubspec.lock files

`pubspec.lock` files are not git ignored to make the bots faster.

If you include `pubspec.lock` file to your PR, make sure to run `flutter pub upgrade`,
when your Flutter is latest at beta channel.

<!-- references -->

[Semver]: https://semver.org/
