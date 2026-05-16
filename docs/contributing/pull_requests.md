# Authoring pull requests

## Make your PR easy to review

1. Make sure your PR has meaningful title and description.
2. Make sure your PR is not too large. Smaller PRs are easier to review.
3. Separate code reorgs from feature changes.

## CI presubmit errors

You may get CI presubmit errors on pull requests for several reasons. This sections explains how to fix some of not obvious ones.

### From `publish / validate` job

In general, the job checks if all [pub.dev](https://pub.dev) packages are release ready. 

See [publishing.md](publishing.md) for more details.
