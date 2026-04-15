# ABOUTME: Tests for scripts/build-site.sh static site generator.
# ABOUTME: Creates a sample wiki, runs build, and verifies output structure and content.

FAILURES=0
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PROJECT_DIR/scripts/build-site.sh"

# --- Script file tests ---
assert_file_exists "$SCRIPT" "build-site.sh exists"
assert_contains "$SCRIPT" "ABOUTME" "build-site.sh has ABOUTME comment"
assert_contains "$SCRIPT" "data.json" "script generates data.json"
assert_contains "$SCRIPT" "index.html" "script generates index.html"
assert_contains "$SCRIPT" "d3" "script references d3"
assert_contains "$SCRIPT" "website" "script references website directory"

# --- Integration test: build a sample wiki and verify output ---
TMPDIR_TEST=$(mktemp -d)
WIKI_DIR="$TMPDIR_TEST/wiki"
WEBSITE_DIR="$TMPDIR_TEST/website"

# Create sample wiki structure
mkdir -p "$WIKI_DIR/concepts" "$WIKI_DIR/entities" "$WIKI_DIR/sources" "$WIKI_DIR/comparisons"

# Create sample concept page
cat > "$WIKI_DIR/concepts/machine-learning.md" << 'ENDOFFILE'
---
title: Machine Learning
type: concept
sources:
  - ../raw/articles/ml-intro.md
related:
  - entities/andrej-karpathy.md
  - concepts/neural-networks.md
confidence: high
created: 2026-04-15
updated: 2026-04-15
---

# Machine Learning

Machine learning is a subset of artificial intelligence that focuses on building systems that learn from data.

## Key Points

- Supervised learning uses labeled data
- Unsupervised learning finds patterns
- Reinforcement learning uses rewards
ENDOFFILE

# Create sample entity page
cat > "$WIKI_DIR/entities/andrej-karpathy.md" << 'ENDOFFILE'
---
title: Andrej Karpathy
type: entity
sources:
  - ../raw/articles/ml-intro.md
  - ../raw/articles/llm-wiki.md
related:
  - concepts/machine-learning.md
  - concepts/neural-networks.md
confidence: high
created: 2026-04-15
updated: 2026-04-15
---

# Andrej Karpathy

Former director of AI at Tesla and researcher at OpenAI.
ENDOFFILE

# Create another concept to test connections
cat > "$WIKI_DIR/concepts/neural-networks.md" << 'ENDOFFILE'
---
title: Neural Networks
type: concept
sources:
  - ../raw/articles/ml-intro.md
related:
  - concepts/machine-learning.md
  - entities/andrej-karpathy.md
confidence: medium
created: 2026-04-15
updated: 2026-04-15
---

# Neural Networks

Neural networks are computing systems inspired by biological neural networks.
ENDOFFILE

# Create a source summary page
cat > "$WIKI_DIR/sources/ml-intro.md" << 'ENDOFFILE'
---
title: Introduction to ML
type: source-summary
sources:
  - ../raw/articles/ml-intro.md
related:
  - concepts/machine-learning.md
confidence: high
created: 2026-04-15
updated: 2026-04-15
---

# Introduction to ML

Summary of the introductory article on machine learning.
ENDOFFILE

# Create a comparison page
cat > "$WIKI_DIR/comparisons/supervised-vs-unsupervised.md" << 'ENDOFFILE'
---
title: Supervised vs Unsupervised Learning
type: comparison
sources:
  - ../raw/articles/ml-intro.md
related:
  - concepts/machine-learning.md
confidence: medium
created: 2026-04-15
updated: 2026-04-15
---

# Supervised vs Unsupervised Learning

| Aspect | Supervised | Unsupervised |
|--------|-----------|-------------|
| Data | Labeled | Unlabeled |
| Goal | Predict | Discover |
ENDOFFILE

# Create index.md
cat > "$WIKI_DIR/index.md" << 'ENDOFFILE'
# Wiki Index

## Sources
- [Introduction to ML](sources/ml-intro.md) — type: source-summary, confidence: high

## Concepts
- [Machine Learning](concepts/machine-learning.md) — type: concept, confidence: high
- [Neural Networks](concepts/neural-networks.md) — type: concept, confidence: medium

## Entities
- [Andrej Karpathy](entities/andrej-karpathy.md) — type: entity, confidence: high

## Comparisons
- [Supervised vs Unsupervised Learning](comparisons/supervised-vs-unsupervised.md) — type: comparison, confidence: medium
ENDOFFILE

# Create overview.md
cat > "$WIKI_DIR/overview.md" << 'ENDOFFILE'
# Wiki Overview

This wiki covers machine learning fundamentals.
ENDOFFILE

# Create log.md
cat > "$WIKI_DIR/log.md" << 'ENDOFFILE'
# Processing Log

## [2026-04-15] ingest | Introduction to ML
- Source: raw/articles/ml-intro.md
- Created: sources/ml-intro.md
- Created: concepts/machine-learning.md
ENDOFFILE

# Run build script
cd "$TMPDIR_TEST"
"$SCRIPT" 2>/dev/null

# Verify output structure
assert_file_exists "$WEBSITE_DIR/index.html" "website/index.html generated"
assert_file_exists "$WEBSITE_DIR/data.json" "website/data.json generated"
assert_file_exists "$WEBSITE_DIR/wiki-css.css" "website/wiki-css.css generated"
assert_file_exists "$WEBSITE_DIR/graph.js" "website/graph.js generated"
assert_file_exists "$WEBSITE_DIR/category.js" "website/category.js generated"
assert_file_exists "$WEBSITE_DIR/categories/concepts.html" "categories/concepts.html generated"
assert_file_exists "$WEBSITE_DIR/categories/entities.html" "categories/entities.html generated"
assert_file_exists "$WEBSITE_DIR/categories/sources.html" "categories/sources.html generated"
assert_file_exists "$WEBSITE_DIR/categories/comparisons.html" "categories/comparisons.html generated"
assert_file_exists "$WEBSITE_DIR/pages/machine-learning.html" "pages/machine-learning.html generated"
assert_file_exists "$WEBSITE_DIR/pages/andrej-karpathy.html" "pages/andrej-karpathy.html generated"
assert_file_exists "$WEBSITE_DIR/pages/neural-networks.html" "pages/neural-networks.html generated"
assert_file_exists "$WEBSITE_DIR/pages/ml-intro.html" "pages/ml-intro.html generated"
assert_file_exists "$WEBSITE_DIR/pages/supervised-vs-unsupervised.html" "pages/supervised-vs-unsupervised.html generated"

# Verify data.json content
assert_contains "$WEBSITE_DIR/data.json" '"nodes"' "data.json has nodes array"
assert_contains "$WEBSITE_DIR/data.json" '"edges"' "data.json has edges array"
assert_contains "$WEBSITE_DIR/data.json" '"Machine Learning"' "data.json contains Machine Learning node"
assert_contains "$WEBSITE_DIR/data.json" '"Andrej Karpathy"' "data.json contains Andrej Karpathy node"
assert_contains "$WEBSITE_DIR/data.json" '"concept"' "data.json contains concept type"
assert_contains "$WEBSITE_DIR/data.json" '"entity"' "data.json contains entity type"
assert_contains "$WEBSITE_DIR/data.json" '"tier"' "data.json contains tier field for node sizing"
assert_contains "$WEBSITE_DIR/data.json" '"weight"' "data.json contains weight field for edges"

# Verify index.html content
assert_contains "$WEBSITE_DIR/index.html" "d3" "index.html loads D3"
assert_contains "$WEBSITE_DIR/index.html" "graph.js" "index.html loads graph.js"
assert_contains "$WEBSITE_DIR/graph.js" "data.json" "graph.js fetches data.json"
assert_contains "$WEBSITE_DIR/graph.js" "contextmenu" "graph.js supports right-click via contextmenu"

# Verify graph.js content
assert_contains "$WEBSITE_DIR/graph.js" "forceSimulation\|force(" "graph.js uses D3 force simulation"
assert_contains "$WEBSITE_DIR/graph.js" "tier" "graph.js uses tier for node sizing"
assert_contains "$WEBSITE_DIR/graph.js" "weight" "graph.js uses weight for edge thickness"
assert_contains "$WEBSITE_DIR/graph.js" "#4A90D9\|concept" "graph.js has concept color"
assert_contains "$WEBSITE_DIR/graph.js" "#50C878\|entity" "graph.js has entity color"

# Verify category pages
assert_contains "$WEBSITE_DIR/categories/concepts.html" "Machine Learning" "concepts page lists Machine Learning"
assert_contains "$WEBSITE_DIR/categories/entities.html" "Andrej Karpathy" "entities page lists Andrej Karpathy"

# Verify individual pages
assert_contains "$WEBSITE_DIR/pages/machine-learning.html" "Machine Learning" "ML page has title"
assert_contains "$WEBSITE_DIR/pages/machine-learning.html" "concept" "ML page shows type"
assert_contains "$WEBSITE_DIR/pages/machine-learning.html" "wiki-css.css" "ML page references wiki-css.css"

# Verify wiki-css.css content (taste-skill design tokens)
assert_contains "$WEBSITE_DIR/wiki-css.css" "Outfit" "wiki-css.css uses Outfit font"
assert_contains "$WEBSITE_DIR/wiki-css.css" "--color-bg" "wiki-css.css has color-bg token"
assert_contains "$WEBSITE_DIR/wiki-css.css" "--color-concept" "wiki-css.css has concept color token"
assert_contains "$WEBSITE_DIR/wiki-css.css" "--font-sans" "wiki-css.css has font-sans token"
assert_contains "$WEBSITE_DIR/wiki-css.css" "--ease-spring" "wiki-css.css has spring easing"
assert_contains "$WEBSITE_DIR/wiki-css.css" "cubic-bezier" "wiki-css.css uses custom cubic-bezier"
assert_contains "$WEBSITE_DIR/wiki-css.css" "JetBrains Mono" "wiki-css.css has monospace font"
assert_contains "$WEBSITE_DIR/wiki-css.css" "fadeInUp" "wiki-css.css has scroll entry animation"

# Verify CSS is NOT regenerated on second run (preserves customizations)
echo "/* user customization */" >> "$WEBSITE_DIR/wiki-css.css"
cd "$TMPDIR_TEST"
"$SCRIPT" 2>/dev/null
assert_contains "$WEBSITE_DIR/wiki-css.css" "user customization" "wiki-css.css preserved on rebuild"

# Verify graph.js reads CSS custom properties
assert_contains "$WEBSITE_DIR/graph.js" "getComputedStyle\|--color-concept" "graph.js reads colors from CSS tokens"

# Clean up
rm -rf "$TMPDIR_TEST"
