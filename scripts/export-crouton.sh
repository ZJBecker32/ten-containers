#!/usr/bin/env bash
#
# export-crouton.sh — strip YAML frontmatter, emit the Crouton-ready body.
#
# The body of every recipe file is already Crouton-compatible Markdown (see
# SCHEMA.md). Crouton has nowhere to put container counts, gram targets or
# observed yields, so the frontmatter is dropped on the way out.
#
# Usage:
#   scripts/export-crouton.sh                        all recipes -> stdout
#   scripts/export-crouton.sh recipes/foo.md         one recipe  -> stdout
#   scripts/export-crouton.sh -o out/                all recipes -> out/*.md
#   scripts/export-crouton.sh -o out/ recipes/foo.md one recipe  -> out/foo.md
#
set -euo pipefail

outdir=""
while getopts ":o:h" opt; do
  case "$opt" in
    o) outdir="$OPTARG" ;;
    h) awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"; exit 0 ;;
    \?) echo "export-crouton.sh: unknown option -$OPTARG" >&2; exit 2 ;;
    :)  echo "export-crouton.sh: -$OPTARG needs an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(find "$repo_root/recipes" -name '*.md' | sort)
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "export-crouton.sh: no recipe files found" >&2
  exit 1
fi

if [ -n "$outdir" ]; then
  mkdir -p "$outdir"
fi

strip_frontmatter() {
  # Drop a leading --- ... --- block, then drop blank lines before the body.
  awk '
    NR == 1 {
      if ($0 == "---") { in_fm = 1; next }
      printing = 1
    }
    in_fm {
      if ($0 == "---") { in_fm = 0; printing = 1 }
      next
    }
    printing { print }
  ' "$1" | awk 'NF || seen { seen = 1; print }'
}

first=1
for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "export-crouton.sh: no such file: $f" >&2
    exit 1
  fi

  if [ -n "$outdir" ]; then
    dest="$outdir/$(basename "$f")"
    strip_frontmatter "$f" > "$dest"
    echo "wrote $dest" >&2
  else
    if [ "$first" -eq 0 ]; then printf '\n\n---\n\n'; fi
    strip_frontmatter "$f"
    first=0
  fi
done
