# Monorepo Release Tool

This Dart-based command-line tool automates the package publishing process for this monorepo using a safe, two-stage workflow.

## Prerequisites

#### Permissions to publish a package to pub.dev

Make sure you have 'admin' permissions for the [labs.flutter.dev publisher](https://pub.dev/publishers/labs.flutter.dev), which you can verify on the [admin page](https://pub.dev/publishers/labs.flutter.dev/admin).

If you do not have permissions, ask an existing admin from the linked page to add you.

## How to release GenUI SDK

The process is a two-stage publish workflow. It is split into two distinct commands, `bump` and `publish`,
to separate release preparation from the act of publishing.

### 0. Update Dependencies

Before running `bump`, make sure to update dependencies to the latest stable versions. This can be done by running:

```bash
dart pub upgrade --major-versions
```

Also, use Antigravity or Gemini CLI to update `CHANGELOG.md` files. You can use a prompt like:

```txt
Look at the git diffs since the <previous tag> tag and add any missing changelog entries to each of the packages with CHANGELOG.md files for breaking and other changes.
```

Where `<previous tag>` is the tag of the previous release. For example, if the previous release was `genui-0.6.0`, then the command would be:

```txt
Look at the git diffs since the genui-0.6.0 tag and add any missing changelog entries to each of the packages with CHANGELOG.md files for breaking and other changes.
```

### 1. Prepare for Publish with `bump`

First, run the `bump` command to prepare the repository for a new release. This will bump the version numbers, finalize the changelogs, and upgrade dependencies. After running this command, you should review the changes, make any necessary manual adjustments, and then commit the changes to your version control system.

**Syntax:**

```bash
dart run tool/release/bin/release.dart bump --level <level>
```

**`<level>` can be one of:**

- `breaking`: Increments the major version for breaking changes.
- `major`: Increments the major version.
- `minor`: Increments the minor version for new features.
- `patch`: Increments the patch version for bug fixes.

### 2. Publish and Prepare for Next Publish Cycle with `publish`

After you have committed the changes from the `bump` command, you can publish the new version. The `publish` command will publish the packages, create git tags, and then prepare the repository for the next development cycle by adding a new `(in progress)` section to top of the CHANGELOG.md files.

By default, `publish` runs in dry-run mode, which simulates the publish process without actually uploading packages.

**Command:**

```bash
dart run tool/release/bin/release.dart publish
```

#### Actual Publish

To perform a real publish, use the `--force` flag. The tool will first perform a dry run. If successful, it will prompt for confirmation before proceeding.

**Command:**

```bash
dart run tool/release/bin/release.dart publish --force
```

After a successful publish, the tool will create local git tags for each published package and print the command needed to push them to the remote repository. You should then push the tags, and commit the new changes to the `CHANGELOG.md` files to start the next development cycle.
