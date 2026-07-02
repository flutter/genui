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
// "Stale" is measured from the last human contribution (a comment, or the
// opening post if there are no human comments) rather than `updated_at`, so the
// bot's own label edits never reset the clock. A PR is "stale" when no internal
// member has commented after the external author's last comment for more than a
// day.
//
// The job prints to console what PRs are flagged/unflagged and why. To see the
// history of runs see the Actions tab for the triage workflow.

export const FLAG_LABEL = 'status: needs-triage';

export const PR_STALE_DAYS = 1;

const DAY_MS = 24 * 60 * 60 * 1000;

// Author associations that count as an internal maintainer response.
const MAINTAINER_ASSOCIATIONS = new Set(['OWNER', 'MEMBER', 'COLLABORATOR']);

export const isBot = user => !user || user.type === 'Bot' || /\[bot\]$/.test(user.login || '');

const labelNames = item =>
  (item.labels || []).map(label => (typeof label === 'string' ? label : label.name));

const ageInDays = (isoTimestamp, now) => (now - new Date(isoTimestamp).getTime()) / DAY_MS;

/**
 * Returns the most recent human contribution to a PR: either its newest non-bot
 * comment, or — if there are none — the opening post itself. Used both to
 * measure staleness and to decide whether an external author is still awaiting a
 * maintainer response.
 */
export function lastHumanContribution(item, comments) {
  let latest = {
    createdAt: item.created_at,
    association: item.author_association,
    user: item.user,
  };

  for (const comment of comments) {
    if (isBot(comment.user)) continue;
    if (new Date(comment.created_at) >= new Date(latest.createdAt)) {
      latest = {
        createdAt: comment.created_at,
        association: comment.author_association,
        user: comment.user,
      };
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
 * member has commented after the external author's last comment for more than a
 * day.
 */
export function flagReason(item, comments, now) {
  if (MAINTAINER_ASSOCIATIONS.has(item.author_association)) {
    return null;
  }

  const latest = lastHumanContribution(item, comments);
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

/**
 * Fetches the comments needed to evaluate a PR. We only need the most recent
 * human contribution, so we skip the API call entirely when the PR has no
 * comments and otherwise fetch a single page of the newest comments (sorted
 * descending) rather than paginating through the whole history. A failure for
 * one PR must not abort the whole run, so errors fall back to no comments.
 */
async function fetchComments({github, owner, repo}, item) {
  if (!item.comments) {
    return [];
  }
  try {
    const {data} = await github.rest.issues.listComments({
      owner,
      repo,
      issue_number: item.number,
      sort: 'created',
      direction: 'desc',
      per_page: 100,
    });
    return data;
  } catch (error) {
    console.error(`Failed to fetch comments for #${item.number}:`, error);
    return [];
  }
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

  // Fetch comments in bounded concurrent batches to avoid a slow serial loop
  // without flooding the API.
  const itemsWithComments = await mapInBatches(openPRs, async item => ({
    item,
    comments: await fetchComments({github, owner, repo}, item),
  }));

  // Decide each PR's desired state from the snapshot, and keep only those whose
  // label needs to change. The snapshot from `listForRepo` can be stale if
  // another run (the daily schedule overlapping a PR event) already changed the
  // label, so the actual mutation re-checks the live state below.
  const itemsToUpdate = itemsWithComments
    .map(({item, comments}) => ({item, reason: flagReason(item, comments, now)}))
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
