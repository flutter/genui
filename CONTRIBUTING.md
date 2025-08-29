# Contributing to GenUI for Flutter

## Guidelines

Please follow [Flutter contributor guidelines][flutter_guidelines].

## Run Examples

To run examples:

1. Configure Firebase as described in [USAGE.md][usage_md].
2. Run `flutter run`.

NOTE: For Google-internal projects see go/flutter-genui-internal.

## Shell scripts

To run a script in `tool/`, open the script in VSCode and press ⇧⌘B.

## Issue triage

We regularly triage issues by looking at newly filed issues and determining what
we should do about each of them. Triage issues as follows:

Check that existing issues are labeled and organized appropriately:

* Upgrade all [assigned P2/P3 issues][assigned_p2_p3_issues] to P1, or unassign
  them.
* Set a milestone to all [P0 and P1 issues][p0_p1_issues_without_milestone].
* Add all [projectless open issues][projectless_open_issues] to the "genui" project.

Triage new issues:

* Open the [list of untriaged issues][untriaged_list].
* For each issue in the list, do one of:
  * If we don't plan to fix the issue, close it with an explanation.
  * If we plan to fix the issue assign a priority label:
    [P0][P0], [P1][P1], [P2][P2], or [P3][P3]. If you don't know which priority
    to assign, apply `P2`. If an issue is `P0` or `P1`, add it to a milestone.

At the end of a triage session, the untriaged issue list should be as close to
empty as possible.

[flutter_guidelines]: https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md
[usage_md]: packages/flutter_genui/USAGE.md#configure-firebase
[assigned_p2_p3_issues]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20label%3AP2%2CP3%20assignee%3A*
[p0_p1_issues_without_milestone]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20label%3AP1%2CP0%20no%3Amilestone
[projectless_open_issues]: https://github.com/flutter/genui/issues?q=is%3Aopen%20is%3Aissue%20no%3Aproject
[untriaged_list]: https://github.com/flutter/genui/issues?q=is%3Aissue%20state%3Aopen%20-label%3AP0%20%20-label%3AP1%20-label%3AP2%20%20-label%3AP3
[P0]: https://github.com/flutter/genui/labels?q=P0
[P1]: https://github.com/flutter/genui/labels?q=P1
[P2]: https://github.com/flutter/genui/labels?q=P2
[P3]: https://github.com/flutter/genui/labels?q=P3
