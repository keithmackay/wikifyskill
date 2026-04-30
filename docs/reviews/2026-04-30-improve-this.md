# wikifyskill — Improvement Review
**Date:** 2026-04-30
**Scope:** Performance (speed + token efficiency) and website usability
**Project type:** AI skill/prompt collection + Python static site generator + shell tooling

---

## Priority List

```
#1  [Impact: High | Confidence: High]   Token Efficiency — Ingest reads ALL source summaries to detect processed files
#2  [Impact: High | Confidence: High]   Token Efficiency — Ingest Step 3 presents the same list twice
#3  [Impact: High | Confidence: High]   Website Interaction Speed — mouseover neighbor check is O(n×m), no adjacency map
#4  [Impact: High | Confidence: High]   Website Usability — single-click on graph node navigates immediately (no preview-first)
#5  [Impact: High | Confidence: Medium] Token Efficiency — router requires confirmation every invocation (unnecessary round-trip)
#6  [Impact: High | Confidence: Medium] Website Load Performance — openPanel fetches full HTML on every panel open
#7  [Impact: High | Confidence: Medium] Website Usability — no search/filter anywhere on the site
#8  [Impact: Medium | Confidence: High] Token Efficiency — Lint Check 1 loads entire wiki at once, no chunking guidance
#9  [Impact: Medium | Confidence: High] Website Usability — blank lines render as <br> not paragraph breaks
#10 [Impact: Medium | Confidence: High] Token Efficiency — build-site.sh duplicated in two places (maintenance drift risk)
#11 [Impact: Medium | Confidence: High] Website Usability — panel fetch has no loading state (appears broken on slow connections)
#12 [Impact: Medium | Confidence: Medium] Website Load Performance — category pages load full data.js but only use one type's nodes
#13 [Impact: Medium | Confidence: Medium] Website Usability — no breadcrumbs or back-nav on individual pages
#14 [Impact: Low | Confidence: High]   Website Usability — Sources timeline uses processing date, not publication date
#15 [Impact: Low | Confidence: High]   Website Interaction Speed — D3 simulation has no alphaMin/alphaDecay tuning
```

---

## Categorized Breakdown

### Token Efficiency

**#1 — Ingest reads ALL source summaries to detect processed files**

Currently Step 1 globs `raw/**/*`, then reads every file in `wiki/sources/` and extracts their `sources:` frontmatter to build a set of processed paths. On a wiki with 100 sources, that's 100 file reads just to find what's new. `log.md` already exists as an append-only record of every ingested file path. It should be checked first — one read instead of N.

- **Impact: High** — grows linearly with wiki size; painful for large corpora
- **Confidence: High** — log.md is precisely designed for this

---

**#2 — Ingest Step 3 presents the same list twice**

The summary asks Claude to present both "Identified items per category" (list all entities, concepts, etc.) *and* "Suggested Wiki Pages" at the end. These are functionally the same list. The user sees the same information formatted twice before they can respond, wasting output tokens and user attention.

- **Impact: High** — happens on every single ingest
- **Confidence: High** — pure redundancy, merging them loses nothing

---

**#5 — Router requires confirmation every invocation**

`SKILL.md` ends with: *"Report which workflow was detected and ask the user to confirm before proceeding."* This means every `/wikify` invocation — including the obvious case where there's clearly new files to ingest — burns a full round-trip for confirmation. For the unambiguous paths (ingest with files found, init with no schema), the confirmation adds friction and latency with no safety benefit.

- **Impact: High** — every invocation affected
- **Confidence: Medium** — there are edge cases where confirmation is genuinely useful (ambiguous query vs. ingest), but the current rule is too broad

---

**#8 — Lint Check 1 loads entire wiki at once**

Check 1 (Contradictions) instructs: *"Read all wiki pages across all category folders."* This loads everything into context simultaneously. On a 200-page wiki this likely hits context limits, and it's wasted for wikis where contradictions are sparse. There's no guidance to process in chunks, start with recently-modified pages, or skip source summaries (which rarely contain synthesized claims).

- **Impact: Medium** — only affects lint, but lint is unusable on large wikis without chunking
- **Confidence: High**

---

**#10 — build-site.sh is duplicated**

`src/build-site.sh` and `src/skill/scripts/build-site.sh` are identical 1151-line files. The install script copies the skill directory, so they need to stay in sync manually. Any bug fix or feature in one must be manually applied to the other.

- **Impact: Medium** — maintenance overhead and source of future drift
- **Confidence: High** — `install.sh` could copy from one canonical source

---

### Website Load Performance

**#6 — openPanel fetches full HTML on every click**

When you double-click or right-click a node in the graph, `openPanel` fires a `fetch('pages/' + nd.id + '.html')`, downloads the entire page HTML (including `<head>`, `<nav>`, all styles, etc.), then DOMParser-strips it down to `.content` and `.page-meta`. This is: one network roundtrip per panel open, downloading ~5-10x more than needed, with no caching coordination. The node data is already in `data.js` — the body content could be embedded there at build time.

- **Impact: High** — perceptible latency on every panel interaction, especially on file://
- **Confidence: Medium** — embedding body in data.js would increase data.js size; trade-off depends on wiki size

---

**#12 — Category pages load full data.js**

Every category page loads `data.js` which contains all nodes and edges across the entire wiki. The category viz only uses the subset of nodes matching one type. For a wiki with 300 pages, a concept category page loads all 300 nodes + all edges to render 40 bubbles.

- **Impact: Medium** — grows with wiki size; currently negligible on small wikis
- **Confidence: Medium** — splitting data.js per category adds build complexity

---

### Website Interaction Speed

**#3 — Mouseover neighbor check is O(n×m)**

In `graph.js`, the `mouseover` handler does `data.edges.some(e => ...)` for every non-hovered node on every mouseover event. With 200 nodes and 400 edges, that's up to 199 × 400 = 79,600 comparisons per hover. The fix is to precompute an adjacency Set per node once after simulation loads.

- **Impact: High** — graph becomes visibly sluggish at scale; affects the flagship feature
- **Confidence: High** — standard D3 pattern, well-understood fix

---

**#15 — D3 simulation has no alphaMin/alphaDecay tuning**

The force simulation has no explicit `alphaMin` or custom `alphaDecay`. D3's default `alphaDecay` is 0.0228, meaning the simulation takes ~300 ticks to cool. On wikis with many nodes, this burns CPU for several seconds after load.

- **Impact: Low** — only affects initial load period; modern hardware handles it
- **Confidence: High**

---

### Website Usability/UX

**#4 — Single-click on graph node navigates immediately**

Clicking a node immediately navigates via `window.location.href`. There's no way to "almost click" a node while panning. The panel preview is only available via double-click or right-click — interactions most users won't discover. Single-click is the dominant user gesture; most knowledge graph UIs require explicit intent to navigate.

- **Impact: High** — affects every user's first experience with the graph
- **Confidence: High**

---

**#7 — No search or filter anywhere on the site**

No way to type a term and find matching nodes on the graph or category pages. On a wiki with 50+ pages, finding a specific entry requires scrolling or visual scanning.

- **Impact: High** — usability cliff as wiki size grows past ~30 pages
- **Confidence: Medium** — adds UI complexity to the generator

---

**#9 — Blank lines render as `<br>` not paragraph breaks**

`md_to_html` converts empty lines to `<br>` tags. Multiple blank lines produce stacked `<br>` elements. The visual result is readable but semantically wrong and makes prose-heavy pages look cramped.

- **Impact: Medium** — visual quality of every individual page
- **Confidence: High**

---

**#11 — Panel fetch has no loading state**

After double-clicking a node, the panel appears not to respond until the fetch completes. No spinner, skeleton, or "Loading…" text is shown while the fetch is in flight.

- **Impact: Medium** — users assume the click didn't register and click again
- **Confidence: High**

---

**#13 — No back navigation or breadcrumbs on individual pages**

Individual pages have no breadcrumb, no "← Back to Concepts" link, and no prev/next within the category. Returning to context requires the browser back button.

- **Impact: Medium** — particularly jarring when coming from a category list
- **Confidence: Medium**

---

**#14 — Sources timeline uses processing date, not publication date**

The timeline plots nodes by `created:` — the date the LLM processed the source, not when the source was written. A 2019 paper ingested today appears at 2026 on the timeline.

- **Impact: Low** — only affects Sources timeline
- **Confidence: High**
