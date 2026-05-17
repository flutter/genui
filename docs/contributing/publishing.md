
# Publishing 

Publishing to [pub.dev](https://pub.dev) happens automatically via GitHub Actions, with the help of
[firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

There are two CI workflows that enable this automation:

1. [post_summaries.yaml](../../.github/workflows/post_summaries.yaml) - job `publish / validate` runs on pre-submit.
2. [publish.yaml](../../.github/workflows/publish.yaml) - job `publish / publish` runs on tagging.

## Passing the publish / validate job

In general, the job [publish / validate](https://github.com/flutter/genui/actions/workflows/post_summaries.yaml) checks if all pub.dev packages are ready for publishing.

To make sure your PR passes this validation, follow [firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

## Package categories

Packages in this repo fall into the following categories:

1. **Not published**: `pubspec.yaml` contains `publish_to: none`. Workspace tools and example apps that are never pushed to pub.dev.
2. **Not yet published**: the package's `version:` ends with a `-dev<N>` suffix (see "`-dev` vs non-`-dev`" below). Published to pub.dev only to reserve the name; not ready for general use yet.
3. **Published**: any other package. Each has its own version cadence on pub.dev.

Note: `resolution: workspace` in a `pubspec.yaml` is a tooling concern — it tells Dart to share dependency resolution and a lockfile with the monorepo, and it does **not** by itself imply anything about release cadence. A package can opt out of the workspace (omit `resolution: workspace`) to avoid circular dependencies or unrelated update churn while still being a published package.

## `-dev` vs non-`-dev` (production ready) versions

The packages code should be always release ready. That means:

1. Use `-dev` version if **at least one** of the following statements is true:

   1.1. The package is planned to be released in the future. In this case it is published with `-dev` suffix in order to reserve the package name.

   1.2. The package's changes touch only non-publishable code or docs (like tests, tools, or not-publishable docs).

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

## How upgrade of dependencies (for both siblings and third party) happens?

### For local development runs

For packages with `resolution: workspace` in their pubspec.yaml, pub resolves every sibling from its local source directory — not from pub.dev, as long as its `version:` satisfies the consumer's constraint.

If a local bump escapes that constraint (e.g. `^0.9.0` → `0.10.0`), update the consumer's `pubspec.yaml` in the same PR. Otherwise pub silently falls back to the published version on pub.dev.

### For runs by external packages

After a new version of a dependency (including sibling package in this repo) is published, this is how upgrade will happen:

1. [Dependabot] detects the new version on pub.dev and opens a PR per dependency, bumping the constraint in each consuming `pubspec.yaml`. See [About Dependabot version updates] for details.
2. The PR runs `publish / validate` and the rest of CI.
3. A maintainer reviews and merges the PR.

[Dependabot]: ../../.github/dependabot.yaml
[About Dependabot version updates]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates
