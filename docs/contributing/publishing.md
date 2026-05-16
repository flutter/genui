
# Publishing

Publishing is happening automatically via GitHub actions, with help of
[firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

There are two CI workflows that enable this automation:

1. [post_summaries.yaml](../../.github/workflows/post_summaries.yaml)
2. [publish.yaml](../../.github/workflows/publish.yaml)

## Making PR passing `publish / validate`

In general, the job [publish / validate](https://github.com/flutter/genui/actions/runs/25936562918) checks if all [pub.dev](https://pub.dev) packages are release ready. 

To make sure your PR passes this validation, follow [firehose rules](https://github.com/dart-lang/ecosystem/tree/main/pkgs/firehose).

## `-dev` vs non-`-dev` (production ready) versions

The packages code should be always release ready. That means:

1. Use `-dev` version if your changes don't touch any published code or docs. For example, you changed tests, tools, or not-publisshed docs.

2. If your feature is partially implemented, hide the feature's code behind a false by default, and use non-dev version.

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

[Semver]: https://semver.org/ 
