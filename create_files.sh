#!/usr/bin/env bash

YML_FILE="${1:-titles.yml}"
INPUT_DIR="input"

mkdir -p "$INPUT_DIR"

grep -E '^[[:space:]]*[0-9]+-[0-9]+-[^:]+:' "$YML_FILE" \
| sed -E 's/^[[:space:]]*([^:]+):.*/\1/' \
| while read -r key; do
    for lang in it de; do
        file="$INPUT_DIR/${key}.${lang}.txt"
        [ -e "$file" ] || touch "$file"
    done
done
