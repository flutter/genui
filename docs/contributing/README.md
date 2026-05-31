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

## Binary files

Avoid adding binary files to the repository. If a binary file is needed, minimize its size
and accompany it with a markdown file that 
describes the binary file and how it was created.

For large binaries, use links instead of embedding them in the repository. 

To host binaries, use your personal account in:

- [Google Drive](https://drive.google.com/)
- [YouTube](https://www.youtube.com/)
- [Comment for a GitHub issue or PR]()
- [Flickr.com](https://www.flickr.com/)
- Any other service that provides direct download links

## Documentation

1. Documentation in the repository (all .md files) should be clear, consistent, concise and up-to-date.
2. Documentation should not contain details that are easy to infer from the code.
3. If code does not match the documentation, there should be TODO comments in the code to signal the discrepancy should be resolved.
4. For documentation use [sentence case for headings](https://developers.google.com/style/capitalization#capitalization-in-titles-and-headings).

## Shell scripts

To run a script in `tool/`:

- If you are on mac and use VS Code, open the script and press `⇧⌘B` (see [.vscode/tasks.json](../../.vscode/tasks.json)).
- Otherwise, you can invoke the scripts on the command line from any directory.

## pubspec.lock files

`pubspec.lock` files are not git ignored to make the bots faster.

If you include `pubspec.lock` file to your PR, make sure to run `flutter pub upgrade`,
when your Flutter is using the latest version of the beta channel (run `flutter channel beta && flutter upgrade` to make sure you're on the right one).

<!-- references -->

[Semver]: https://semver.org/
