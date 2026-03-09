#!/usr/bin/env bash
# skill-statusline v2 — Shared helpers

# Convert any path to forward slashes (safe on all OS)
to_fwd() {
  echo "$1" | tr '\\' '/' | sed 's|//\+|/|g'
}

# Right-pad a colored string to a visible width
rpad() {
  local str="$1" w="$2"
  local plain
  plain=$(printf '%b' "$str" | sed $'s/\033\\[[0-9;]*m//g')
  local vlen=${#plain}
  local need=$(( w - vlen ))
  printf '%b' "$str"
  [ "$need" -gt 0 ] && printf "%${need}s" ""
}

# Format token count with k/M suffixes
fmt_tok() {
  awk -v t="$1" 'BEGIN {
    if (t >= 1000000) printf "%.1fM", t/1000000
    else if (t >= 1000) printf "%.0fk", t/1000
    else printf "%d", t
  }'
}

# Format duration from milliseconds to human-readable
fmt_duration() {
  awk -v ms="$1" 'BEGIN {
    s = int(ms / 1000)
    if (s < 60) printf "%ds", s
    else if (s < 3600) printf "%dm%ds", int(s/60), s%60
    else printf "%dh%dm", int(s/3600), int((s%3600)/60)
  }'
}

# ── Run a command with a timeout (seconds) ──
# Usage: run_with_timeout <seconds> <command...>
# Returns empty string if timeout exceeded
run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@" 2>/dev/null
  else
    # Fallback: background + wait (POSIX-ish)
    "$@" 2>/dev/null &
    local pid=$!
    local i=0
    while [ $i -lt $(( secs * 10 )) ]; do
      if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid" 2>/dev/null
        return $?
      fi
      sleep 0.1
      i=$((i + 1))
    done
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    return 124
  fi
}

# ── Filesystem caching with TTL ──

CACHE_DIR="/tmp/sl-cache-${USER:-unknown}"
CACHE_TTL="${SL_CACHE_TTL:-5}"

# Detect stat flavor once (not on every cache check)
_SL_STAT_GNU=""
_sl_cache_init() {
  [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR" 2>/dev/null
  # Detect stat syntax once and cache the result
  if stat -c %Y "$CACHE_DIR" >/dev/null 2>&1; then
    _SL_STAT_GNU="yes"
  else
    _SL_STAT_GNU="no"
  fi
}

# Get file mtime using cached stat detection
_sl_file_mtime() {
  if [ "$_SL_STAT_GNU" = "yes" ]; then
    stat -c %Y "$1" 2>/dev/null
  else
    stat -f %m "$1" 2>/dev/null
  fi
}

# cache_get "key" "command" [ttl_seconds]
# Returns cached result if fresh, otherwise runs command and caches
cache_get() {
  local key="$1" cmd="$2" ttl="${3:-$CACHE_TTL}"
  local f="${CACHE_DIR}/${key}"

  if [ -f "$f" ]; then
    local now mtime age
    now=$(date +%s)
    mtime=$(_sl_file_mtime "$f")
    if [ -n "$mtime" ]; then
      age=$(( now - mtime ))
      if [ "$age" -lt "$ttl" ]; then
        cat "$f"
        return 0
      fi
    fi
  fi

  local result
  result=$(eval "$cmd" 2>/dev/null)
  printf '%s' "$result" > "$f" 2>/dev/null
  printf '%s' "$result"
}

# Clear all cached data
cache_clear() {
  [ -d "$CACHE_DIR" ] && rm -f "${CACHE_DIR}"/* 2>/dev/null
}
