
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

1. **Not planned to be published**: `pubspec.yaml` contains `publish_to: none`. Workspace tools and example apps that are never pushed to pub.dev.
2. **Not yet published**: the package's `version:` ends with a `-wip<N>` suffix (see "Versioning" below). Not-ready-for-production versions are pushed to pub.dev to reserve the name and maybe to try the package in dev purposes.
3. **Published**: any other package. Each has its own version cadence on pub.dev.

## About `resolution: workspace`

`resolution: workspace` in a `pubspec.yaml`:

1. Tells Dart to share dependency resolution and a lockfile with the monorepo.

2. Tells to use **current repo as a source** for the package, not pub.dev (for local runs).

Note that a package can opt out (by omitting `resolution: workspace`) to have separate dependency resolution.



## Versioning

We use [Semver] for package versioning, although before 1.0.0, we will be
incrementing only the minor number for breaking changes and the patch number for
non-breaking changes. After 1.0.0, we will be using standard Semver, bumping the
major number for breaking changes.

<!-- references -->

[Semver]: https://semver.org/ 

The versions may have postfixes:

- **`-wip<three digit number>`**: not ready for production
- **`-noop`**: used in CHANGELOG.md and pubspec.yaml to indicate that the code does not contain publishable changes comparing to the previously published version and thus should not be published to pub.dev.
- **no postfix**: release ready version, that should be pushed to pub.dev right after merging the PR that introduced the changes.

The packages code should be always release ready. That means:

1. Use `-wip` version (format `0.1.0-wip002`) if **at least one** the package is planned to be released in the future. 

2. Use `-noop` version if your PR touches only non-publishable code or docs (like tests, tools, or not-publishable docs).

3. You can publish `-wip<number>` versions (where `<number>` is a three-digit, zero padded integer like `-wip003`), if you need it for development, but do not merge `wip` versions for prod-ready published packages.

4. Remove `-noop` suffix from a version in `pubspec.yaml`, if your change  is publishable.

5. If your feature is partially implemented, hide the feature's code behind a false-by-default flag, and use **release-ready** version. (There is no detailed guidance how to define this flag yet. It should be outlined when it is needed. Please create an issue if you need it soon.)

## How publishing happens?

1. **Auto**: The workflow job `publish / validate` will:
   - check if the PR follows [firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).
   - add a table [like this](https://github.com/flutter/genui/pull/941#issuecomment-4556675732) to each PR.

2. **Manual**: After reviewing and merging the PR, for each 'ready to publish' version the author of the PR should run `flutter pub publish` or `dart pub publish`.

TODO(polinach): update this section after fix of https://github.com/dart-lang/ecosystem/issues/418.

## On-call responsibilities

Weekly:

1. Make sure each releasable dart package is released (TODO: [auto-create P0 bug](https://github.com/dart-lang/ecosystem/issues/423))
   1.1. Check the `Package publishing` table in the latest merged PR to see if all non-wip versions are marked `already published`.
   1.2. For packages not yet published, publish them by running `flutter pub publish` (if you do not have permissions, ask in the team chat to be made an admin on the admin page of the package).

2. Make sure publishable changes are not under `wip` in `CHANGELOG.md` (should be [auto-validated](https://github.com/dart-lang/ecosystem/issues/422) in future).
   
   If publishable changes are under `wip` in `CHANGELOG.md`:

   2.1. Convert the wip version to a non-wip version in `CHANGELOG.md`.

   2.2. Publish the new version.
   
   2.3. Comment on the PR that merged publishable changes under `wip`:
    
     > This PR wrongly placed publishable changes under a `wip` version. This is corrected in PR <link>. See guidelines [here](https://github.com/flutter/genui/blob/main/docs/contributing/publishing.md#-wip-vs-non--wip-production-ready-versions).

   2.4. Make sure the PR author and reviewers acknowledged the comment.

## How upgrade of dependencies happens?

### For run in workspace

For packages with `resolution: workspace` in their pubspec.yaml, pub resolves every sibling from its local source directory — not from pub.dev, as long as its `version:` satisfies the consumer's constraint.

If a local bump escapes that constraint (e.g. `^0.9.0` → `0.10.0`), you must update the consumer's `pubspec.yaml` in the same PR. While `dart pub` natively silently falls back to the published version on pub.dev, **our `test_and_fix` CI suite contains a verification step that will explicitly throw an error** and fail your PR if internal workspace version constraints are not met.

### For global dependencies

After a new version of a dependency is published, this is how upgrade will happen:

1. [Dependabot] detects the new version on pub.dev and opens a PR per dependency, bumping the constraint in each consuming `pubspec.yaml`. See [About Dependabot version updates] for details.
2. The PR runs `publish / validate` and the rest of CI.
3. A maintainer reviews and merges the PR. 

TODO: Consume solution for [dependabot issue][dependabot/dependabot-core#15057] when it is fixed.

[Dependabot]: ../../.github/dependabot.yaml
[About Dependabot version updates]: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates
[dependabot/dependabot-core#15057]: https://github.com/dependabot/dependabot-core/issues/15057

## How to configure GitHub and pub.dev for auto-publishing?

GitHub and pub.dev are already configured for auto-publishing. This section is here in case this needs to be reproduced for new repo or new package. 

Note that you need to have administrative permissions to update configuration.

### Setup org permissions

In https://github.com/organizations/flutter/settings/actions:

1. Find the section "Allow or block specified actions and reusable workflows"
2. Add these values (if they are already here, they will be de-dupped automatically):

   ```
   peter-evans/create-or-update-comment@*,
   peter-evans/create-pull-request@*,
   peter-evans/repository-dispatch@*,
   dart-lang/ecosystem/.github/workflows/health.yaml@*,
   dart-lang/ecosystem/.github/workflows/post_summaries.yaml@*,
   dart-lang/ecosystem/.github/workflows/publish.yaml@*,
   ```

### Configure pub.dev for each package 

This requires uploader/admin rights on the package.

1. Go to https://pub.dev/packages/<YOUR_PACKAGE_NAME>/admin
2. Under "Automated publishing", enable "Publishing from GitHub Actions" for both `push` and `workflow_dispatch` events.
3. Set Repository to `<YOUR_ORG>/<YOUR_REPO>`.
4. Set Tag pattern to `<YOUR_PACKAGE_NAME>-v{{version}}`.
