
# Publishing 

Publishing to [pub.dev](https://pub.dev) happens automatically via GitHub Actions, with the help of
[firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

There are two CI workflows that enable this automation:

1. [post_summaries.yaml](../../.github/workflows/post_summaries.yaml)
2. [publish.yaml](../../.github/workflows/publish.yaml)

## Making PR passing `publish / validate`

In general, the job [publish / validate](https://github.com/flutter/genui/actions/runs/25936562918) checks if all pub.dev packages are ready for publishing. 

To make sure your PR passes this validation, follow [firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

## Package categories

`pub.dev` packages in this repo fall into three categories:

1. **Not intended to be published**: they have `publish_to: none` in their `pubspec.yaml`.
2. **Mono-repo packages**: they have `resolution: workspace` in their `pubspec.yaml`, and are released together, in lock-step, with the same version number.
3. **Independent packages**: they don't have `publish_to` and `resolution` fields in their `pubspec.yaml`. They are released independently.
4. **Not yet published packages**: they have `resolution: workspace` and `release: none` in their `pubspec.yaml`.

## `-dev` vs non-`-dev` (production ready) versions

The packages code should be always release ready. That means:

1. Use `-dev` version if **at least one** of the following statements is true:

   1.1. The package is planned to be released in future. In this case it is published with `-dev` suffix in order to reserve the package name.

   1.2. The package's changes touch only pub.dev non-publishable code or docs (like tests, tools, or not-publishable docs) and it is not a mono-repo package in lock-step with another package that has publishable code.

   You can publish `-dev<number>` versions, if you need it for development. 

2. If your feature is partially implemented, hide the feature's code behind a false-by-default flag, and use **release-ready** version.

## Versioning

We use [Semver] for package versioning, although before 1.0.0, we will be
incrementing only the minor number for breaking changes and the patch number for
non-breaking changes. After 1.0.0, we will be using standard Semver, bumping the
major number for breaking changes.

<!-- references -->

[Semver]: https://semver.org/ 

## How publishing happens?

TODO(polina-c): add information, https://github.com/google/A2UI/issues/1383
