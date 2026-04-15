#!/usr/bin/env bash
# ABOUTME: Builds a static website from wiki/ folder with D3.js force graph.
# ABOUTME: Generates data.json, index.html, category pages, and individual page HTML.

set -e

WIKI_DIR="${1:-wiki}"
WEBSITE_DIR="${2:-website}"

if [ ! -d "$WIKI_DIR" ]; then
  echo "Error: wiki directory not found at '$WIKI_DIR'"
  echo "Usage: build-site.sh [wiki-dir] [output-dir]"
  exit 1
fi

# Clean generated files but preserve wiki-css.css (user may have customized it)
if [ -d "$WEBSITE_DIR" ]; then
  # Save wiki-css.css if it exists
  if [ -f "$WEBSITE_DIR/wiki-css.css" ]; then
    cp "$WEBSITE_DIR/wiki-css.css" "$WEBSITE_DIR/wiki-css.css.bak"
  fi
  rm -rf "$WEBSITE_DIR/categories" "$WEBSITE_DIR/pages" "$WEBSITE_DIR/data.json" \
         "$WEBSITE_DIR/graph.js" "$WEBSITE_DIR/category.js" "$WEBSITE_DIR/index.html"
  # Restore wiki-css.css
  if [ -f "$WEBSITE_DIR/wiki-css.css.bak" ]; then
    mv "$WEBSITE_DIR/wiki-css.css.bak" "$WEBSITE_DIR/wiki-css.css"
  fi
fi
mkdir -p "$WEBSITE_DIR/categories" "$WEBSITE_DIR/pages"

TMPWORK=$(mktemp -d)
trap "rm -rf $TMPWORK" EXIT

# --- Parse frontmatter from a single markdown file ---
parse_page() {
  local file="$1"
  local outfile="$2"
  local in_fm=0
  local fm_count=0
  local title="" type="" confidence="" created="" updated=""
  local collecting=""
  local sources="" related=""
  local body=""
  local in_body=0
  local slug
  slug=$(basename "$file" .md)

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "---" ]; then
      fm_count=$((fm_count + 1))
      if [ "$fm_count" -eq 1 ]; then in_fm=1; continue; fi
      if [ "$fm_count" -eq 2 ]; then in_fm=0; in_body=1; continue; fi
    fi
    if [ "$in_fm" -eq 1 ]; then
      case "$line" in
        "title: "*) title="${line#title: }"; collecting="" ;;
        "type: "*) type="${line#type: }"; collecting="" ;;
        "confidence: "*) confidence="${line#confidence: }"; collecting="" ;;
        "created: "*) created="${line#created: }"; collecting="" ;;
        "updated: "*) updated="${line#updated: }"; collecting="" ;;
        "sources:") collecting="sources" ;;
        "related:") collecting="related" ;;
        "  - "*)
          local val="${line#  - }"
          if [ "$collecting" = "sources" ]; then
            sources="${sources:+$sources,}$val"
          elif [ "$collecting" = "related" ]; then
            related="${related:+$related,}$val"
          fi
          ;;
        *) collecting="" ;;
      esac
    fi
    if [ "$in_body" -eq 1 ]; then
      body="${body}${line}
"
    fi
  done < "$file"

  [ -z "$title" ] && return 1

  # Write parsed data to temp files
  echo "$title" > "$outfile.title"
  echo "$type" > "$outfile.type"
  echo "$confidence" > "$outfile.confidence"
  echo "$created" > "$outfile.created"
  echo "$updated" > "$outfile.updated"
  echo "$sources" > "$outfile.sources"
  echo "$related" > "$outfile.related"
  echo "$slug" > "$outfile.slug"
  echo "$body" | md_to_html > "$outfile.body"
  return 0
}

md_to_html() {
  sed -E \
    -e 's/^#### (.+)/<h4>\1<\/h4>/' \
    -e 's/^### (.+)/<h3>\1<\/h3>/' \
    -e 's/^## (.+)/<h2>\1<\/h2>/' \
    -e 's/^# (.+)/<h1>\1<\/h1>/' \
    -e 's/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g' \
    -e 's/\*([^*]+)\*/<em>\1<\/em>/g' \
    -e 's/`([^`]+)`/<code>\1<\/code>/g' \
    -e 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g' \
    -e 's/^- (.+)/<li>\1<\/li>/' \
    -e '/^$/s/.*/<br>/'
}

# --- Collect all pages ---
echo "Parsing wiki pages..."
PAGE_COUNT=0
PAGE_IDS=""

for dir in concepts entities sources comparisons; do
  if [ -d "$WIKI_DIR/$dir" ]; then
    for file in "$WIKI_DIR/$dir"/*.md; do
      [ -f "$file" ] || continue
      local_id="page_${PAGE_COUNT}"
      if parse_page "$file" "$TMPWORK/$local_id"; then
        echo "$dir" > "$TMPWORK/$local_id.dir"
        PAGE_IDS="${PAGE_IDS} ${local_id}"
        PAGE_COUNT=$((PAGE_COUNT + 1))
      fi
    done
  fi
done

echo "Found $PAGE_COUNT wiki pages."

# --- Compute inbound link counts ---
for pid in $PAGE_IDS; do
  echo "0" > "$TMPWORK/$pid.inbound"
done

for pid in $PAGE_IDS; do
  related=$(cat "$TMPWORK/$pid.related")
  # Split related on commas using tr
  echo "$related" | tr ',' '\n' | while read -r rel; do
    [ -z "$rel" ] && continue
    rel_slug=$(basename "$rel" .md)
    for pid2 in $PAGE_IDS; do
      s2=$(cat "$TMPWORK/$pid2.slug")
      if [ "$s2" = "$rel_slug" ]; then
        cur=$(cat "$TMPWORK/$pid2.inbound")
        echo $((cur + 1)) > "$TMPWORK/$pid2.inbound"
        break
      fi
    done
  done
done

get_tier() {
  local count=$1
  if [ "$count" -le 1 ]; then echo 1
  elif [ "$count" -le 3 ]; then echo 2
  elif [ "$count" -le 6 ]; then echo 3
  elif [ "$count" -le 10 ]; then echo 4
  else echo 5; fi
}

get_radius() {
  case "$1" in
    1) echo 6 ;; 2) echo 10 ;; 3) echo 16 ;; 4) echo 24 ;; 5) echo 34 ;;
  esac
}

# --- Build data.json ---
echo "Building data.json..."

# Nodes
node_first=1
printf '{\n  "nodes": [' > "$WEBSITE_DIR/data.json"

for pid in $PAGE_IDS; do
  slug=$(cat "$TMPWORK/$pid.slug")
  title=$(cat "$TMPWORK/$pid.title" | sed 's/"/\\"/g')
  type=$(cat "$TMPWORK/$pid.type")
  confidence=$(cat "$TMPWORK/$pid.confidence")
  created=$(cat "$TMPWORK/$pid.created")
  inbound=$(cat "$TMPWORK/$pid.inbound")
  dir=$(cat "$TMPWORK/$pid.dir")
  tier=$(get_tier "$inbound")
  radius=$(get_radius "$tier")

  [ "$node_first" -eq 1 ] && node_first=0 || printf ',' >> "$WEBSITE_DIR/data.json"

  cat >> "$WEBSITE_DIR/data.json" << NODEJSON

    {
      "id": "${slug}",
      "title": "${title}",
      "type": "${type}",
      "confidence": "${confidence}",
      "created": "${created}",
      "tier": ${tier},
      "radius": ${radius},
      "inbound": ${inbound},
      "dir": "${dir}"
    }
NODEJSON
done

printf '\n  ],\n  "edges": [' >> "$WEBSITE_DIR/data.json"

# Edges
EDGE_COUNT=0
edge_first=1
echo "" > "$TMPWORK/edge_seen"

for pid in $PAGE_IDS; do
  slug_a=$(cat "$TMPWORK/$pid.slug")
  sources_a=$(cat "$TMPWORK/$pid.sources")
  related=$(cat "$TMPWORK/$pid.related")

  echo "$related" | tr ',' '\n' | while read -r rel; do
    [ -z "$rel" ] && continue
    slug_b=$(basename "$rel" .md)

    # Check target exists
    found_pid=""
    for pid2 in $PAGE_IDS; do
      s2=$(cat "$TMPWORK/$pid2.slug")
      if [ "$s2" = "$slug_b" ]; then
        found_pid="$pid2"
        break
      fi
    done
    [ -z "$found_pid" ] && continue

    # Deduplicate
    edge_key=$(printf '%s\n%s' "$slug_a" "$slug_b" | sort | tr '\n' '-')
    if grep -q "^${edge_key}$" "$TMPWORK/edge_seen" 2>/dev/null; then
      continue
    fi
    echo "$edge_key" >> "$TMPWORK/edge_seen"

    # Compute weight from shared sources
    sources_b=$(cat "$TMPWORK/$found_pid.sources")
    weight=1
    echo "$sources_a" | tr ',' '\n' | while read -r sa; do
      [ -z "$sa" ] && continue
      echo "$sources_b" | tr ',' '\n' | while read -r sb; do
        [ -z "$sb" ] && continue
        if [ "$sa" = "$sb" ]; then
          cur_w=$(cat "$TMPWORK/cur_weight" 2>/dev/null || echo 0)
          echo $((cur_w + 1)) > "$TMPWORK/cur_weight"
        fi
      done
    done
    extra_w=$(cat "$TMPWORK/cur_weight" 2>/dev/null || echo 0)
    rm -f "$TMPWORK/cur_weight"
    weight=$((weight + extra_w))

    thickness=$weight
    [ "$thickness" -gt 5 ] && thickness=5

    # Write edge to temp file (subshell can't modify parent vars)
    cat >> "$TMPWORK/edges_out" << EDGEJSON
{
      "source": "${slug_a}",
      "target": "${slug_b}",
      "weight": ${weight},
      "thickness": ${thickness}
    }
EDGEJSON
  done
done

# Read edges from temp file into data.json
if [ -f "$TMPWORK/edges_out" ]; then
  while IFS= read -r eline; do
    # Skip empty lines
    [ -z "$eline" ] && continue
    if echo "$eline" | grep -q '"source"'; then
      [ "$edge_first" -eq 1 ] && edge_first=0 || printf ',' >> "$WEBSITE_DIR/data.json"
      EDGE_COUNT=$((EDGE_COUNT + 1))
    fi
    printf '\n    %s' "$eline" >> "$WEBSITE_DIR/data.json"
  done < "$TMPWORK/edges_out"
fi

printf '\n  ]\n}\n' >> "$WEBSITE_DIR/data.json"

echo "Generated data.json with $PAGE_COUNT nodes and $EDGE_COUNT edges."

# --- Generate wiki-css.css (only on first run, preserves user customizations) ---
if [ ! -f "$WEBSITE_DIR/wiki-css.css" ]; then
  echo "Generating wiki-css.css (first run)..."
  cat > "$WEBSITE_DIR/wiki-css.css" << 'ENDCSS'
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

  /* ── Category Colors ── */
  --color-concept:         #5b9bd5;
  --color-concept-bg:      rgba(91,155,213,0.12);
  --color-entity:          #66c29a;
  --color-entity-bg:       rgba(102,194,154,0.12);
  --color-source-summary:       #d4a054;
  --color-source-summary-bg:    rgba(212,160,84,0.12);
  --color-comparison:      #9a7ec4;
  --color-comparison-bg:   rgba(154,126,196,0.12);

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
  width: 440px; height: calc(100dvh - var(--nav-height));
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

.badge-concept       { background: var(--color-concept-bg);    color: var(--color-concept); }
.badge-entity        { background: var(--color-entity-bg);     color: var(--color-entity); }
.badge-source-summary { background: var(--color-source-summary-bg); color: var(--color-source-summary); }
.badge-comparison    { background: var(--color-comparison-bg); color: var(--color-comparison); }
.badge-confidence    { background: rgba(255,255,255,0.05);     color: var(--color-text-muted); }

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

/* ── Responsive ── */
@media (max-width: 768px) {
  #side-panel { width: 100%; }
  .category-container, .page-container { padding: 0 16px; }
  nav { padding: 0 12px; gap: 4px; }
  nav a { font-size: 12px; padding: 4px 8px; }
}
ENDCSS
else
  echo "wiki-css.css exists, preserving customizations."
fi

# --- Write graph.js ---
cat > "$WEBSITE_DIR/graph.js" << 'ENDJS'
// ABOUTME: D3.js force-directed graph for the wikifyskill landing page.
// ABOUTME: Handles node sizing by tier, edge weight/thickness, hover, right-click panel, drag, zoom.
// Read category colors from CSS custom properties for consistency
const cs = getComputedStyle(document.documentElement);
const TYPE_COLORS = {
  'concept': cs.getPropertyValue('--color-concept').trim() || '#5b9bd5',
  'entity': cs.getPropertyValue('--color-entity').trim() || '#66c29a',
  'source-summary': cs.getPropertyValue('--color-source-summary').trim() || '#d4a054',
  'comparison': cs.getPropertyValue('--color-comparison').trim() || '#9a7ec4'
};

async function initGraph() {
  const data = await (await fetch('data.json')).json();
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
    .force('collision', d3.forceCollide().radius(d => d.radius + 4));

  const link = g.append('g').selectAll('line').data(data.edges).join('line')
    .attr('stroke', '#30363d').attr('stroke-width', d => d.thickness).attr('stroke-opacity', 0.6);

  const node = g.append('g').selectAll('circle').data(data.nodes).join('circle')
    .attr('r', d => d.radius).attr('fill', d => TYPE_COLORS[d.type] || '#8b949e')
    .attr('stroke', '#0d1117').attr('stroke-width', 1.5).attr('cursor', 'pointer')
    .call(d3.drag().on('start', ds).on('drag', dd).on('end', de));

  const labels = g.append('g').selectAll('text').data(data.nodes.filter(d => d.tier >= 3)).join('text')
    .text(d => d.title).attr('font-size', d => d.tier >= 4 ? 12 : 10).attr('fill', '#c9d1d9')
    .attr('text-anchor', 'middle').attr('dy', d => d.radius + 14).attr('pointer-events', 'none').attr('opacity', 0.8);

  node.on('mouseover', function(event, d) {
    tooltip.style('opacity', 1).html(
      '<div class="tt-title">' + d.title + '</div>' +
      '<div class="tt-type" style="color:' + TYPE_COLORS[d.type] + '">' + d.type + '</div>' +
      '<div class="tt-confidence">confidence: ' + d.confidence + ' \u00B7 ' + d.inbound + ' inbound links</div>'
    ).style('left', (event.pageX + 14) + 'px').style('top', (event.pageY - 10) + 'px');
    link.attr('stroke-opacity', l => (l.source.id === d.id || l.target.id === d.id) ? 1 : 0.1)
      .attr('stroke', l => (l.source.id === d.id || l.target.id === d.id) ? '#58a6ff' : '#30363d');
    node.attr('opacity', n => {
      if (n.id === d.id) return 1;
      return data.edges.some(e => (e.source.id===d.id && e.target.id===n.id)||(e.target.id===d.id && e.source.id===n.id)) ? 1 : 0.2;
    });
  }).on('mousemove', function(event) {
    tooltip.style('left', (event.pageX+14)+'px').style('top', (event.pageY-10)+'px');
  }).on('mouseout', function() {
    tooltip.style('opacity', 0); link.attr('stroke-opacity', 0.6).attr('stroke', '#30363d'); node.attr('opacity', 1);
  });

  node.on('click', (e, d) => { window.location.href = 'pages/' + d.id + '.html'; });
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

async function openPanel(nd) {
  const panel = document.getElementById('side-panel');
  const html = await (await fetch('pages/' + nd.id + '.html')).text();
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const content = doc.querySelector('.content');
  const meta = doc.querySelector('.page-meta');
  panel.querySelector('.panel-meta').innerHTML = meta ? meta.innerHTML : '';
  panel.querySelector('.panel-body').innerHTML = content ? content.innerHTML : '<p>No content.</p>';
  const pl = panel.querySelector('.panel-link'); if (pl) pl.href = 'pages/' + nd.id + '.html';
  panel.classList.add('open');
}
function closePanel() { document.getElementById('side-panel').classList.remove('open'); }
document.addEventListener('click', e => {
  const p = document.getElementById('side-panel');
  if (p.classList.contains('open') && !p.contains(e.target)) closePanel();
});
document.addEventListener('DOMContentLoaded', initGraph);
ENDJS

# --- Write category.js ---
cat > "$WEBSITE_DIR/category.js" << 'ENDJS'
// ABOUTME: D3.js visualizations for category pages (bubble charts and timelines).
// ABOUTME: Renders bubble chart sized by source count, colored by confidence.
const cs = getComputedStyle(document.documentElement);
const TYPE_COLORS = {
  'concept': cs.getPropertyValue('--color-concept').trim() || '#5b9bd5',
  'entity': cs.getPropertyValue('--color-entity').trim() || '#66c29a',
  'source-summary': cs.getPropertyValue('--color-source-summary').trim() || '#d4a054',
  'comparison': cs.getPropertyValue('--color-comparison').trim() || '#9a7ec4'
};
const CONF_OP = { 'high': 1.0, 'medium': 0.65, 'low': 0.35 };

async function initCategoryViz(catType) {
  const data = await (await fetch('../data.json')).json();
  const nodes = data.nodes.filter(n => n.type === catType);
  if (!nodes.length) return;
  const el = document.getElementById('category-viz');
  const w = el.clientWidth, h = el.clientHeight;
  if (catType === 'source-summary') renderTimeline(el, nodes, w, h);
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
    .on('click', (e,d) => { window.location.href='../pages/'+d.data.id+'.html'; });
  nd.append('circle').attr('r', d=>d.r).attr('fill', color)
    .attr('fill-opacity', d=>CONF_OP[d.data.confidence]||0.5).attr('stroke', color).attr('stroke-width', 1);
  nd.filter(d=>d.r>24).append('text').text(d=>d.data.title).attr('text-anchor','middle')
    .attr('dy','0.35em').attr('fill','#f0f6fc').attr('font-size', d=>Math.min(d.r/3,14)).attr('pointer-events','none');
}

function renderTimeline(el, nodes, w, h) {
  const color = TYPE_COLORS['source-summary'];
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
    .attr('cursor','pointer').on('click',(e,d)=>{window.location.href='../pages/'+d.id+'.html';});
  nd.append('circle').attr('r',d=>d.radius||8).attr('fill',color).attr('fill-opacity',d=>CONF_OP[d.confidence]||0.5);
  nd.filter(d=>(d.radius||8)>6).append('text').text(d=>d.title.length>20?d.title.substring(0,18)+'...':d.title)
    .attr('text-anchor','middle').attr('dy',(d,i)=>i%2===0?-14:20).attr('fill','#c9d1d9').attr('font-size',11);
}
ENDJS

# --- Generate index.html ---
echo "Generating index.html..."
cat > "$WEBSITE_DIR/index.html" << 'ENDHTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Wiki Graph</title>
  <link rel="stylesheet" href="wiki-css.css">
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
  <nav>
    <a href="index.html" class="logo">Wiki Graph</a>
    <a href="categories/concepts.html">Concepts</a>
    <a href="categories/entities.html">Entities</a>
    <a href="categories/sources.html">Sources</a>
    <a href="categories/comparisons.html">Comparisons</a>
  </nav>
  <div id="graph-container"></div>
  <div class="tooltip"></div>
  <div id="side-panel">
    <button class="panel-close" onclick="closePanel()">&times;</button>
    <div class="panel-meta"></div>
    <div class="panel-body"></div>
    <a class="panel-link" href="#">Open full page &rarr;</a>
  </div>
  <script src="graph.js"></script>
</body>
</html>
ENDHTML

# --- Generate category pages ---
echo "Generating category pages..."

gen_category() {
  local cat_dir="$1" cat_name="$2" d3_type="$3"
  local cat_file="$WEBSITE_DIR/categories/${cat_dir}.html"
  local count=0 list_html=""

  for pid in $PAGE_IDS; do
    ptype=$(cat "$TMPWORK/$pid.type")
    if [ "$ptype" = "$d3_type" ]; then
      count=$((count + 1))
      ptitle=$(cat "$TMPWORK/$pid.title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
      pslug=$(cat "$TMPWORK/$pid.slug")
      pconf=$(cat "$TMPWORK/$pid.confidence")
      pcreated=$(cat "$TMPWORK/$pid.created")
      list_html="${list_html}<li><a href=\"../pages/${pslug}.html\">${ptitle}</a><span class=\"meta\"><span>confidence: ${pconf}</span><span>${pcreated}</span></span></li>"
    fi
  done

  local active_concepts="" active_entities="" active_sources="" active_comparisons=""
  case "$cat_dir" in
    concepts) active_concepts='class="active"' ;; entities) active_entities='class="active"' ;;
    sources) active_sources='class="active"' ;; comparisons) active_comparisons='class="active"' ;;
  esac

  cat > "$cat_file" << ENDCATHTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${cat_name} — Wiki</title>
  <link rel="stylesheet" href="../wiki-css.css">
  <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body class="page-body">
  <nav>
    <a href="../index.html" class="logo">Wiki Graph</a>
    <a href="concepts.html" ${active_concepts}>Concepts</a>
    <a href="entities.html" ${active_entities}>Entities</a>
    <a href="sources.html" ${active_sources}>Sources</a>
    <a href="comparisons.html" ${active_comparisons}>Comparisons</a>
  </nav>
  <div class="category-container">
    <div class="category-header"><h1>${cat_name}</h1><div class="count">${count} pages</div></div>
    <div id="category-viz"></div>
    <ul class="page-list">${list_html}</ul>
  </div>
  <div class="tooltip"></div>
  <script src="../category.js"></script>
  <script>initCategoryViz('${d3_type}');</script>
</body>
</html>
ENDCATHTML
}

gen_category "concepts" "Concepts" "concept"
gen_category "entities" "Entities" "entity"
gen_category "sources" "Sources" "source-summary"
gen_category "comparisons" "Comparisons" "comparison"

# --- Generate individual pages ---
echo "Generating individual pages..."

for pid in $PAGE_IDS; do
  slug=$(cat "$TMPWORK/$pid.slug")
  title=$(cat "$TMPWORK/$pid.title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
  type=$(cat "$TMPWORK/$pid.type")
  confidence=$(cat "$TMPWORK/$pid.confidence")
  created=$(cat "$TMPWORK/$pid.created")
  body=$(cat "$TMPWORK/$pid.body")
  related=$(cat "$TMPWORK/$pid.related")

  related_html=""
  if [ -n "$related" ]; then
    related_html="<h3>Related Pages</h3><ul>"
    # Write related items to temp file to avoid subshell variable scope issues
    rm -f "$TMPWORK/rel_items"
    echo "$related" | tr ',' '\n' | while read -r rel; do
      [ -z "$rel" ] && continue
      rel_slug=$(basename "$rel" .md)
      rel_title="$rel_slug"
      for pid2 in $PAGE_IDS; do
        s2=$(cat "$TMPWORK/$pid2.slug")
        if [ "$s2" = "$rel_slug" ]; then
          rel_title=$(cat "$TMPWORK/$pid2.title")
          break
        fi
      done
      echo "<li><a href=\"${rel_slug}.html\">${rel_title}</a></li>" >> "$TMPWORK/rel_items"
    done
    if [ -f "$TMPWORK/rel_items" ]; then
      related_html="${related_html}$(cat "$TMPWORK/rel_items")"
    fi
    related_html="${related_html}</ul>"
  fi

  cat > "$WEBSITE_DIR/pages/${slug}.html" << ENDPAGEHTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — Wiki</title>
  <link rel="stylesheet" href="../wiki-css.css">
</head>
<body class="page-body">
  <nav>
    <a href="../index.html" class="logo">Wiki Graph</a>
    <a href="../categories/concepts.html">Concepts</a>
    <a href="../categories/entities.html">Entities</a>
    <a href="../categories/sources.html">Sources</a>
    <a href="../categories/comparisons.html">Comparisons</a>
  </nav>
  <div class="page-container">
    <div class="page-meta">
      <span class="badge badge-${type}">${type}</span>
      <span class="badge badge-confidence">confidence: ${confidence}</span>
      <span class="badge badge-confidence">${created}</span>
    </div>
    <div class="content">${body}</div>
    ${related_html}
  </div>
</body>
</html>
ENDPAGEHTML
done

echo ""
echo "Site built successfully in $WEBSITE_DIR/"
echo "  $PAGE_COUNT pages, $EDGE_COUNT edges"
echo "  Open $WEBSITE_DIR/index.html in a browser to view."
