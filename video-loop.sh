#!/usr/bin/env bash
set -euo pipefail

# Ensure we’re in a desktop session (autostart) or terminal
export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

log(){ echo "[video-loop] $*"; }

# Build regex for extensions: "mp4 mov" -> \.(mp4|mov)$
ext_regex='\.('"$(printf "%s" "$EXTS" | tr ' ' '|' | tr '[:upper:]' '[:lower:]')"')$'

expand_search_dirs() {
  local out=()
  for root in $SEARCH_DIRS; do
    # Include per-user mounts under /media/$USER and /run/media/$USER
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
  log "Search roots:"
  printf "  • %s\n" "${dirs[@]}"

  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    # Scan up to 3 levels deep to allow USB subfolders
    while IFS= read -r -d '' f; do
      hits+=("$f")
    done < <(find "$d" -maxdepth 3 -type f -iregex ".*${ext_regex}" -print0 2>/dev/null || true)
    # Stop early if we already found something in higher-priority root
    [[ ${#hits[@]} -gt 0 ]] && break
  done

  if [[ ${#hits[@]} -eq 0 ]]; then
    log "No videos found in: $SEARCH_DIRS"
    return 1
  fi

  IFS=$'\n' hits=($(printf "%s\n" "${hits[@]}" | sort -f)); unset IFS
  printf "%s\0" "${hits[@]}"
}

main() {
  log "Starting… user=$USER  DISPLAY=$DISPLAY"
  mapfile -d '' -t playlist < <(find_videos) || {
    log "Nothing to play. Put a file in /media/$USER/<USB>/ or $HOME/Videos"
    exit 1
  }

  log "Found ${#playlist[@]} file(s):"
  for f in "${playlist[@]}"; do log "  - $f"; done

  if [[ "$PLAY_ALL" == "1" && ${#playlist[@]} -gt 1 ]]; then
    tmpplist="$(mktemp)"
    trap 'rm -f "$tmpplist"' EXIT
    printf "%s\n" "${playlist[@]}" > "$tmpplist"
    log "Launching mpv (playlist)…"
    exec mpv $MPV_OPTS --playlist="$tmpplist"
  else
    log "Launching mpv (single file)…"
    exec mpv $MPV_OPTS --loop-file=inf "${playlist[0]}"
  fi
}

main "$@"
