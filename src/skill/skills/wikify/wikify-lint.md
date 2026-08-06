# wikify — Lint Workflow

Run six health checks on the wiki, then present results and offer fixes.

## Step 0: Read Categories from WIKI_SCHEMA.md

Read `WIKI_SCHEMA.md` and extract the full category map before running any checks. All folder paths used in checks below come from this map — never hardcode folder names.

## Check 1: Contradictions

> **Note:** On wikis with more than 50 pages, offer to run the Contradictions check on a single category at a time rather than the whole wiki.

Use a chunked approach:

1. Read `wiki/index.md` to get the full page list grouped by category.
2. Process one category at a time. For each category folder, read all pages in that folder.
3. Within each category, check for internal contradictions (claims that conflict between pages in the same folder).
4. After finishing a category, check cross-category contradictions only for pages that share overlapping `related:` links — not all-vs-all.
5. Skip `wiki/sources/` — source summary pages rarely contain synthesised claims.

For each contradiction found, report:
- The conflicting claims (quote both)
- Which pages contain them
- Which raw sources support each claim

Ask the user which claim to trust, then update the incorrect page.

After updating the incorrect page, trace the superseded claim's lineage across the rest of the wiki:
1. Search other pages for references to the now-superseded claim, using both `related:` links (pages linked to or from the corrected page) and plain-text body search for the claim's key terms.
2. Pay special attention to pages created via the Query workflow's "save as wiki page" feature — these carry a `type` matching one of the schema categories but were created outside the normal Ingest flow, so they may repeat the stale claim without being caught by source re-ingestion.
3. Flag any such pages to the user for review rather than editing them silently. No new frontmatter fields are needed — this is a plain-text search across the wiki.

## Check 2: Orphan Pages

Build a link graph across the wiki:
- For each page, collect all paths from `related:` frontmatter and all inline markdown links
- Find pages that have zero inbound links from any other page

Exclude `wiki/index.md`, `wiki/log.md`, and `wiki/overview.md` from this check.

For each orphan, suggest adding it to related pages or flagging it for removal.

## Check 3: Stale Claims

For each source summary in `wiki/sources/`:
1. Read the `sources:` frontmatter to find the raw file path
2. Check the raw file's modification timestamp (`ls -la` via Bash)
3. Compare against the page's `updated:` date
4. If the raw file is newer, flag for re-ingestion

## Check 4: Missing Cross-References

> **Note:** On wikis with more than 50 pages, offer to run the Missing Cross-References check on a single category at a time rather than the whole wiki.

For every wiki page A listing page B in `related:`:
- Read page B and check if page A appears in B's `related:` list
- Report all one-directional links

Fix in two modes:
- **Batch fix (unambiguous cases):** When page A already lists page B in its `related:`, adding page A to page B's `related:` list is unambiguous. Apply all such fixes in one pass per category and report a summary count (e.g. "added 7 reciprocal links across the Concepts category") rather than requiring one-at-a-time approval.
- **One-at-a-time (ambiguous cases):** Reserve individual confirmation for cases that require judgment about whether the two pages are genuinely related — for example, when the existing one-directional link itself looks questionable and reciprocating it may not be warranted.

## Check 5: Stub Detection

> **Note:** On wikis with more than 50 pages, offer to run the Stub Detection check on a single category at a time rather than the whole wiki.

Scan all wiki page bodies for proper nouns and concept terms that:
- Appear in 2 or more different pages
- Do not have their own dedicated page in any category folder (from WIKI_SCHEMA.md)

Exclude generic or common technical terms (e.g. "API", "model", "system", "data", "service") unless they appear with a domain-specific modifier that makes them a meaningful distinct topic (e.g. "Assistants API", "reward model", "event sourcing system"). A bare generic term is not a stub candidate.

After generating the candidate stub list, present it to the user for confirmation or rejection before creating any pages (mirroring the category-confirmation pattern in wikify-init.md Step 0). Do not create pages automatically.

## Check 6: Broken Links

For every wiki page:
- Check all paths in `related:` frontmatter — verify each file exists
- Check all inline markdown links — verify each target exists
- Check all `sources:` frontmatter paths — verify each raw file exists

## Lint Summary

Present a summary table after all checks complete:

```
| Check               | Issues Found |
|---------------------|-------------|
| Contradictions      | X           |
| Orphan Pages        | X           |
| Stale Claims        | X           |
| Missing Cross-Refs  | X           |
| Stubs               | X           |
| Broken Links        | X           |
```

Offer to fix issues starting with broken links and working up to contradictions. For Missing Cross-References (Check 4), apply unambiguous reciprocal-link fixes in batch per category and report a summary count; get user approval one at a time only for its ambiguous cases. All other judgment-requiring fixes — contradictions (Check 1) especially, plus stub creation and orphan handling — remain one-at-a-time with user approval before each fix.
