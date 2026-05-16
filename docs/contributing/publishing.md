
# Publishing 

Publishing to [pub.dev](https://pub.dev) is happening automatically via GitHub actions, with help of
[firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

There are two CI workflows that enable this automation:

1. [post_summaries.yaml](../../.github/workflows/post_summaries.yaml)
2. [publish.yaml](../../.github/workflows/publish.yaml)

## Making PR passing `publish / validate`

In general, the job [publish / validate](https://github.com/flutter/genui/actions/runs/25936562918) checks if all pub.dev packages are ready for publishing. 

To make sure your PR passes this validation, follow [firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

## `-dev` vs non-`-dev` (production ready) versions

The packages code should be always release ready. That means:

1. Use `-dev` version if your changes don't touch any published code or docs. For example, you changed tests, tools, or not-publisshed docs.

2. If your feature is partially implemented, hide the feature's code behind a false by default, and use non-dev version.

## Package categories

`pub.dev` packages in this repo fall into three categories:

1. **Not published**: they have `release: none` in their `pubspec.yaml`.
2. **Mono-repo packages**: they have `resolution: workspace` in their `pubspec.yaml`, and are released together, with the same version number.
3. **Independent packages**: they don't have `release: none` and `resolution` in their `pubspec.yaml`. They are released independently.

## Versioning

We use [Semver] for package versioning, although before 1.0.0, we will be
incrementing only the minor number for breaking changes and the patch number for
non-breaking changes. After 1.0.0, we will be using standard Semver, bumping the
major number for breaking changes.

<!-- references -->

[Semver]: https://semver.org/ 
