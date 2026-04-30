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

For every wiki page A listing page B in `related:`:
- Read page B and check if page A appears in B's `related:` list
- Report all one-directional links and offer to fix them automatically

## Check 5: Stub Detection

Scan all wiki page bodies for proper nouns and concept terms that:
- Appear in 2 or more different pages
- Do not have their own dedicated page in any category folder (from WIKI_SCHEMA.md)

Report potential stub pages and offer to create them.

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

Offer to fix issues one at a time, starting with broken links and working up to contradictions. Get user approval before each fix.
