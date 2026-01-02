# Contributing to GenUI for Flutter

## Guidelines

Please follow [Flutter contributor guidelines][flutter_guidelines].

## Run Examples

To run examples:

1. Configure Firebase as described in [README.md][readme_md].
2. Run `flutter run`.

NOTE: For Google-internal projects see go/flutter-genui-internal.

## Shell scripts

To run a script in `tool/`, open the script in VSCode and press ⇧⌘B.

## Issue triage

### Daily front-line triage

The function of the daily front-line triage is to determine if the issue
is a _critical_ issue that needs immediate response.

Until the genui package is marked as 1.0,
an issue is _critical_ if it blocks someone from compiling the
package's code as part of their build process, or if previously
advertised behavior breaks in surprising ways (a behavior change
is not surprising if it was documented as part of the release
of the package).
We note that _critical_ issues should be very rare.

We have a rotation which runs daily on business days. The responsibilities
of the front-line triage include:

* Once a day, open the list of new issues which do not have
  [`front-line-handled` label][for-front-line].
* Assess if this issue is _critical_ (using the definition above).
  If so, assign P0 label and add the `front-line-handled` label. Then,
  ping the team chat, cc the Eng Manager, and share that a new P0
  regression / issue has been identified. In addition, reply to the issue
  to acknowledge that we believe this is a P0 issue and thank the
  author for their time.
* If the issue is not _critical_ and thus not a P0, then add
  the `front-line-handled` label to the issue. This signals that you have
  looked at the issue as part of front-line triage.
* If the issue looks legitimate, feel free to thank the author
  of the issue for their time. If a follow-up question is warranted,
  feel free to ask a follow-up question to help the second-line
  triage process.

### Periodic second-line triage

### Bi-weekly during the planning meeting

Check that existing issues are labeled and organized appropriately:

* Upgrade all [assigned P2/P3 issues][assigned_p2_p3_issues] to P1, or unassign
  them.
* Set a milestone to all [P0 and P1 issues][p0_p1_issues_without_milestone].
* Add all [projectless open issues][projectless_open_issues] to the "genui" project.

### Weekly during the planning meeting

Triage issues ready for second-line review:

* Open the [list of issues ready for second-line][ready-for-second-line].
* For each issue in the list:
  * Do one of:
    * If we don't plan to fix the issue, close it with an explanation.
    * If we plan to fix the issue assign a priority label:
      [P0][P0], [P1][P1], [P2][P2], or [P3][P3]. If you don't know which priority
      to assign, apply `P2`. If an issue is `P0` or `P1`, add it to a milestone.
  * Add a label for `second-line-triaged`

At the end of a triage session, the untriaged issue list should be as close to
empty as possible.

## Versioning

We use [Semver] for package versioning, although before 1.0.0, we will be
incrementing only the minor number for breaking changes and the patch number for
non-breaking changes. After 1.0.0, we will be using standard Semver, bumping the
major number for breaking changes.

We release the following packages in lock step,
with the same version number, so when one is released, they are all released:

* `genui`
* `genui_a2ui`
* `genui_firebase_ai`
* `genui_google_generative_ui`

These packages are released independently on their own schedule, with their
own version number:

* `genai_primitives`
* `json_schema_builder`

"Releasing" consititutes manually publishing them all to [pub.dev] after the
pull request containing the version bump has passed CI. The packages must be
published by someone with permission to publish under the labs.flutter.org
owner.

Use the [release tool](tool/release/README.md) to help automate the process of
releasing a new version.

[pub.dev]: https://pub.dev
[Semver]: https://semver.org/
[for-front-line]: https://github.com/flutter/genui/issues?q=is%3Aissue%20state%3Aopen%20-label%3AP0%20%20-label%3AP1%20-label%3AP2%20%20-label%3AP3%20-label%3Afront-line-handled
[flutter_guidelines]: https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md
[readme_md]: packages/genui/README.md#configure-firebase-ai-logic
[assigned_p2_p3_issues]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20label%3AP2%2CP3%20assignee%3A*
[p0_p1_issues_without_milestone]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20label%3AP1%2CP0%20no%3Amilestone
[projectless_open_issues]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20no%3Aproject
[ready-for-second-line]: https://github.com/flutter/genui/issues?q=is%3Aissue%20state%3Aopen%20label%3Afront-line-handled%20-label%3Asecond-line-triaged
[P0]: https://github.com/flutter/genui/labels?q=P0
[P1]: https://github.com/flutter/genui/labels?q=P1
[P2]: https://github.com/flutter/genui/labels?q=P2
[P3]: https://github.com/flutter/genui/labels?q=P3

## pubspec.lock files

`pubspec.lock` files are not git ignored to make the bots faster.

If you include `pubspec.lock` file to your PR, make sure to run `flutter pub upgrade`,
when your Flutter is latest at beta channel.

## Internal information

For Google-internal information see go/flutter-genui-internal.
