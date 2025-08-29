# Contributing to Flutter GenUI

## Guidelines

Please follow
[Flutter contributor guidelines](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md).

## Run Examples

To run examples:

1. Configure Firebase as described in [USAGE.md](packages/flutter_genui/USAGE.md#configure-firebase).
2. Run `flutter run`.

NOTE: For Google-internal projects see go/flutter-genui-internal.

## Shell scripts

To run a script in `tool/`, open the script in VSCode and press ⇧⌘B.

## Issue triage

We regularly triage issues by looking at newly filed issues and determining what
we should do about each of them. Triage issues as follows:

* Open the [list of untriaged issues][untriaged_list].
* For each issue in the list, do one of:
  * If we don't plan to fix the issue, close it with an explanation.
  * If we plan to fix the issue, add the `triaged` label and assign a priority: [P0][P0], [P1][P1], [P2][P2], or [P3][P3]. If you don't know which priority to assign, apply `P2`. If an issue is `P0` or `P1`, add it to a milestone.

At the end of a triage session, the untriaged issue list should be as close to
empty as possible.

[untriaged_list]: https://github.com/flutter/genui/issues?q=is%3Aissue+state%3Aopen+-label%3Atriaged
[P0]: https://github.com/flutter/genui/labels?q=P0
[P1]: https://github.com/flutter/genui/labels?q=P1
[P2]: https://github.com/flutter/genui/labels?q=P2
[P3]: https://github.com/flutter/genui/labels?q=P3
