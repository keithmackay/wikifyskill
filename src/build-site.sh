#!/usr/bin/env python3
# ABOUTME: Builds a static website from wiki/ folder with D3.js force graph.
# ABOUTME: Generates data.json, index.html, category pages, and individual page HTML.

import sys
import os
import json
import re
import shutil

WIKI_DIR = sys.argv[1] if len(sys.argv) > 1 else "wiki"
WEBSITE_DIR = sys.argv[2] if len(sys.argv) > 2 else "website"

if not os.path.isdir(WIKI_DIR):
    print(f"Error: wiki directory not found at '{WIKI_DIR}'")
    print("Usage: build-site.sh [wiki-dir] [output-dir]")
    sys.exit(1)

# Color palette — first 4 are canonical colors for known types, rest for extras
PALETTE = [
    '#5b9bd5',  # concept
    '#66c29a',  # entity
    '#d4a054',  # source-summary
    '#9a7ec4',  # comparison
    '#e06c75',  # extra
    '#56b6c2',  # extra
    '#d19a66',  # extra
    '#98c379',  # extra
    '#c678dd',  # extra
    '#abb2bf',  # extra
]
KNOWN_TYPE_ORDER = ['concept', 'entity', 'source-summary', 'comparison', 'learning-plan']
SPECIAL_ROOT_FILES = {'index.md', 'log.md', 'overview.md'}  # root wiki files to skip

# Clean generated files but preserve wiki-css.css (user may have customized it)
css_backup = None
if os.path.isdir(WEBSITE_DIR):
    css_path = os.path.join(WEBSITE_DIR, "wiki-css.css")
    if os.path.isfile(css_path):
        with open(css_path) as f:
            css_backup = f.read()
    for name in ["categories", "pages"]:
        p = os.path.join(WEBSITE_DIR, name)
        if os.path.isdir(p):
            shutil.rmtree(p)
    for name in ["data.json", "data.js", "graph.js", "category.js", "index.html"]:
        p = os.path.join(WEBSITE_DIR, name)
        if os.path.isfile(p):
            os.remove(p)
    import glob as glob_module
    for f in glob_module.glob(os.path.join(WEBSITE_DIR, "data-*.js")):
        os.remove(f)

os.makedirs(os.path.join(WEBSITE_DIR, "categories"), exist_ok=True)
os.makedirs(os.path.join(WEBSITE_DIR, "pages"), exist_ok=True)


# --- Parse frontmatter from a markdown file ---
def parse_page(filepath, category):
    with open(filepath, encoding="utf-8") as f:
        text = f.read()

    slug = os.path.splitext(os.path.basename(filepath))[0]
    fm, body = {}, ""
    lines = text.split("\n")
    i = 0
    if lines and lines[0].strip() == "---":
        i = 1
        collecting = None
        while i < len(lines):
            line = lines[i]
            if line.strip() == "---":
                i += 1
                break
            if line.startswith("title: "):
                fm["title"] = line[7:].strip(); collecting = None
            elif line.startswith("type: "):
                fm["type"] = line[6:].strip(); collecting = None
            elif line.startswith("confidence: "):
                fm["confidence"] = line[12:].strip(); collecting = None
            elif line.startswith("created: "):
                fm["created"] = line[9:].strip(); collecting = None
            elif line.startswith("updated: "):
                fm["updated"] = line[9:].strip(); collecting = None
            elif line.strip() == "sources:":
                fm.setdefault("sources", []); collecting = "sources"
            elif line.strip() == "related:":
                fm.setdefault("related", []); collecting = "related"
            elif line.startswith("  - ") and collecting:
                fm.setdefault(collecting, []).append(line[4:].strip())
            else:
                collecting = None
            i += 1
        body_lines = lines[i:]
    # Strip a leading "# Title" from the body if it duplicates the frontmatter title
    title_val = fm.get("title", "")
    if body_lines:
        first_content = next((l for l in body_lines if l.strip()), "")
        if first_content.startswith("# ") and first_content[2:].strip() == title_val:
            idx = next(j for j, l in enumerate(body_lines) if l.strip() == first_content)
            body_lines = body_lines[idx + 1:]
    body = "\n".join(body_lines)

    if "title" not in fm:
        return None

    return {
        "slug": slug,
        "title": fm.get("title", ""),
        "type": fm.get("type", ""),
        "confidence": fm.get("confidence", ""),
        "created": fm.get("created", ""),
        "updated": fm.get("updated", ""),
        "sources": fm.get("sources", []),
        "related": fm.get("related", []),
        "dir": category,
        "body": body,
    }


def obsidian_link_to_html(match):
    """Convert [[path/slug|Display Title]] or [[slug]] to HTML links."""
    inner = match.group(1)
    if "|" in inner:
        path, label = inner.split("|", 1)
    else:
        path, label = inner, inner
    slug = os.path.splitext(os.path.basename(path.replace("\\", "/")))[0]
    return f'<a href="{slug}.html">{html_escape(label.strip())}</a>'


def md_to_html(text):
    def transform_line(line):
        line = re.sub(r'^#### (.+)', r'<h4>\1</h4>', line)
        line = re.sub(r'^### (.+)', r'<h3>\1</h3>', line)
        line = re.sub(r'^## (.+)', r'<h2>\1</h2>', line)
        line = re.sub(r'^# (.+)', r'<h1>\1</h1>', line)
        line = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', line)
        line = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', line)
        line = re.sub(r'`([^`]+)`', r'<code>\1</code>', line)
        line = re.sub(r'\[\[([^\]]+)\]\]', obsidian_link_to_html, line)
        line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', line)
        line = re.sub(r'^- (.+)', r'<li>\1</li>', line)
        return line
    paragraphs = re.split(r'\n{2,}', text.strip())
    out = []
    for para in paragraphs:
        lines = [transform_line(l) for l in para.split("\n") if l.strip()]
        if not lines:
            continue
        joined = "\n".join(lines)
        if re.match(r'^<(h[1-4]|li)', joined.strip()):
            out.append(joined)
        else:
            out.append(f"<p>{joined}</p>")
    return "\n".join(out)


def html_escape(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


# --- Collect all pages from all subdirectories ---
print("Parsing wiki pages...")
pages = []
if os.path.isdir(WIKI_DIR):
    # Parse root-level .md files with frontmatter (e.g. learning_plan.md)
    for fname in sorted(os.listdir(WIKI_DIR)):
        if not fname.endswith(".md") or fname in SPECIAL_ROOT_FILES:
            continue
        fpath = os.path.join(WIKI_DIR, fname)
        if os.path.isfile(fpath):
            p = parse_page(fpath, "")
            if p and p.get("type"):
                p["dir"] = ""
                pages.append(p)
    # Parse category subdirectories
    for category in sorted(os.listdir(WIKI_DIR)):
        cat_dir = os.path.join(WIKI_DIR, category)
        if not os.path.isdir(cat_dir):
            continue
        for fname in sorted(os.listdir(cat_dir)):
            if not fname.endswith(".md"):
                continue
            p = parse_page(os.path.join(cat_dir, fname), category)
            if p:
                pages.append(p)

print(f"Found {len(pages)} wiki pages.")

# Build slug -> page index for O(1) lookups
slug_map = {p["slug"]: p for p in pages}

# --- Compute inbound link counts ---
for p in pages:
    p["inbound"] = 0

for p in pages:
    for rel in p["related"]:
        rel_slug = os.path.splitext(os.path.basename(rel))[0]
        if rel_slug in slug_map:
            slug_map[rel_slug]["inbound"] += 1


def get_tier(count):
    if count == 0:  return 1
    if count == 1:  return 2
    if count <= 3:  return 3
    if count <= 6:  return 4
    if count <= 11: return 5
    if count <= 17: return 6
    return 7


def get_radius(tier):
    return {1: 5, 2: 8, 3: 12, 4: 17, 5: 23, 6: 30, 7: 40}[tier]


def get_thickness(weight):
    """Interpolate thickness from 1 (weight=1) to 15 (weight>=5)."""
    return round(1.0 + (min(weight, 5) - 1) * 3.5, 1)


# --- Determine types and assign colors ---
def sort_types(type_set):
    known = [t for t in KNOWN_TYPE_ORDER if t in type_set]
    extra = sorted(t for t in type_set if t not in KNOWN_TYPE_ORDER)
    return known + extra

unique_types = sort_types(set(p["type"] for p in pages if p["type"]))
type_colors = {t: PALETTE[i % len(PALETTE)] for i, t in enumerate(unique_types)}

print(f"Found {len(unique_types)} categories: {', '.join(unique_types)}")


# --- Build data.json ---
print("Building data.json...")

nodes = []
for p in pages:
    tier = get_tier(p["inbound"])
    nodes.append({
        "id": p["slug"],
        "title": p["title"],
        "type": p["type"],
        "confidence": p["confidence"],
        "created": p["created"],
        "tier": tier,
        "radius": get_radius(tier),
        "inbound": p["inbound"],
        "dir": p["dir"],
        "body_html": md_to_html(p["body"]),
    })

edges = []
seen_edges = set()
for p in pages:
    slug_a = p["slug"]
    sources_a = set(p["sources"])
    for rel in p["related"]:
        slug_b = os.path.splitext(os.path.basename(rel))[0]
        if slug_b not in slug_map:
            continue
        edge_key = tuple(sorted([slug_a, slug_b]))
        if edge_key in seen_edges:
            continue
        seen_edges.add(edge_key)
        sources_b = set(slug_map[slug_b]["sources"])
        weight = 1 + len(sources_a & sources_b)
        edges.append({
            "source": slug_a,
            "target": slug_b,
            "weight": weight,
            "thickness": get_thickness(weight),
        })

data = {"nodes": nodes, "edges": edges, "typeColors": type_colors}
with open(os.path.join(WEBSITE_DIR, "data.json"), "w") as f:
    json.dump(data, f, indent=2)

# Also write data.js so the graph works when opened via file:// without a server
with open(os.path.join(WEBSITE_DIR, "data.js"), "w") as f:
    f.write("// ABOUTME: Inlined wiki graph data for file:// compatibility.\n")
    f.write("// ABOUTME: Generated by build-site.sh — do not edit manually.\n")
    f.write("const WIKI_DATA = ")
    json.dump(data, f)
    f.write(";\n")

for cat_type in unique_types:
    cat_nodes = [n for n in nodes if n["type"] == cat_type]
    cat_data = {"nodes": cat_nodes, "typeColors": type_colors}
    with open(os.path.join(WEBSITE_DIR, f"data-{cat_type}.js"), "w") as f:
        f.write("// ABOUTME: Per-category wiki data for file:// compatibility.\n")
        f.write("// ABOUTME: Generated by build-site.sh — do not edit manually.\n")
        f.write("const WIKI_CAT_DATA = ")
        json.dump(cat_data, f)
        f.write(";\n")

print(f"Generated data.json with {len(nodes)} nodes and {len(edges)} edges.")

# --- Write wiki-css.css (only on first run, preserves user customizations) ---
css_path = os.path.join(WEBSITE_DIR, "wiki-css.css")
if css_backup is not None:
    with open(css_path, "w") as f:
        f.write(css_backup)
    print("wiki-css.css exists, preserving customizations.")
else:
    print("Generating wiki-css.css (first run)...")
    with open(css_path, "w") as f:
        f.write("""\
/* wiki-css.css — Design tokens and styles for wikifyskill static site.
 * Generated on first build. Edit freely — the build script will not overwrite.
 * Design language: Ethereal Glass (taste-skill) with minimalist typography.
 */

/* ── Fonts ── */
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
  /* ── Color Tokens ── */
  --color-bg:            #050505;
  --color-surface:       #0f1115;
  --color-surface-hover: #161a1f;
  --color-border:        rgba(255,255,255,0.08);
  --color-border-hover:  rgba(255,255,255,0.16);
  --color-text:          #e1e4e8;
  --color-text-muted:    #7a818a;
  --color-text-heading:  #f0f3f6;
  --color-accent:        #6cb4ee;
  --color-accent-hover:  #8dc8f8;

  /* ── Typography ── */
  --font-sans:     'Outfit', 'Satoshi', 'Cabinet Grotesk', system-ui, sans-serif;
  --font-mono:     'JetBrains Mono', 'Geist Mono', 'SF Mono', monospace;
  --tracking-tight: -0.025em;
  --tracking-wide:  0.05em;
  --leading-tight:  1.15;
  --leading-body:   1.65;

  /* ── Spacing ── */
  --nav-height:    52px;
  --container-max: 1100px;
  --page-max:      780px;
  --radius-sm:     6px;
  --radius-md:     10px;
  --radius-lg:     16px;
  --radius-xl:     24px;

  /* ── Shadows ── */
  --shadow-panel:   -6px 0 32px rgba(0,0,0,0.5);
  --shadow-tooltip: 0 12px 32px rgba(0,0,0,0.55);
  --shadow-card:    0 1px 3px rgba(0,0,0,0.2), 0 0 0 1px var(--color-border);
  --shadow-card-hover: 0 4px 16px rgba(0,0,0,0.3), 0 0 0 1px var(--color-border-hover);

  /* ── Transitions ── */
  --ease-out:  cubic-bezier(0.16, 1, 0.3, 1);
  --ease-spring: cubic-bezier(0.32, 0.72, 0, 1);
  --duration-fast: 180ms;
  --duration-normal: 280ms;
  --duration-slow: 450ms;
}

/* ── Reset ── */
*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

/* ── Base ── */
body {
  font-family: var(--font-sans);
  font-weight: 400;
  font-size: 15px;
  line-height: var(--leading-body);
  color: var(--color-text);
  background: var(--color-bg);
  overflow: hidden;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body.page-body {
  overflow: auto;
  min-height: 100dvh;
}

/* ── Navigation ── */
nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  height: var(--nav-height);
  background: rgba(5,5,5,0.85);
  border-bottom: 1px solid var(--color-border);
  padding: 0 24px;
  display: flex; align-items: center; gap: 8px;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

nav .logo {
  font-size: 16px; font-weight: 600;
  color: var(--color-text-heading);
  text-decoration: none;
  letter-spacing: var(--tracking-tight);
  margin-right: 16px;
}

nav a {
  color: var(--color-text-muted);
  text-decoration: none;
  font-size: 13px; font-weight: 500;
  padding: 5px 14px;
  border-radius: 9999px;
  transition: color var(--duration-fast) var(--ease-out),
              background var(--duration-fast) var(--ease-out);
}

nav a:hover {
  color: var(--color-text);
  background: rgba(255,255,255,0.06);
}

nav a.active {
  color: var(--color-text-heading);
  background: rgba(255,255,255,0.1);
}

/* ── Graph ── */
#graph-container {
  width: 100vw;
  height: 100dvh;
  padding-top: var(--nav-height);
}

/* ── Tooltip ── */
.tooltip {
  position: absolute;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 12px 16px;
  font-size: 13px;
  pointer-events: none;
  opacity: 0;
  transition: opacity var(--duration-fast) var(--ease-out);
  max-width: 300px;
  box-shadow: var(--shadow-tooltip);
}

.tooltip .tt-title {
  font-weight: 600; font-size: 14px;
  color: var(--color-text-heading);
  margin-bottom: 4px;
  letter-spacing: var(--tracking-tight);
}

.tooltip .tt-type {
  font-size: 10px; font-weight: 500;
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
}

.tooltip .tt-confidence {
  font-size: 11px; margin-top: 6px;
  color: var(--color-text-muted);
}

/* ── Side Panel ── */
#side-panel {
  position: fixed; top: var(--nav-height); right: 0;
  width: 33vw; min-width: 320px; max-width: 600px;
  height: calc(100dvh - var(--nav-height));
  background: var(--color-surface);
  border-left: 1px solid var(--color-border);
  transform: translateX(100%);
  transition: transform var(--duration-slow) var(--ease-spring);
  overflow-y: auto; z-index: 90;
  padding: 28px;
  box-shadow: var(--shadow-panel);
}

#side-panel.open { transform: translateX(0); }

#side-panel .panel-close {
  position: absolute; top: 14px; right: 14px;
  background: none; border: none;
  color: var(--color-text-muted);
  font-size: 18px; cursor: pointer;
  width: 32px; height: 32px;
  border-radius: 9999px;
  display: flex; align-items: center; justify-content: center;
  transition: background var(--duration-fast) var(--ease-out),
              color var(--duration-fast) var(--ease-out);
}

#side-panel .panel-close:hover {
  color: var(--color-text-heading);
  background: rgba(255,255,255,0.08);
}

#side-panel .panel-meta {
  display: flex; gap: 8px;
  margin-bottom: 20px; flex-wrap: wrap;
}

#side-panel .panel-body h1 {
  font-size: 22px; font-weight: 600;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  line-height: var(--leading-tight);
  margin: 20px 0 10px;
}

#side-panel .panel-body h2 {
  font-size: 17px; font-weight: 600;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  margin: 18px 0 8px;
}

#side-panel .panel-body h3 {
  font-size: 14px; font-weight: 600;
  color: var(--color-text-heading);
  margin: 14px 0 6px;
}

#side-panel .panel-body li {
  margin-left: 20px; margin-bottom: 6px;
}

#side-panel .panel-body code {
  background: rgba(255,255,255,0.06);
  padding: 2px 7px; border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 12.5px;
}

#side-panel .panel-body a { color: var(--color-accent); text-decoration: none; }
#side-panel .panel-body a:hover { color: var(--color-accent-hover); }

#side-panel .panel-body table { border-collapse: collapse; margin: 10px 0; width: 100%; }
#side-panel .panel-body td {
  border: 1px solid var(--color-border);
  padding: 8px 12px; text-align: left; font-size: 13px;
}

.panel-link {
  display: inline-block; margin-top: 16px;
  color: var(--color-accent);
  text-decoration: none; font-size: 13px; font-weight: 500;
  transition: color var(--duration-fast) var(--ease-out);
}
.panel-link:hover { color: var(--color-accent-hover); }

/* ── Category Pages ── */
.category-container {
  max-width: var(--container-max);
  margin: calc(var(--nav-height) + 32px) auto 48px;
  padding: 0 28px;
}

.category-header h1 {
  font-size: 32px; font-weight: 700;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  line-height: var(--leading-tight);
}

.category-header .count {
  font-size: 13px; font-weight: 500;
  color: var(--color-text-muted);
  margin-top: 6px;
}

#category-viz {
  width: 100%; height: 400px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  margin-bottom: 28px;
}

.page-list { list-style: none; }

.page-list li {
  padding: 14px 18px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  margin-bottom: 8px;
  background: var(--color-surface);
  display: flex; justify-content: space-between; align-items: center;
  transition: border-color var(--duration-fast) var(--ease-out),
              box-shadow var(--duration-fast) var(--ease-out);
}

.page-list li:hover {
  border-color: var(--color-border-hover);
  box-shadow: var(--shadow-card-hover);
}

.page-list a {
  color: var(--color-accent);
  text-decoration: none; font-weight: 500;
  transition: color var(--duration-fast) var(--ease-out);
}

.page-list a:hover { color: var(--color-accent-hover); }

.page-list .meta {
  font-size: 12px; font-weight: 500;
  color: var(--color-text-muted);
  display: flex; gap: 14px;
  font-variant-numeric: tabular-nums;
}

/* ── Individual Pages ── */
.page-container {
  max-width: var(--page-max);
  margin: calc(var(--nav-height) + 32px) auto 48px;
  padding: 0 28px;
}

.page-title {
  font-size: 36px;
  font-weight: 700;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  line-height: var(--leading-tight);
  margin-bottom: 16px;
}

.page-container .page-meta {
  display: flex; gap: 8px;
  margin-bottom: 24px; flex-wrap: wrap;
}

/* ── Badges ── */
.badge {
  font-size: 10px; font-weight: 600;
  padding: 3px 10px;
  border-radius: 9999px;
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
}

.badge-confidence { background: rgba(255,255,255,0.05); color: #7a818a; }

/* ── Content Typography ── */
.page-container .content h1,
#side-panel .panel-body h1 {
  font-size: 28px; font-weight: 700;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  line-height: var(--leading-tight);
  margin: 24px 0 12px;
}

.page-container .content h2 {
  font-size: 20px; font-weight: 600;
  color: var(--color-text-heading);
  letter-spacing: var(--tracking-tight);
  margin: 20px 0 10px;
}

.page-container .content h3 {
  font-size: 16px; font-weight: 600;
  color: var(--color-text-heading);
  margin: 16px 0 8px;
}

.page-container .content li {
  margin-left: 22px; margin-bottom: 6px;
}

.page-container .content code {
  background: rgba(255,255,255,0.06);
  padding: 2px 7px; border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 13px;
}

.page-container .content a { color: var(--color-accent); text-decoration: none; }
.page-container .content a:hover { color: var(--color-accent-hover); }

.page-container .content table {
  border-collapse: collapse;
  margin: 14px 0; width: 100%;
}

.page-container .content td {
  border: 1px solid var(--color-border);
  padding: 10px 14px; text-align: left; font-size: 14px;
}

/* ── Scroll Entry Animation ── */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(12px); }
  to   { opacity: 1; transform: translateY(0); }
}

.page-container .content,
.category-container .page-list li {
  animation: fadeInUp 600ms var(--ease-out) both;
}

.category-container .page-list li:nth-child(n) {
  animation-delay: calc((var(--i, 0)) * 60ms);
}

/* ── Breadcrumb ── */
.breadcrumb { margin-bottom: 16px; }
.breadcrumb a { color: var(--color-text-muted); font-size: 13px; text-decoration: none; transition: color var(--duration-fast) var(--ease-out); }
.breadcrumb a:hover { color: var(--color-text); }

/* ── Responsive ── */
@media (max-width: 768px) {
  #side-panel { width: 100%; }
  .category-container, .page-container { padding: 0 16px; }
  nav { padding: 0 12px; gap: 4px; }
  nav a { font-size: 12px; padding: 4px 8px; }
}
""")

# --- Write graph.js ---
with open(os.path.join(WEBSITE_DIR, "graph.js"), "w") as f:
    f.write("""\
// ABOUTME: D3.js force-directed graph for the wikifyskill landing page.
// ABOUTME: Handles node sizing by tier, edge weight/thickness, hover, right-click panel, drag, zoom.
const TYPE_COLORS = (typeof WIKI_DATA !== 'undefined') ? WIKI_DATA.typeColors : {};

async function initGraph() {
  const data = (typeof WIKI_DATA !== 'undefined') ? WIKI_DATA : await (await fetch('data.json')).json();
  const container = document.getElementById('graph-container');
  const width = container.clientWidth, height = container.clientHeight;

  const svg = d3.select('#graph-container').append('svg').attr('width', width).attr('height', height);
  const g = svg.append('g');
  svg.call(d3.zoom().scaleExtent([0.2, 5]).on('zoom', e => g.attr('transform', e.transform)));

  const tooltip = d3.select('.tooltip');
  const simulation = d3.forceSimulation(data.nodes)
    .force('link', d3.forceLink(data.edges).id(d => d.id).distance(d => 120 / Math.sqrt(d.weight)))
    .force('charge', d3.forceManyBody().strength(-200))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force('collision', d3.forceCollide().radius(d => d.radius + 4))
    .alphaDecay(0.03).alphaMin(0.001);

  const neighbors = new Map();
  data.nodes.forEach(n => neighbors.set(n.id, new Set()));
  data.edges.forEach(e => {
    const sid = typeof e.source === 'object' ? e.source.id : e.source;
    const tid = typeof e.target === 'object' ? e.target.id : e.target;
    neighbors.get(sid)?.add(tid);
    neighbors.get(tid)?.add(sid);
  });

  const link = g.append('g').selectAll('line').data(data.edges).join('line')
    .attr('stroke', '#30363d').attr('stroke-width', d => d.thickness).attr('stroke-opacity', 0.6);

  const node = g.append('g').selectAll('circle').data(data.nodes).join('circle')
    .attr('r', d => d.radius).attr('fill', d => TYPE_COLORS[d.type] || '#8b949e')
    .attr('stroke', '#0d1117').attr('stroke-width', 1.5).attr('cursor', 'pointer')
    .call(d3.drag().on('start', ds).on('drag', dd).on('end', de));

  const labels = g.append('g').selectAll('text').data(data.nodes.filter(d => d.tier >= 3)).join('text')
    .text(d => d.title).attr('font-size', d => d.tier >= 5 ? 12 : 10).attr('fill', '#c9d1d9')
    .attr('text-anchor', 'middle').attr('dy', d => d.radius + 14).attr('pointer-events', 'none').attr('opacity', 0.8);

  document.getElementById('graph-search')?.addEventListener('input', e => {
    const q = e.target.value.toLowerCase();
    node.attr('opacity', d => !q || d.title.toLowerCase().includes(q) ? 1 : 0.08);
    labels.attr('opacity', d => !q || d.title.toLowerCase().includes(q) ? 0.8 : 0.05);
  });

  node.on('mouseover', function(event, d) {
    tooltip.style('opacity', 1).html(
      '<div class="tt-title">' + d.title + '</div>' +
      '<div class="tt-type" style="color:' + (TYPE_COLORS[d.type] || '#8b949e') + '">' + d.type + '</div>' +
      '<div class="tt-confidence">confidence: ' + d.confidence + ' \\u00B7 ' + d.inbound + ' inbound links</div>'
    ).style('left', (event.pageX + 14) + 'px').style('top', (event.pageY - 10) + 'px');
    link.attr('stroke-opacity', l => (l.source.id === d.id || l.target.id === d.id) ? 1 : 0.1)
      .attr('stroke', l => (l.source.id === d.id || l.target.id === d.id) ? '#58a6ff' : '#30363d');
    node.attr('opacity', n => {
      if (n.id === d.id) return 1;
      return n.id === d.id || neighbors.get(d.id)?.has(n.id) ? 1 : 0.2;
    });
  }).on('mousemove', function(event) {
    tooltip.style('left', (event.pageX+14)+'px').style('top', (event.pageY-10)+'px');
  }).on('mouseout', function() {
    tooltip.style('opacity', 0); link.attr('stroke-opacity', 0.6).attr('stroke', '#30363d'); node.attr('opacity', 1);
  });

  node.on('click', (e, d) => { e.stopPropagation(); openPanel(d); });
  node.on('dblclick', (e, d) => { e.stopPropagation(); window.location.href = 'pages/' + d.id + '.html'; });
  node.on('contextmenu', (e, d) => { e.preventDefault(); openPanel(d); });

  simulation.on('tick', () => {
    link.attr('x1', d=>d.source.x).attr('y1', d=>d.source.y).attr('x2', d=>d.target.x).attr('y2', d=>d.target.y);
    node.attr('cx', d=>d.x).attr('cy', d=>d.y);
    labels.attr('x', d=>d.x).attr('y', d=>d.y);
  });

  function ds(e, d) { if (!e.active) simulation.alphaTarget(0.3).restart(); d.fx=d.x; d.fy=d.y; }
  function dd(e, d) { d.fx=e.x; d.fy=e.y; }
  function de(e, d) { if (!e.active) simulation.alphaTarget(0); d.fx=null; d.fy=null; }
}

function openPanel(nd) {
  const panel = document.getElementById('side-panel');
  const node = data.nodes.find(n => n.id === nd.id);
  const color = TYPE_COLORS[node.type] || '#8b949e';
  panel.querySelector('.panel-meta').innerHTML =
    '<span class="badge" style="background:' + color + '1f;color:' + color + '">' + (node.type||'') + '</span>' +
    '<span class="badge badge-confidence">confidence: ' + (node.confidence||'') + '</span>';
  panel.querySelector('.panel-body').innerHTML = (node && node.body_html) ? node.body_html : '<p>No content.</p>';
  const pl = panel.querySelector('.panel-link');
  if (pl) pl.href = 'pages/' + nd.id + '.html';
  panel.classList.add('open');
}
function closePanel() { document.getElementById('side-panel').classList.remove('open'); }
document.addEventListener('click', e => {
  const p = document.getElementById('side-panel');
  if (p.classList.contains('open') && !p.contains(e.target)) closePanel();
});
document.addEventListener('DOMContentLoaded', initGraph);
""")

# --- Write category.js ---
with open(os.path.join(WEBSITE_DIR, "category.js"), "w") as f:
    f.write("""\
// ABOUTME: D3.js visualizations for category pages (bubble charts and timelines).
// ABOUTME: Renders bubble chart sized by inbound links, colored by confidence.
const TYPE_COLORS = (typeof WIKI_CAT_DATA !== 'undefined') ? WIKI_CAT_DATA.typeColors :
                    (typeof WIKI_DATA !== 'undefined') ? WIKI_DATA.typeColors : {};
const CONF_OP = { 'high': 1.0, 'medium': 0.65, 'low': 0.35 };

// Module-level reference so highlightVizNode/clearVizHighlight can reach the D3 selection.
let vizNodes = null;

async function initCategoryViz(catType) {
  const data = (typeof WIKI_CAT_DATA !== 'undefined') ? WIKI_CAT_DATA :
               (typeof WIKI_DATA !== 'undefined') ? WIKI_DATA :
               await (await fetch('../data.json')).json();
  const nodes = data.nodes.filter(n => n.type === catType);
  if (!nodes.length) return;
  const el = document.getElementById('category-viz');
  const w = el.clientWidth, h = el.clientHeight;
  if (catType === 'source-summary') renderTimeline(el, nodes, w, h, catType);
  else renderBubble(el, nodes, w, h, catType);
}

function renderBubble(el, nodes, w, h, catType) {
  const color = TYPE_COLORS[catType] || '#8b949e';
  const pack = d3.pack().size([w-40, h-40]).padding(6);
  const root = d3.hierarchy({children: nodes}).sum(d => (d.inbound||0)+1);
  pack(root);
  const svg = d3.select(el).append('svg').attr('width', w).attr('height', h);
  const g = svg.append('g').attr('transform', 'translate(20,20)');
  const nd = g.selectAll('g').data(root.leaves()).join('g')
    .attr('transform', d => 'translate('+d.x+','+d.y+')').attr('cursor','pointer')
    .on('click', (e,d) => { expandItem(d.data.id); });
  nd.append('circle').attr('r', d=>d.r).attr('fill', color)
    .attr('fill-opacity', d=>CONF_OP[d.data.confidence]||0.5).attr('stroke', color).attr('stroke-width', 1);
  nd.filter(d=>d.r>24).append('text').text(d=>d.data.title).attr('text-anchor','middle')
    .attr('dy','0.35em').attr('fill','#f0f6fc').attr('font-size', d=>Math.min(d.r/3,14)).attr('pointer-events','none');
  vizNodes = { sel: nd, getId: d => d.data.id, color };
}

function renderTimeline(el, nodes, w, h, catType) {
  const color = TYPE_COLORS[catType] || '#8b949e';
  const m = {top:30,right:30,bottom:40,left:30};
  nodes.sort((a,b)=>(a.created||'').localeCompare(b.created||''));
  const svg = d3.select(el).append('svg').attr('width',w).attr('height',h);
  const dates = nodes.map(n=>new Date(n.created)).filter(d=>!isNaN(d));
  if (!dates.length) return;
  const x = d3.scaleTime().domain(d3.extent(dates)).range([m.left,w-m.right]);
  svg.append('g').attr('transform','translate(0,'+(h-m.bottom)+')').call(d3.axisBottom(x).ticks(6)).selectAll('text').attr('fill','#8b949e');
  svg.append('line').attr('x1',m.left).attr('x2',w-m.right).attr('y1',h/2).attr('y2',h/2).attr('stroke','#30363d');
  const nd = svg.selectAll('g.node').data(nodes).join('g')
    .attr('transform',(d,i)=>'translate('+x(new Date(d.created))+','+(h/2+(i%2===0?-40:40))+')')
    .attr('cursor','pointer').on('click',(e,d)=>{ expandItem(d.id); });
  nd.append('circle').attr('r',d=>d.radius||8).attr('fill',color).attr('fill-opacity',d=>CONF_OP[d.confidence]||0.5);
  nd.filter(d=>(d.radius||8)>6).append('text').text(d=>d.title.length>20?d.title.substring(0,18)+'...':d.title)
    .attr('text-anchor','middle').attr('dy',(d,i)=>i%2===0?-14:20).attr('fill','#c9d1d9').attr('font-size',11);
  vizNodes = { sel: nd, getId: d => d.id, color };
}

function highlightVizNode(slug) {
  if (!vizNodes) return;
  const { sel, getId, color } = vizNodes;
  sel.select('circle')
    .transition().duration(200)
    .attr('stroke', d => getId(d) === slug ? '#ffffff' : color)
    .attr('stroke-width', d => getId(d) === slug ? 2.5 : 1)
    .attr('opacity', d => getId(d) === slug ? 1 : 0.25);
}

function clearVizHighlight() {
  if (!vizNodes) return;
  const { sel, color } = vizNodes;
  sel.select('circle')
    .transition().duration(200)
    .attr('stroke', color)
    .attr('stroke-width', 1)
    .attr('opacity', 1);
}

function expandItem(slug) {
  document.querySelectorAll('.cat-item').forEach(el => el.classList.remove('expanded'));
  const item = document.getElementById('item-' + slug);
  if (!item) return;
  item.classList.add('expanded');
  item.scrollIntoView({ behavior: 'smooth', block: 'start' });
  highlightVizNode(slug);
}

function toggleItem(slug) {
  const item = document.getElementById('item-' + slug);
  if (!item) return;
  if (item.classList.contains('expanded')) {
    item.classList.remove('expanded');
    clearVizHighlight();
  } else {
    expandItem(slug);
  }
}

function filterItems(term) {
  const q = term.toLowerCase();
  document.querySelectorAll('.cat-item').forEach(el => {
    const title = el.querySelector('.cat-item-title');
    el.style.display = (!q || (title && title.textContent.toLowerCase().includes(q))) ? '' : 'none';
  });
}
""")


# --- Nav and badge helpers ---
TYPE_LABELS = {
    'source-summary': 'Sources (by ingest date)',
    'learning-plan': 'Learning Plan',
}

def make_nav(types, type_colors, active_type=None, depth=0):
    prefix = "../" * depth
    links = [f'<a href="{prefix}index.html" class="logo">Wiki Graph</a>']
    for t in types:
        label = TYPE_LABELS.get(t, t.replace("-", " ").title())
        active = ' class="active"' if t == active_type else ""
        # learning-plan pages link directly to their page, not a category listing
        if t == 'learning-plan':
            links.append(f'<a href="{prefix}pages/learning_plan.html"{active}>{label}</a>')
        else:
            links.append(f'<a href="{prefix}categories/{t}.html"{active}>{label}</a>')
    return "\n    ".join(links)


def badge_html(type_name, type_colors):
    color = type_colors.get(type_name, "#8b949e")
    return f'<span class="badge" style="background:{color}1f;color:{color};">{html_escape(type_name)}</span>'


# --- Generate index.html ---
print("Generating index.html...")
nav_html = make_nav(unique_types, type_colors, depth=0)
with open(os.path.join(WEBSITE_DIR, "index.html"), "w") as f:
    f.write(f"""\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Wiki Graph</title>
  <link rel="stylesheet" href="wiki-css.css">
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <script src="data.js"></script>
</head>
<body>
  <nav>
    {nav_html}
    <input id="graph-search" type="text" placeholder="Search nodes..." style="margin-left:auto;padding:4px 10px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.12);border-radius:9999px;color:#e1e4e8;font-size:12px;font-family:inherit;outline:none;">
  </nav>
  <div id="graph-container"></div>
  <div class="tooltip"></div>
  <div id="side-panel">
    <button class="panel-close" onclick="closePanel()">&times;</button>
    <div class="panel-meta"></div>
    <div class="panel-body"></div>
    <a class="panel-link" href="#">Open full page (or double-click node) &rarr;</a>
  </div>
  <script src="graph.js"></script>
</body>
</html>
""")

# --- Generate category pages ---
print("Generating category pages...")

for cat_type in unique_types:
    cat_pages = [p for p in pages if p["type"] == cat_type]
    list_items = []
    for p in cat_pages:
        body_html = md_to_html(p["body"])
        list_items.append(
            f'<li id="item-{p["slug"]}" class="cat-item">'
            f'<div class="cat-item-header" onclick="toggleItem(\'{p["slug"]}\')">'
            f'<span class="cat-item-title">{html_escape(p["title"])}</span>'
            f'<span class="cat-item-arrow">&#9654;</span>'
            f'</div>'
            f'<div class="cat-item-body content">'
            f'<div class="cat-item-meta">'
            f'<span>confidence: {p["confidence"]}</span>'
            f'<span>{p["created"]}</span>'
            f'</div>'
            f'{body_html}'
            f'<a class="cat-item-link" href="../pages/{p["slug"]}.html">Open full page &rarr;</a>'
            f'</div>'
            f'</li>'
        )
    list_html = "\n".join(list_items)
    cat_name = cat_type.replace("-", " ").title()
    nav_html = make_nav(unique_types, type_colors, active_type=cat_type, depth=1)
    with open(os.path.join(WEBSITE_DIR, "categories", f"{cat_type}.html"), "w") as f:
        f.write(f"""\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{cat_name} — Wiki</title>
  <link rel="stylesheet" href="../wiki-css.css">
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <script src="../data-{cat_type}.js"></script>
  <style>
    .cat-layout {{
      display: flex;
      gap: 24px;
      align-items: flex-start;
      margin-top: calc(var(--nav-height) + 24px);
      padding: 0 28px 48px;
      max-width: var(--container-max);
      margin-left: auto;
      margin-right: auto;
    }}
    .cat-list {{
      flex: 0 0 42%;
      max-height: calc(100dvh - var(--nav-height) - 80px);
      overflow-y: auto;
      padding-right: 8px;
    }}
    .cat-chart {{
      flex: 1;
      position: sticky;
      top: calc(var(--nav-height) + 16px);
    }}
    #category-viz {{
      height: calc(100dvh - var(--nav-height) - 80px);
      margin-bottom: 0;
    }}
    .cat-item {{
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      margin-bottom: 6px;
      background: var(--color-surface);
      transition: border-color 180ms;
    }}
    .cat-item:hover {{ border-color: var(--color-border-hover); }}
    .cat-item.expanded {{ border-color: var(--color-border-hover); }}
    .cat-item-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      cursor: pointer;
      gap: 12px;
    }}
    .cat-item-title {{
      color: var(--color-text);
      font-weight: 500;
      font-size: 14px;
      flex: 1;
    }}
    .cat-item:hover .cat-item-title {{ color: var(--color-text-heading); }}
    .cat-item.expanded .cat-item-title {{ color: var(--color-accent); }}
    .cat-item-meta {{
      display: flex; gap: 16px;
      font-size: 11px; font-weight: 500;
      color: var(--color-text-muted);
      margin-bottom: 10px;
    }}
    .cat-item-link {{
      display: inline-block;
      margin-top: 12px;
      color: var(--color-accent);
      text-decoration: none;
      font-size: 12px; font-weight: 500;
    }}
    .cat-item-link:hover {{ color: var(--color-accent-hover); }}
    .cat-item-arrow {{
      color: var(--color-text-muted);
      font-size: 10px;
      transition: transform 200ms;
      display: inline-block;
    }}
    .cat-item.expanded .cat-item-arrow {{ transform: rotate(90deg); }}
    .cat-item-body {{
      display: none;
      padding: 0 16px 16px;
      font-size: 13px;
      line-height: 1.6;
      border-top: 1px solid var(--color-border);
    }}
    .cat-item.expanded .cat-item-body {{ display: block; }}
    .cat-header {{
      padding: 0 0 16px;
    }}
    .cat-header h1 {{
      font-size: 28px;
      font-weight: 700;
      color: var(--color-text-heading);
      letter-spacing: -0.025em;
    }}
    .cat-header .count {{
      font-size: 13px;
      color: var(--color-text-muted);
      margin-top: 4px;
    }}
    @media (max-width: 768px) {{
      .cat-layout {{ flex-direction: column; padding: 0 16px 48px; }}
      .cat-list {{ max-height: none; flex: none; width: 100%; }}
      .cat-chart {{ position: static; width: 100%; }}
      #category-viz {{ height: 300px; }}
    }}
    #cat-filter {{
      width: 100%;
      padding: 8px 12px;
      margin-bottom: 12px;
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      color: var(--color-text);
      font-size: 13px;
      font-family: var(--font-sans);
    }}
    #cat-filter:focus {{ outline: none; border-color: var(--color-border-hover); }}
  </style>
</head>
<body class="page-body">
  <nav>
    {nav_html}
  </nav>
  <div class="cat-layout">
    <div class="cat-list">
      <div class="cat-header">
        <h1>{cat_name}</h1>
        <div class="count">{len(cat_pages)} pages</div>
      </div>
      <input id="cat-filter" type="text" placeholder="Filter {cat_name}..." oninput="filterItems(this.value)">
      <ul class="page-list" style="list-style:none;">
        {list_html}
      </ul>
    </div>
    <div class="cat-chart">
      <div id="category-viz"></div>
    </div>
  </div>
  <div class="tooltip"></div>
  <script src="../category.js"></script>
  <script>initCategoryViz('{cat_type}');</script>
</body>
</html>
""")

# --- Generate individual pages ---
print("Generating individual pages...")
for p in pages:
    body_html = md_to_html(p["body"])
    related_html = ""
    if p["related"]:
        items = []
        for rel in p["related"]:
            rel_slug = os.path.splitext(os.path.basename(rel))[0]
            rel_title = slug_map[rel_slug]["title"] if rel_slug in slug_map else rel_slug
            items.append(f'<li><a href="{rel_slug}.html">{html_escape(rel_title)}</a></li>')
        related_html = "<h3>Related Pages</h3><ul>" + "".join(items) + "</ul>"

    if p["dir"]:
        cat_label = TYPE_LABELS.get(p["type"], p["type"].replace("-", " ").title())
        breadcrumb_html = f'<nav class="breadcrumb"><a href="../categories/{p["type"]}.html">\u2190 {cat_label}</a></nav>'
    else:
        breadcrumb_html = '<nav class="breadcrumb"><a href="../index.html">\u2190 Graph</a></nav>'
    title_esc = html_escape(p["title"])
    type_badge = badge_html(p["type"], type_colors)
    nav_html = make_nav(unique_types, type_colors, depth=1)
    with open(os.path.join(WEBSITE_DIR, "pages", f'{p["slug"]}.html'), "w") as f:
        f.write(f"""\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title_esc} — Wiki</title>
  <link rel="stylesheet" href="../wiki-css.css">
</head>
<body class="page-body">
  <nav>
    {nav_html}
  </nav>
  <div class="page-container">
    {breadcrumb_html}
    <h1 class="page-title">{title_esc}</h1>
    <div class="page-meta">
      {type_badge}
      <span class="badge badge-confidence">confidence: {p['confidence']}</span>
      <span class="badge badge-confidence">{p['created']}</span>
    </div>
    <div class="content">{body_html}</div>
    {related_html}
  </div>
</body>
</html>
""")

print(f"\nSite built successfully in {WEBSITE_DIR}/")
print(f"  {len(pages)} pages, {len(edges)} edges, {len(unique_types)} categories")
print(f"  Open {WEBSITE_DIR}/index.html in a browser to view.")
