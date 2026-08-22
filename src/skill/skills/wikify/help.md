wikify — build and maintain an LLM-compiled knowledge wiki (Karpathy pattern)

WHAT IT DOES
  Compiles source material in raw/ into a persistent, cross-referenced
  knowledge base in wiki/. The LLM handles all bookkeeping — page
  creation, cross-references, contradiction detection, confidence
  tracking — while the human curates sources and asks questions.
  Auto-detects which workflow to run from the current directory's state
  and the user's message: Init, Ingest, Query, Lint, or Learning Plan.

WHAT IT NEEDS
  - A project directory; wikify will create raw/ and wiki/ on first run
    (Init) if WIKI_SCHEMA.md doesn't exist yet

USAGE
  wikify                    Auto-detects context; runs Init, Ingest,
                             Query, Lint, or Learning Plan as appropriate
  "lint"                    Run a wiki health check
  "learning plan"           Generate a learning plan from the wiki
  <a question>              Query the compiled wiki
  --help                    Show this message and exit
  --dry-run                 Preview what would be created/updated
                             (pages, schema, index/log entries)
                             without writing any file

OTHER TOOLS
  scripts/build-site.sh     Renders the wiki into a static website.
                             Run from any wiki project root:
                             python3 ~/.claude/skills/wikify/scripts/build-site.sh wiki website

FLAGS
  --help      Show this help message without making any changes
  --dry-run   Run the normal detection and analysis for whichever
              workflow applies (Init, Ingest, Lint, or Learning Plan),
              then report what would be created or updated instead of
              writing anything
