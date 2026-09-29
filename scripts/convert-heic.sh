#!/usr/bin/env bash
# scripts/convert-heic.sh
# Convert all .HEIC/.HEIF images in the repository root (or given directory)
# to JPEG files with the same base name. Keeps original HEIC files.
# Usage: ./scripts/convert-heic.sh [path]

set -euo pipefail

DIR=".${1:+/$1}"
# If path was provided, use that instead
if [ "$#" -ge 1 ]; then
  DIR="$1"
fi

shopt -s nullglob

HEIC_FILES=("$DIR"/*.HEIC "$DIR"/*.HEIF "$DIR"/*.heic "$DIR"/*.heif)

if [ ${#HEIC_FILES[@]} -eq 0 ]; then
  echo "No HEIC/HEIF files found in ${DIR}."
  exit 0
fi

echo "Found ${#HEIC_FILES[@]} HEIC/HEIF file(s)."

# Detect available converter
if command -v magick >/dev/null 2>&1; then
  CONVERTER="magick"
elif command -v heif-convert >/dev/null 2>&1; then
  CONVERTER="heif-convert"
elif command -v sips >/dev/null 2>&1; then
  CONVERTER="sips"
else
  echo "No suitable converter found. Please install ImageMagick (magick), libheif (heif-convert), or on macOS use sips."
  exit 1
fi

for src in "${HEIC_FILES[@]}"; do
  # Skip if glob didn't match
  [ -e "$src" ] || continue
  base="$(basename "$src")"
  name="${base%.*}"
  out="$DIR/${name}.jpg"

  echo "Converting '$src' -> '$out' using $CONVERTER"

  if [ "$CONVERTER" = "magick" ]; then
    magick convert "$src" -quality 85 -strip "$out"
  elif [ "$CONVERTER" = "heif-convert" ]; then
    heif-convert "$src" "$out"
  elif [ "$CONVERTER" = "sips" ]; then
    sips -s format jpeg "$src" --out "$out"
  fi

  # Optionally optimize if jpegoptim is available
  if command -v jpegoptim >/dev/null 2>&1; then
    jpegoptim --strip-all --max=85 "$out" >/dev/null || true
  fi

done

echo "Done. Review the new .jpg files, then:"
cat <<'EOF'
  git add *.jpg
  git commit -m "Convert HEIC images to JPEG for web compatibility"
  git push origin main
EOF

exit 0
