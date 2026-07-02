/*
 * Copyright 2025 The Flutter Authors.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

// Reconciles the 'status: needs-triage' label across all open pull requests. The
// label is fully owned by this automation: it is added to every PR that matches
// the rule below and removed from every PR that does not, on each run.
//
// A PR is flagged when it is a stale PR opened by an external contributor (PRs
// from maintainers are managed by their authors).
//
// "Stale" is measured from the last human contribution (a comment, review, or
// inline review comment, or the opening post if there are none) rather than
// `updated_at`, so the bot's own label edits never reset the clock. A PR is
// "stale" when no internal member has responded after the external author's last
// contribution for more than a day.
//
// Flagged PRs:
// https://github.com/flutter/genui/pulls?q=state%3Aopen%20label%3A%22status%3A%20needs-triage%22
//
// The job prints to console what PRs are flagged/unflagged and why. To see the
// history of runs see:
// https://github.com/flutter/genui/actions/workflows/triage.yaml

export const FLAG_LABEL = 'status: needs-triage';

export const PR_STALE_DAYS = 1;

const DAY_MS = 24 * 60 * 60 * 1000;

// Author associations that count as an internal maintainer response.
const MAINTAINER_ASSOCIATIONS = new Set(['OWNER', 'MEMBER', 'COLLABORATOR']);

// A deleted account surfaces as a null `user`; treat that as a human so their
// past contributions still count, rather than silently classifying them as a bot.
export const isBot = user =>
  Boolean(user) && (user.type === 'Bot' || /\[bot\]$/.test(user.login || ''));

const labelNames = item =>
  (item.labels || []).map(label => (typeof label === 'string' ? label : label.name));

const ageInDays = (isoTimestamp, now) => (now - new Date(isoTimestamp).getTime()) / DAY_MS;

/**
 * Returns the most recent human contribution to a PR: either its newest non-bot
 * contribution (a comment, review, or inline review comment), or — if there are
 * none — the opening post itself. Used both to measure staleness and to decide
 * whether an external author is still awaiting a maintainer response.
 *
 * `contributions` is the merged, normalized event list from `fetchContributions`.
 * It comes from three different endpoints so it is not sorted; the scan picks the
 * latest regardless of order.
 */
export function lastHumanContribution(item, contributions) {
  let latest = {
    createdAt: item.created_at,
    association: item.author_association,
    user: item.user,
  };

  for (const event of contributions) {
    if (isBot(event.user)) continue;
    if (new Date(event.createdAt) >= new Date(latest.createdAt)) {
      latest = event;
    }
  }

  return latest;
}

/**
 * Returns a human-readable reason why a single open PR should carry the flag
 * label, or null if it should not. The reason is logged for visibility.
 *
 * Only external contributors' PRs are watched; maintainers manage their own, so
 * an internally-authored PR is never flagged. A PR is "stale" when no internal
 * member has responded (via a comment, review, or inline review comment) after
 * the external author's last contribution for more than a day.
 */
export function flagReason(item, contributions, now) {
  if (MAINTAINER_ASSOCIATIONS.has(item.author_association)) {
    return null;
  }

  const latest = lastHumanContribution(item, contributions);
  const staleDays = ageInDays(latest.createdAt, now);

  // True when the most recent human contribution is from outside the team — no
  // internal member has commented after the external author's last word.
  const awaitingMember = !MAINTAINER_ASSOCIATIONS.has(latest.association) && !isBot(latest.user);

  return awaitingMember && staleDays > PR_STALE_DAYS
    ? `no maintainer has responded to the author for more than ${PR_STALE_DAYS} day.`
    : null;
}

// Max concurrent API calls per phase. Keeps us fast without tripping GitHub's
// secondary (abuse) rate limits, which a single huge Promise.all can hit.
const BATCH_SIZE = 10;

/**
 * Maps `items` through async `fn` in concurrent batches of `BATCH_SIZE` rather
 * than all at once, bounding the number of in-flight requests.
 */
async function mapInBatches(items, fn) {
  const results = [];
  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = items.slice(i, i + BATCH_SIZE);
    results.push(...(await Promise.all(batch.map(fn))));
  }
  return results;
}

// Normalizes the different GitHub contribution shapes into a common
// `{createdAt, association, user}` event. Reviews stamp their submission time in
// `submitted_at`; issue and inline review comments use `created_at`.
const toEvent = contribution => ({
  createdAt: contribution.created_at || contribution.submitted_at,
  association: contribution.author_association,
  user: contribution.user,
});

/**
 * Gathers every human-visible contribution to a PR — top-level issue comments,
 * formal reviews, and inline review comments — as a flat list of normalized
 * events. All three matter: a maintainer often responds by submitting a review
 * or leaving inline comments without posting a separate top-level comment, so
 * considering only issue comments would wrongly treat the PR as unanswered. A
 * failure for one source must not abort the whole run, so errors fall back to an
 * empty list for that source.
 */
async function fetchContributions({github, owner, repo}, item) {
  const number = item.number;

  const fetchAll = async (label, endpoint, params) => {
    try {
      return await github.paginate(endpoint, {owner, repo, per_page: 100, ...params});
    } catch (error) {
      console.error(`Failed to fetch ${label} for #${number}:`, error);
      return [];
    }
  };

  const [issueComments, reviews, reviewComments] = await Promise.all([
    // The issue-comment count is on the list item, so skip the call when it is
    // zero; reviews and review comments have no such hint and are always fetched.
    item.comments
      ? fetchAll('comments', github.rest.issues.listComments, {issue_number: number})
      : [],
    fetchAll('reviews', github.rest.pulls.listReviews, {pull_number: number}),
    fetchAll('review comments', github.rest.pulls.listReviewComments, {pull_number: number}),
  ]);

  return [...issueComments, ...reviews, ...reviewComments].map(toEvent);
}

export default async function prTriage({github, context}) {
  console.log('GenUI PR triage-flag reconciliation started');

  const {owner, repo} = context.repo;
  const now = Date.now();

  // `listForRepo` returns both issues and PRs; PRs carry a `pull_request` key.
  // We only reconcile PRs here.
  const openItems = await github.paginate(github.rest.issues.listForRepo, {
    owner,
    repo,
    state: 'open',
    per_page: 100,
  });
  const openPRs = openItems.filter(item => Boolean(item.pull_request));

  // Fetch each PR's contributions in bounded concurrent batches to avoid a slow
  // serial loop without flooding the API.
  const itemsWithContributions = await mapInBatches(openPRs, async item => ({
    item,
    contributions: await fetchContributions({github, owner, repo}, item),
  }));

  // Decide each PR's desired state from the snapshot, and keep only those whose
  // label needs to change. The snapshot from `listForRepo` can be stale if
  // another run (the daily schedule overlapping a PR event) already changed the
  // label, so the actual mutation re-checks the live state below.
  const itemsToUpdate = itemsWithContributions
    .map(({item, contributions}) => ({item, reason: flagReason(item, contributions, now)}))
    .filter(({item, reason}) => Boolean(reason) !== labelNames(item).includes(FLAG_LABEL));

  let added = 0;
  let removed = 0;

  await mapInBatches(itemsToUpdate, async ({item, reason}) => {
    const wantsFlag = Boolean(reason);
    try {
      // Re-read the live labels so a concurrent run cannot make us add the
      // label twice.
      const {data: fresh} = await github.rest.issues.get({
        owner,
        repo,
        issue_number: item.number,
      });
      const hasFlag = labelNames(fresh).includes(FLAG_LABEL);
      if (wantsFlag === hasFlag) {
        return; // Another run already reconciled this PR.
      }

      if (wantsFlag) {
        await github.rest.issues.addLabels({
          owner,
          repo,
          issue_number: item.number,
          labels: [FLAG_LABEL],
        });
        added += 1;
        console.log(`Flagged ${item.html_url} — ${reason}`);
      } else {
        await github.rest.issues.removeLabel({
          owner,
          repo,
          issue_number: item.number,
          name: FLAG_LABEL,
        });
        removed += 1;
        console.log(`Unflagged ${item.html_url} — no longer matches the triage rule.`);
      }
    } catch (error) {
      console.error(`Failed to update #${item.number}:`, error);
    }
  });

  console.log(
    `GenUI PR triage-flag reconciliation completed: ` +
      `${openPRs.length} PRs, +${added} / -${removed} label changes`,
  );
}
