#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

# Build regex for extensions: "mp4 mov" -> \.(mp4|mov)$
ext_regex='\.('"$(printf "%s" "$EXTS" | tr ' ' '|' | tr '[:upper:]' '[:lower:]')"')$'

expand_search_dirs() {
  local out=()
  for root in $SEARCH_DIRS; do
    # If there are per-user subdirs under /media or /run/media, include them.
    if [[ -d "$root/$USER" ]]; then
      for d in "$root/$USER"/*; do [[ -d "$d" ]] && out+=("$d"); done
    fi
    [[ -d "$root" ]] && out+=("$root")
  done
  printf "%s\n" "${out[@]}" | awk 'NF' | uniq
}

find_videos() {
  local -a dirs; mapfile -t dirs < <(expand_search_dirs)
  local -a hits=()
  for d in "${dirs[@]}"; do
    while IFS= read -r -d '' f; do
      hits+=("$f")
    done < <(find "$d" -maxdepth 1 -type f -iregex ".*${ext_regex}" -print0 2>/dev/null || true)
    [[ ${#hits[@]} -gt 0 ]] && break
  done
  IFS=$'\n' hits=($(printf "%s\n" "${hits[@]}" | sort -f)); unset IFS

  if [[ ${#hits[@]} -eq 0 ]]; then
    echo "[video-loop] No videos found in: $SEARCH_DIRS"
    exit 1
  fi

  if [[ "$PLAY_ALL" == "1" && ${#hits[@]} -gt 1 ]]; then
    printf "%s\0" "${hits[@]}"
  else
    printf "%s\0" "${hits[0]}"
  fi
}

main() {
  echo "[video-loop] Searching for videos..."
  mapfile -d '' -t playlist < <(find_videos)

  echo "[video-loop] Found ${#playlist[@]} file(s):"
  for f in "${playlist[@]}"; do echo "  - $f"; done

  if [[ ${#playlist[@]} -gt 1 && "$PLAY_ALL" == "1" ]]; then
    tmpplist="$(mktemp)"
    trap 'rm -f "$tmpplist"' EXIT
    printf "%s\n" "${playlist[@]}" > "$tmpplist"
    exec mpv $MPV_OPTS --playlist="$tmpplist"
  else
    exec mpv $MPV_OPTS --loop-file=inf "${playlist[0]}"
  fi
}

main "$@"
