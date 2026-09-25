#!/usr/bin/env bash

set -euo pipefail

readonly export_dir="${1:?Usage: prepare-web-package.sh EXPORT_DIRECTORY}"
readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly chunk_size=$((90 * 1024 * 1024))
readonly loader_name='web-pck-loader.js'

if [[ ! -d "$export_dir" ]]; then
  printf 'Web export directory does not exist: %s\n' "$export_dir" >&2
  exit 1
fi

if [[ ! -f "$export_dir/index.html" ]]; then
  printf 'Godot Web entry point does not exist: %s/index.html\n' "$export_dir" >&2
  exit 1
fi

if [[ ! -f "$script_dir/$loader_name" ]]; then
  printf 'PCK loader does not exist: %s/%s\n' "$script_dir" "$loader_name" >&2
  exit 1
fi

split_count=0

while IFS= read -r -d '' pack; do
  pack_name="${pack##*/}"
  pack_stem="${pack_name%.pck}"
  pack_size=$(stat --format='%s' "$pack")
  manifest="${pack}.parts.json"
  parts_dir=$(mktemp -d "$export_dir/.pck-parts.XXXXXX")

  split \
    --bytes="$chunk_size" \
    --numeric-suffixes=0 \
    --suffix-length=3 \
    --additional-suffix='.pck' \
    "$pack" \
    "$parts_dir/${pack_stem}.part-"

  manifest_tmp="${manifest}.tmp"
  printf '{"size":%s,"parts":[' "$pack_size" >"$manifest_tmp"
  first_part=1

  for part in "$parts_dir"/*.pck; do
    if (( first_part )); then
      first_part=0
    else
      printf ',' >>"$manifest_tmp"
    fi

    printf \
      '{"path":"%s","size":%s}' \
      "${part##*/}" \
      "$(stat --format='%s' "$part")" \
      >>"$manifest_tmp"
  done

  printf ']}\n' >>"$manifest_tmp"

  find "$export_dir" \
    -maxdepth 1 \
    -type f \
    -name "${pack_stem}.part-*.pck" \
    -delete
  mv "$parts_dir"/*.pck "$export_dir/"
  rmdir "$parts_dir"
  mv "$manifest_tmp" "$manifest"
  rm -- "$pack"

  printf \
    'Split %s (%s bytes) into %s MiB chunks for static hosting.\n' \
    "$pack_name" \
    "$pack_size" \
    "$((chunk_size / 1024 / 1024))"
  split_count=$((split_count + 1))
done < <(find "$export_dir" -maxdepth 1 -type f -name '*.pck' -size +"$chunk_size"c -print0)

if (( split_count == 0 )); then
  echo 'No Web package exceeded the chunk threshold.'
  exit 0
fi

cp "$script_dir/$loader_name" "$export_dir/$loader_name"

if ! grep -qF "$loader_name" "$export_dir/index.html"; then
  sed -i \
    "s#</head>#<script src=\"$loader_name\"></script>\\n</head>#" \
    "$export_dir/index.html"
fi
