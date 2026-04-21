# wikify — Query Workflow

Synthesize an answer from the compiled wiki with citations back to source material.

## Step 1: Parse the Question

Extract the full question from the user's message.

## Step 2: Gather Context

1. Read `wiki/overview.md` for high-level context
2. Read `wiki/index.md` for the full page catalog
3. Identify relevant pages by matching the question against page titles and descriptions

## Step 3: Read Relevant Pages

Read the identified relevant wiki pages (typically 3-10 depending on scope). Prioritize:
- Pages whose titles closely match the question topic
- Non-source pages over source summaries (they synthesize across sources)

## Step 4: Synthesize Answer

Produce a comprehensive answer grounded in wiki content:
- Use inline citations: `(see [Page Title](wiki/path/page.md))`
- Note confidence levels for key claims
- Structure clearly with headings if complex

## Step 5: Identify Gaps

After answering, note areas where information is thin or missing and suggest source types that would fill the gaps.

## Step 6: Offer to Save

Ask: "Should I save this answer as a wiki page?"

If yes:
1. Ask which category fits best (from WIKI_SCHEMA.md categories)
2. Create the page with full frontmatter
3. Update `wiki/index.md`
4. Append to `wiki/log.md` with a `query` action type
5. Run a cross-reference pass on the new page
