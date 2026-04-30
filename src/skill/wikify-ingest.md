# wikify — Ingest Workflow

Process new source files from `raw/` and create or update wiki pages.

## Step 0: Read Categories from WIKI_SCHEMA.md

**Before doing anything else**, read `WIKI_SCHEMA.md` and extract the Categories section. Parse each line of the form `- \`<folder>/\` → type: \`<type>\`` to build the category map.

This map drives all file placement and frontmatter type values in Steps 4 and 5. Never use hardcoded folder names — always use what WIKI_SCHEMA.md says.

## Step 1: Discover Unprocessed Files

**Build the processed-file set from `wiki/log.md`:**

1. Read `wiki/log.md`. Extract every source file path from lines matching `- Source: ` — each such line contains a path like `raw/path/to/file.ext`. This is the set of already-processed files.
2. Use the Glob tool to list all raw files: `pattern: raw/**/*`. Filter out `.DS_Store`, `.gitkeep`, `Thumbs.db`, and any file starting with `.`.
3. Any raw file whose path does not appear in the processed-file set is unprocessed.
4. **Fallback**: If `wiki/log.md` is absent or contains no `- Source:` lines (migrating an older wiki), fall back to reading each source summary page in `wiki/sources/` and extracting the `sources:` frontmatter field instead.

Report the count and list of unprocessed files. Ask: "Which file would you like to process first?" or "Process them in order?"

Process one file at a time. After each file, ask whether to continue with the next.

## Step 2: Read the Source

Read the file using the appropriate method based on file extension:

| Extension | Method |
|-----------|--------|
| `.md`, `.txt`, `.html` | Use the Read tool directly |
| `.csv`, `.json`, `.yaml`, `.yml` | Use the Read tool directly |
| `.py`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.c`, `.cpp`, `.h`, `.rb`, `.sh` | Use the Read tool directly |
| `.pdf` | Use the `read_pdf_content` MCP tool |
| `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg` | Use the Read tool (Claude sees images via vision) |
| Directories in `raw/repos/` | Read README.md first, then key source files |
| Other | Report the file type and ask the user for a text summary or to convert it |

## Step 3: Detect Domain and Present Summary

**First, detect the domain of the source material.**

| Domain | Signals |
|--------|---------|
| **Fiction / Narrative** | Novel, story, chapter headings, character names, dialogue |
| **Technical / Code** | Imports, function names, APIs, architecture diagrams |
| **Research / Academic** | Citations, abstracts, methodology sections |
| **General** | Mixed or unclear |

**Extraction mandate: Be exhaustive, not selective.**

The rule: **if it has a proper name, it gets a page.** Do not filter by importance.

After reading the source, present the user with:

1. **Key Takeaways** — Comprehensive bullet list
2. **Pages to create or update** — For each category in the wiki (from WIKI_SCHEMA.md), list every item from the source that belongs there, noting whether each is new or an update to an existing page. Be exhaustive. Flag any contradictions with existing wiki content inline as ⚠️ warnings.
3. **Contradictions** — (only if any exist) A summary of claims that conflict with existing wiki pages and which raw sources support each side.

Then ask: "Any additional context or direction for how to file this? Are there any items I missed?"

Wait for the user's response before proceeding.

## Step 4: Create and Update Wiki Pages

**Read the category map from WIKI_SCHEMA.md** (Step 0 result) to determine all file paths and type values.

**Source summary page** (always create):
- Path: `wiki/sources/<kebab-case-slug>.md`
- Frontmatter `type: source-summary`
- Body: summary paragraph, key takeaways, links to related wiki pages

**Pages for each category** (create or update):
- Path: `wiki/<folder>/<slug>.md` where `<folder>` comes from the category map
- Frontmatter `type: <type>` where `<type>` comes from the category map
- Check for an existing page before creating — if found, read it, append new information, add the raw file to `sources:`, update `updated:`
- Create a page for every item identified in Step 3 for that category. Do not omit anything.

All pages must use lowercase kebab-case filenames and the full frontmatter schema.

## Step 5: Update Index and Log

**Update `wiki/index.md`**:
- Read the current index
- Add entries for all newly created pages under the matching category section
- The section names come from WIKI_SCHEMA.md categories — do not add or invent sections not in the schema
- Format: `- [Title](relative-path) — type: <type>, confidence: <level>`
- Keep entries sorted alphabetically within each section
- Never remove a section heading — use `*None yet.*` as placeholder

**Append to `wiki/log.md`**:
```markdown
## [YYYY-MM-DD] ingest | Source Title
- Source: raw/path/to/file.ext
- Created: sources/slug.md
- Created: <cat>/new-page.md (if applicable)
- Updated: <cat>/existing-page.md (if applicable)
```

## Step 6: Cross-Reference Pass

Read all pages created or modified during this ingest. For each page:

1. Check the `related:` frontmatter list
2. For every page A that lists page B in `related:`, verify page B also lists page A
3. If page B doesn't link back, edit page B to add page A to its `related:` list
4. Update the `updated:` date on any page modified during this pass

## Step 7: Continue or Stop

If there are more unprocessed files, ask: "Process the next file (<filename>), or stop here?"

If no more unprocessed files remain: "All sources processed. Run wikify with a question to query the wiki, or ask for a lint health check."
