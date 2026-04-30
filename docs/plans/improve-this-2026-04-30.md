# wikifyskill — Implementation Plan
**Date:** 2026-04-30
**Source:** docs/reviews/2026-04-30-improve-this.md
**Scope:** All 15 findings, priority order

Findings are grouped into phases by area of change to minimise context-switching.
Each task is numbered for tracking. All changes to `src/build-site.sh` must be
mirrored to `src/skill/scripts/build-site.sh` — finding #10 eliminates this
duplication, so do Phase 1 first.

---

## Phase 1 — Eliminate build-site.sh duplication (#10)

**Goal:** One canonical copy; install.sh derives the skill copy from it.

### 1.1 — Remove the duplicate from the skill directory

Delete `src/skill/scripts/build-site.sh`. The canonical file is `src/build-site.sh`.

### 1.2 — Update install.sh

After copying `src/skill/` to `~/.claude/skills/wikify/`, add a step that copies
`src/build-site.sh` into `~/.claude/skills/wikify/scripts/build-site.sh`.

```bash
mkdir -p "$SKILLS_DIR/scripts"
cp "$SRC_DIR/build-site.sh" "$SKILLS_DIR/scripts/build-site.sh"
```

**Verification:** Run `./scripts/install.sh`, confirm the skill dir contains
`scripts/build-site.sh` and that it matches `src/build-site.sh` byte-for-byte (`diff`).

---

## Phase 2 — Skill prompt: token efficiency (#1, #2, #5, #8)

All changes are to markdown skill files. No code changes.

### 2.1 — Ingest: use log.md for processed-file detection (#1)

In `src/skill/wikify-ingest.md` and `src/wikify.md`, replace Step 1 with:

**New Step 1:**
1. Read `wiki/log.md` and extract all source file paths that have been processed. Each ingest entry contains the raw file path — parse lines matching `- Source: ` to build the processed set.
2. Use Glob `raw/**/*` to list all raw files (excluding `.DS_Store`, `.gitkeep`, etc.).
3. Any raw file not in the processed set is unprocessed.

Only fall back to reading `wiki/sources/` frontmatter if `log.md` is absent or empty (e.g. migrating an older wiki).

**Why this works:** log.md is append-only and contains every processed raw path. One file read replaces N.

### 2.2 — Ingest: merge redundant summary items (#2)

In `src/skill/wikify-ingest.md` and `src/wikify.md`, Step 3 currently presents:
- Item 2: "Identified items per category"
- Item 5: "Suggested Wiki Pages"

Replace both with a single item: **"Pages to create or update"** — one combined list grouped by category, showing both new pages and existing pages that will be updated. Remove the separate "Suggested Wiki Pages" bullet entirely.

Before asking the user for input, also drop the "Identified source-summary" bullet (it's implicit — there's always one) and fold any contradictions note into the combined list as a warning flag on the relevant page entry.

**Net result:** Summary goes from 5 items to 3 (Takeaways, Pages to create/update, Contradictions if any).

### 2.3 — Router: remove blanket confirmation (#5)

In `src/skill/SKILL.md` and `src/wikify.md`, replace the final line:

> "Report which workflow was detected and ask the user to confirm before proceeding."

With workflow-specific behaviour:

- **Init, Ingest, Lint, Learning Plan**: proceed directly — announce the workflow in one line ("Detected: N unprocessed files. Starting Ingest."), then start.
- **Query**: proceed directly — no announcement needed, just answer.
- **Inconsistent state only**: pause and ask the user before doing anything destructive.
- **Nothing to do**: present the menu as before.

### 2.4 — Lint: chunk Contradictions check (#8)

In `src/skill/wikify-lint.md` and `src/wikify.md`, replace Check 1 with:

**New Check 1:**
1. Read `wiki/index.md` to get the full page list grouped by category.
2. Process one category at a time. For each category folder, read all pages in that folder.
3. Within each category, check for internal contradictions.
4. After finishing a category, check for cross-category contradictions only for pages with overlapping `related:` links (rather than all-vs-all).
5. Skip `sources/` — source summary pages rarely contain synthesised claims.

Also add a note: *"On wikis with more than 50 pages, offer to run Contradictions check on a single category at a time."*

---

## Phase 3 — Website: JS performance (#3, #15)

Changes to the `graph.js` string inside `src/build-site.sh`.

### 3.1 — Precompute adjacency map for hover (#3)

After `simulation` is created and before any event handlers, build an adjacency Set per node:

```js
const neighbors = new Map();
data.nodes.forEach(n => neighbors.set(n.id, new Set()));
data.edges.forEach(e => {
  neighbors.get(e.source.id || e.source)?.add(e.target.id || e.target);
  neighbors.get(e.target.id || e.target)?.add(e.source.id || e.source);
});
```

Then replace the mouseover opacity setter:
```js
// Before (O(n×m)):
return data.edges.some(e => (e.source.id===d.id && e.target.id===n.id)||...) ? 1 : 0.2;

// After (O(1) per node):
return n.id === d.id || neighbors.get(d.id)?.has(n.id) ? 1 : 0.2;
```

Note: the adjacency map must be built in the `tick` callback's first call or after `simulation` has resolved string IDs to object references — D3 mutates `edges` to replace string IDs with node objects after `forceLink` runs.

### 3.2 — Tune simulation cooling (#15)

Add to the simulation chain:
```js
.alphaDecay(0.03)   // faster cooling than default 0.0228
.alphaMin(0.001)    // explicit stop threshold
```

This cuts simulation ticks from ~300 to ~200 and makes the stop condition explicit.

---

## Phase 4 — Website: load performance (#6, #12)

Changes to `build-site.sh` data generation and `graph.js`.

### 4.1 — Embed panel content in data.js (#6)

At build time, add a `body_html` field to each node in `data.json`/`data.js`:

```python
nodes.append({
    ...existing fields...,
    "body_html": md_to_html(p["body"]),
    "related": p["related"],  # already present
})
```

In `graph.js`, replace `openPanel` to use this embedded content instead of fetching:

```js
function openPanel(nd) {
  const panel = document.getElementById('side-panel');
  const node = data.nodes.find(n => n.id === nd.id);
  const color = TYPE_COLORS[node.type] || '#8b949e';
  panel.querySelector('.panel-meta').innerHTML =
    `<span class="badge" style="background:${color}1f;color:${color}">${node.type}</span>
     <span class="badge badge-confidence">confidence: ${node.confidence}</span>`;
  panel.querySelector('.panel-body').innerHTML = node.body_html || '<p>No content.</p>';
  const pl = panel.querySelector('.panel-link');
  if (pl) pl.href = 'pages/' + nd.id + '.html';
  panel.classList.add('open');
}
```

This makes panel opens instant (no network round-trip). The trade-off is larger `data.js` — acceptable because individual page HTML is also generated, and users on slow connections benefit most from eliminating the per-click fetch.

The `async` keyword can be removed from `openPanel`; update the dblclick/contextmenu handlers accordingly.

### 4.2 — Generate per-category data files (#12)

At build time, after writing `data.js`, write one `data-<type>.js` per category containing only nodes of that type (no edges needed for the viz):

```python
for cat_type in unique_types:
    cat_nodes = [n for n in nodes if n["type"] == cat_type]
    cat_data = {"nodes": cat_nodes, "typeColors": type_colors}
    with open(os.path.join(WEBSITE_DIR, f"data-{cat_type}.js"), "w") as f:
        f.write(f"const WIKI_CAT_DATA = ")
        json.dump(cat_data, f)
        f.write(";\n")
```

Update category page HTML to load `data-<cat_type>.js` instead of `data.js`, and update `category.js` to read from `WIKI_CAT_DATA` instead of `WIKI_DATA`.

---

## Phase 5 — Website: usability (#4, #7, #9, #11, #13, #14)

### 5.1 — Change single-click to open panel, double-click to navigate (#4)

In `graph.js`, swap the click/dblclick behaviour:

```js
// Before:
node.on('click', (e, d) => { window.location.href = 'pages/' + d.id + '.html'; });
node.on('dblclick', (e, d) => { e.stopPropagation(); openPanel(d); });

// After:
node.on('click', (e, d) => { e.stopPropagation(); openPanel(d); });
node.on('dblclick', (e, d) => { e.stopPropagation(); window.location.href = 'pages/' + d.id + '.html'; });
```

Add a hint in the panel footer or tooltip: *"Double-click to open full page"*. Update the panel-link text from "Open full page →" to "Open full page (or double-click node) →".

Also update the contextmenu handler to keep right-click → panel behaviour unchanged.

### 5.2 — Add search/filter (#7)

**Category pages:** Add a text input above the list:

```html
<input id="cat-filter" type="text" placeholder="Filter..." 
  oninput="filterItems(this.value)">
```

With JS:
```js
function filterItems(term) {
  const q = term.toLowerCase();
  document.querySelectorAll('.cat-item').forEach(el => {
    el.style.display = el.querySelector('.cat-item-title')
      .textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}
```

**Main graph:** Add a search input in the nav bar. On input, highlight matching nodes (full opacity) and dim non-matching nodes (0.1 opacity). Clear on empty input.

```js
// In graph.js, after node selection is created:
document.getElementById('graph-search')?.addEventListener('input', e => {
  const q = e.target.value.toLowerCase();
  node.attr('opacity', d => !q || d.title.toLowerCase().includes(q) ? 1 : 0.08);
  labels.attr('opacity', d => !q || d.title.toLowerCase().includes(q) ? 0.8 : 0.05);
});
```

Add `<input id="graph-search" type="text" placeholder="Search nodes...">` to `index.html` nav.

### 5.3 — Fix blank line rendering (#9)

Replace `md_to_html` blank-line handling. Instead of converting line-by-line with `<br>` for empty lines, group consecutive non-empty lines into `<p>` blocks:

```python
def md_to_html(text):
    paragraphs = re.split(r'\n{2,}', text.strip())
    out = []
    for para in paragraphs:
        lines = para.split("\n")
        processed = []
        for line in lines:
            # apply all existing regex transforms...
            processed.append(line)
        joined = "\n".join(processed)
        # if it's already a block element (h1-h4, li), don't wrap in <p>
        if re.match(r'^<(h[1-4]|li|ul|ol)', joined.strip()):
            out.append(joined)
        else:
            out.append(f"<p>{joined}</p>")
    return "\n".join(out)
```

Wrap consecutive `<li>` elements in `<ul>` tags as a follow-on improvement.

### 5.4 — Add loading state to panel (#11)

With Phase 4.1 implemented, the panel open is synchronous and this finding is resolved automatically. If 4.1 is not implemented first, add a loading state:

In `graph.js` `openPanel`:
```js
async function openPanel(nd) {
  const panel = document.getElementById('side-panel');
  panel.querySelector('.panel-body').innerHTML = '<p class="panel-loading">Loading…</p>';
  panel.classList.add('open');
  // ...existing fetch logic
}
```

Add `.panel-loading { color: var(--color-text-muted); padding: 20px 0; }` to CSS.

### 5.5 — Add breadcrumb back-navigation to individual pages (#13)

In `build-site.sh`, update the individual page HTML template to include a breadcrumb above the title:

```python
# Determine the category display name and link
if p["dir"]:
    cat_label = TYPE_LABELS.get(p["type"], p["type"].replace("-", " ").title())
    breadcrumb = f'<nav class="breadcrumb"><a href="../categories/{p["type"]}.html">← {cat_label}</a></nav>'
else:
    breadcrumb = '<nav class="breadcrumb"><a href="../index.html">← Graph</a></nav>'
```

Add breadcrumb CSS to `wiki-css.css` default block:
```css
.breadcrumb { margin-bottom: 16px; }
.breadcrumb a { color: var(--color-text-muted); font-size: 13px; text-decoration: none; }
.breadcrumb a:hover { color: var(--color-text); }
```

Note: breadcrumb is generated into individual page HTML; `wiki-css.css` is only written on first run. The breadcrumb CSS must be added to the existing `wiki-css.css` on user machines separately, or the default CSS block in `build-site.sh` must be updated and a migration note added to CHANGELOG.

### 5.6 — Fix Sources timeline date semantics (#14)

Two options — pick one:

**Option A (recommended):** Add a `published:` field to the source-summary frontmatter schema (in `WIKI_SCHEMA.md` template and `wikify-ingest.md` instructions). Populate it during ingest from any detected publication date in the source. If no publication date is detectable, leave blank. The timeline viz uses `published:` if present, falls back to `created:` with a visual indicator ("processed date").

**Option B (minimal):** Relabel the timeline axis and tooltip to say "Date processed" instead of implying chronological publication order. Change the viz title from "Sources" to "Sources (by ingest date)".

Option B is a one-line change; Option A requires schema and ingest prompt changes.

---

## Implementation Order Summary

| Phase | Tasks | Files changed | Effort |
|-------|-------|--------------|--------|
| 1 | #10 — deduplicate build-site.sh | `scripts/install.sh`, delete `src/skill/scripts/build-site.sh` | Trivial |
| 2 | #1, #2, #5, #8 — skill prompt efficiency | `src/skill/wikify-ingest.md`, `src/skill/SKILL.md`, `src/skill/wikify-lint.md`, `src/wikify.md` | Small |
| 3 | #3, #15 — JS perf | `src/build-site.sh` (graph.js string) | Small |
| 4 | #6, #12 — load perf | `src/build-site.sh` (data gen + graph.js + category.js) | Medium |
| 5 | #4, #7, #9, #11, #13, #14 — usability | `src/build-site.sh` (multiple sections) | Medium |

Phases 1–3 have no dependencies on each other and can be done in any order or in parallel. Phase 4 should precede Phase 5 task 5.4 (loading state becomes moot once panel is synchronous).
