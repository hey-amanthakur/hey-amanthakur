#!/usr/bin/env bash
# Fill in inputs and regenerate every local asset for the profile README.
#
#   ./setup.sh --image assets/me.png
#   ./setup.sh --image assets/me.png --cols 110 --circle --animate
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"

mode="dots"; cols=100; image=""
# defaults below reproduce the committed look: colour dots + row-reveal
color="--color"; reveal="--reveal"
circle=""; animate=""; invert=""; square=""
focus="0.5,0.5"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)   image="$2"; shift 2 ;;
    --mode)    mode="$2"; shift 2 ;;
    --cols)    cols="$2"; shift 2 ;;
    --focus)   focus="$2"; shift 2 ;;
    --no-color)  color=""; shift ;;
    --no-reveal) reveal=""; shift ;;
    --circle)  circle="--circle"; shift ;;
    --color)   color="--color"; shift ;;
    --animate) animate="--animate"; shift ;;
    --invert)  invert="--invert"; shift ;;
    --square)  square="--square"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

echo "
[1/3] drawing the skill radar"
python3 "$root/scripts/radar.py" --data "$root/assets/skills.json" -o "$root/assets/radar"

echo "      drawing the language radar from the GitHub API (unauthenticated: 60 req/hr)"
python3 "$root/scripts/radar.py" --github hey-amanthakur -o "$root/assets/radar-langs" \
  --values --limit 7 --curve 0.4 \
  --exclude "shell,makefile,dockerfile,batchfile,procfile"

if [[ -n "$image" ]]; then
  echo "
[2/3] dot-matrixing $image"
  python3 "$root/scripts/dotify.py" "$image" -o "$root/assets/portrait" \
    --mode "$mode" --cols "$cols" --equalize --detail 0.5 $square $circle \
    $color $reveal $animate $invert ${square:+--focus "$focus"}
else
  echo "
[2/3] no --image given, skipping the portrait"
fi

echo "
[3/3] stat and repo cards"
python3 "$root/scripts/cards.py" --user hey-amanthakur \
  --projects "$root/assets/projects.json" --out "$root/assets"

echo "
done. open preview.html to check it, then read docs/SETUP.md for the GitHub side."
