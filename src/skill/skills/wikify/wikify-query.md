# wikify — Query Workflow

Synthesize an answer from the compiled wiki with citations back to source material.

## Step 1: Parse the Question

Extract the full question from the user's message.

## Step 2: Gather Context

1. Read `wiki/overview.md` for high-level context
2. Read `wiki/index.md` for the full page catalog
3. Read `wiki/excluded.md` if it exists — items noticed during Ingest but not compiled into dedicated pages (item name, source `raw/` path, exclusion reason, ingest date)
4. Identify relevant pages by matching the question against page titles and descriptions

**Optional — hybrid search for large wikis:** For wikis large enough that title/description matching in `wiki/index.md` isn't precise enough, you may supplement lookup with a lightweight BM25/vector search tool (e.g. a `qmd`-style CLI providing hybrid search over the wiki). This is optional guidance, not a hard dependency — the base workflow (`index.md` + targeted reads) remains dependency-free.

## Step 3: Read Relevant Pages

Read the identified relevant wiki pages (typically 3-10 depending on scope). Prioritize:
- Pages whose titles closely match the question topic
- Non-source pages over source summaries (they synthesize across sources)

**Two-pass fallback for broad queries:** If the relevant-page set exceeds ~15 pages (broad questions across a large wiki), don't attempt to read the full candidate set. Instead:
1. First pass — read only page titles and descriptions from `wiki/index.md` to build a ranked shortlist.
2. Second pass — do targeted full reads of only the top-ranked subset.

**Recursive synthesis (RLM) for very large wikis:** For wikis exceeding ~200 pages, avoid reading many individual pages flat — this risks exceeding context on broad cross-cutting questions. Instead summarize hierarchically:
1. Category level — for each relevant category, read its pages and produce one category-level synthesis.
2. Final level — synthesize the answer from the category-level summaries plus a small number of directly-relevant individual pages.

## Step 4: Synthesize Answer

Produce a comprehensive answer grounded in wiki content:
- Use inline citations: `(see [Page Title](wiki/path/page.md))`
- Note confidence levels for key claims
- Structure clearly with headings if complex

## Step 5: Identify Gaps

After answering, note areas where information is thin or missing and suggest source types that would fill the gaps.

**Excluded items:** If the query topic matches an entry in `wiki/excluded.md` but has no compiled wiki page covering it, surface this explicitly:

> "This wasn't compiled into the wiki, but appears in `raw/<file>`. Would you like me to read the raw source directly to answer this specific question?"

Before proceeding, state the tradeoff so the user can decide:
- Reading raw sources on demand costs more time/tokens per query than a compiled wiki page, and the answer won't have the wiki's cross-referencing or confidence tracking.
- Let the user choose whether that's worth it for this one question, or whether the item is worth promoting to a full wiki page.

If the user wants the ad-hoc answer: read only the specific referenced raw file(s) — not a full re-ingest — and answer from that source directly, noting the answer is source-level, not wiki-level synthesis.

If the user prefers to promote the item: offer to run it through Ingest Step 4 as a targeted addition (creating a proper wiki page) rather than answering ad hoc.

## Step 6: Offer to Save

Ask: "Should I save this answer as a wiki page?"

If yes:
1. Ask which category fits best (from WIKI_SCHEMA.md categories)
2. Create the page with full frontmatter
3. Update `wiki/index.md`
4. Append to `wiki/log.md` with a `query` action type
5. Run a cross-reference pass on the new page
