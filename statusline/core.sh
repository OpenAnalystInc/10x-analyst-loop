#!/usr/bin/env bash
# skill-statusline v2 — Core engine
# Reads Claude Code JSON from stdin, computes all fields, renders via layout

STATUSLINE_DIR="${HOME}/.claude/statusline"
CONFIG_FILE="${HOME}/.claude/statusline-config.json"

# ── 0. Read stdin JSON first (before anything else) ──
# If stdin isn't piped properly, `cat` hangs forever — guard against that
if [ -t 0 ]; then
  exit 0
fi
input=$(timeout 2 cat 2>/dev/null)
if [ -z "$input" ]; then
  exit 0
fi

# Note: no global watchdog — individual timeouts on stdin (2s), git (2s),
# and tput (1s) protect against hangs without background process issues

# ── 1. Source modules ──
source "${STATUSLINE_DIR}/json-parser.sh"
source "${STATUSLINE_DIR}/helpers.sh"

# ── 2. Parse ALL JSON in one awk pass ──
# This sets SL_J_* variables — avoids spawning 100+ subshells
sl_parse_json

# ── 3. Load config (using simple grep — much faster than multiple json calls) ──
active_theme="default"
active_layout="standard"
cfg_warn_threshold=85
cfg_bar_width=40
cfg_show_burn_rate="false"
cfg_show_vim="true"
cfg_show_agent="true"

if [ -f "$CONFIG_FILE" ]; then
  _cfg=$(cat "$CONFIG_FILE" 2>/dev/null)
  _t=$(echo "$_cfg" | grep -o '"theme"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\(.*\)"/\1/')
  _l=$(echo "$_cfg" | grep -o '"layout"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\(.*\)"/\1/')
  [ -n "$_t" ] && active_theme="$_t"
  [ -n "$_l" ] && active_layout="$_l"
  _w=$(echo "$_cfg" | grep -o '"compaction_warning_threshold"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*:[[:space:]]*//')
  _bw=$(echo "$_cfg" | grep -o '"bar_width"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed 's/.*:[[:space:]]*//')
  _br=$(echo "$_cfg" | grep -o '"show_burn_rate"[[:space:]]*:[[:space:]]*true' | head -1)
  _sv=$(echo "$_cfg" | grep -o '"show_vim_mode"[[:space:]]*:[[:space:]]*false' | head -1)
  _sa=$(echo "$_cfg" | grep -o '"show_agent_name"[[:space:]]*:[[:space:]]*false' | head -1)
  [ -n "$_w" ] && cfg_warn_threshold="$_w"
  [ -n "$_bw" ] && cfg_bar_width="$_bw"
  [ -n "$_br" ] && cfg_show_burn_rate="true"
  [ -n "$_sv" ] && cfg_show_vim="false"
  [ -n "$_sa" ] && cfg_show_agent="false"
fi

# Allow env override (for ccsl preview)
[ -n "$STATUSLINE_THEME_OVERRIDE" ] && active_theme="$STATUSLINE_THEME_OVERRIDE"
[ -n "$STATUSLINE_LAYOUT_OVERRIDE" ] && active_layout="$STATUSLINE_LAYOUT_OVERRIDE"

# ── 4. Source theme ──
theme_file="${STATUSLINE_DIR}/themes/${active_theme}.sh"
if [ -f "$theme_file" ]; then
  source "$theme_file"
else
  source "${STATUSLINE_DIR}/themes/default.sh"
fi

# ── 5. Terminal width detection (with timeout) ──
SL_TERM_WIDTH=${COLUMNS:-0}
if [ "$SL_TERM_WIDTH" -eq 0 ] 2>/dev/null; then
  _tw=$(timeout 1 tput cols 2>/dev/null || echo "")
  [ -n "$_tw" ] && [ "$_tw" -gt 0 ] && SL_TERM_WIDTH="$_tw"
fi
[ "$SL_TERM_WIDTH" -eq 0 ] && SL_TERM_WIDTH=80

# Auto-downgrade layout for narrow terminals
if [ "$SL_TERM_WIDTH" -lt 60 ]; then
  active_layout="compact"
elif [ "$SL_TERM_WIDTH" -lt 80 ] && [ "$active_layout" = "full" ]; then
  active_layout="standard"
fi

# Dynamic bar width
BAR_WIDTH="$cfg_bar_width"
if [ "$SL_TERM_WIDTH" -gt 100 ]; then
  _dyn=$(( SL_TERM_WIDTH - 20 ))
  [ "$_dyn" -gt 60 ] && _dyn=60
  [ "$_dyn" -gt "$BAR_WIDTH" ] && BAR_WIDTH="$_dyn"
elif [ "$SL_TERM_WIDTH" -lt 70 ]; then
  BAR_WIDTH=20
fi

# ── 6. Initialize cache ──
_sl_cache_init

# ── 7. Map parsed JSON vars to display vars ──

# --- Directory ---
SL_CWD="${SL_J_workspace_current_dir:-$SL_J_cwd}"
if [ -z "$SL_CWD" ]; then
  SL_DIR="~"
  clean_cwd=""
else
  clean_cwd=$(to_fwd "$SL_CWD")
  SL_DIR=$(echo "$clean_cwd" | awk -F'/' '{if(NF>3) print $(NF-2)"/"$(NF-1)"/"$NF; else if(NF>2) print $(NF-1)"/"$NF; else print $0}')
  [ -z "$SL_DIR" ] && SL_DIR="~"
fi

# --- Model ---
SL_MODEL_DISPLAY="${SL_J_model_display_name:-unknown}"
SL_MODEL_ID="${SL_J_model_id}"
model_ver=""
if [ -n "$SL_MODEL_ID" ]; then
  model_ver=$(echo "$SL_MODEL_ID" | sed -n 's/.*-\([0-9]*\)-\([0-9]*\)$/\1.\2/p')
fi
if [ -n "$model_ver" ] && ! echo "$SL_MODEL_DISPLAY" | grep -q '[0-9]'; then
  SL_MODEL="${SL_MODEL_DISPLAY} ${model_ver}"
else
  SL_MODEL="$SL_MODEL_DISPLAY"
fi

# --- Context — ACCURATE computation from current_usage ---
ctx_size="${SL_J_context_window_context_window_size:-200000}"
cur_input="${SL_J_context_window_current_usage_input_tokens:-0}"
cur_output="${SL_J_context_window_current_usage_output_tokens:-0}"
cur_cache_create="${SL_J_context_window_current_usage_cache_creation_input_tokens:-0}"
cur_cache_read="${SL_J_context_window_current_usage_cache_read_input_tokens:-0}"

# Claude's formula: input + cache_creation + cache_read (output excluded from context %)
ctx_used=$(( cur_input + cur_cache_create + cur_cache_read ))

# Self-calculated percentage
calc_pct=0
if [ "$cur_input" -gt 0 ] 2>/dev/null && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
  calc_pct=$(( ctx_used * 100 / ctx_size ))
fi

# Reported percentage as fallback
reported_pct="${SL_J_context_window_used_percentage}"

# Use self-calculated if we have current_usage data, else fallback
if [ "$cur_input" -gt 0 ] 2>/dev/null; then
  SL_CTX_PCT="$calc_pct"
elif [ -n "$reported_pct" ]; then
  SL_CTX_PCT=$(echo "$reported_pct" | cut -d. -f1)
else
  SL_CTX_PCT=0
fi

SL_CTX_REMAINING=$(( 100 - SL_CTX_PCT ))
[ "$SL_CTX_REMAINING" -lt 0 ] && SL_CTX_REMAINING=0

# Context color
if [ "$SL_CTX_PCT" -gt 90 ] 2>/dev/null; then
  CTX_CLR="$CLR_CTX_CRIT"
elif [ "$SL_CTX_PCT" -gt 75 ] 2>/dev/null; then
  CTX_CLR="$CLR_CTX_HIGH"
elif [ "$SL_CTX_PCT" -gt 40 ] 2>/dev/null; then
  CTX_CLR="$CLR_CTX_MED"
else
  CTX_CLR="$CLR_CTX_LOW"
fi

# Build context bar
filled=$(( SL_CTX_PCT * BAR_WIDTH / 100 ))
[ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
empty=$(( BAR_WIDTH - filled ))
bar_filled=""; bar_empty=""
i=0; while [ $i -lt $filled ]; do bar_filled="${bar_filled}${BAR_FILLED}"; i=$((i+1)); done
i=0; while [ $i -lt $empty ]; do bar_empty="${bar_empty}${BAR_EMPTY}"; i=$((i+1)); done
SL_CTX_BAR="${CTX_CLR}${bar_filled}${CLR_RST}${CLR_BAR_EMPTY}${bar_empty}${CLR_RST} ${CTX_CLR}${SL_CTX_PCT}%${CLR_RST}"

# Compaction warning
SL_COMPACT_WARNING=""
if [ "$SL_CTX_PCT" -ge 95 ] 2>/dev/null; then
  SL_COMPACT_WARNING=" ${CLR_CTX_CRIT}${CLR_BOLD}COMPACTING${CLR_RST}"
elif [ "$SL_CTX_PCT" -ge "$cfg_warn_threshold" ] 2>/dev/null; then
  SL_COMPACT_WARNING=" ${CLR_CTX_HIGH}${SL_CTX_REMAINING}% left${CLR_RST}"
fi

# --- GitHub (with caching + timeouts) ---
SL_BRANCH="no-git"
SL_GIT_DIRTY=""
SL_GITHUB=""
gh_user=""
gh_repo=""

if [ -n "$clean_cwd" ]; then
  SL_BRANCH=$(cache_get "git-branch" "timeout 2 git --no-optional-locks -C '$clean_cwd' symbolic-ref --short HEAD 2>/dev/null || timeout 2 git --no-optional-locks -C '$clean_cwd' rev-parse --short HEAD 2>/dev/null" 5)
  [ -z "$SL_BRANCH" ] && SL_BRANCH="no-git"

  if [ "$SL_BRANCH" != "no-git" ]; then
    remote_url=$(cache_get "git-remote" "timeout 2 git --no-optional-locks -C '$clean_cwd' remote get-url origin" 10)
    if [ -n "$remote_url" ]; then
      gh_user=$(echo "$remote_url" | sed 's|.*github\.com[:/]\([^/]*\)/.*|\1|')
      [ "$gh_user" = "$remote_url" ] && gh_user=""
      gh_repo=$(echo "$remote_url" | sed 's|.*/\([^/]*\)\.git$|\1|; s|.*/\([^/]*\)$|\1|')
      [ "$gh_repo" = "$remote_url" ] && gh_repo=""
    fi

    # Dirty check (shorter cache — changes more often)
    _staged=$(cache_get "git-staged" "timeout 2 git --no-optional-locks -C '$clean_cwd' diff --cached --quiet 2>/dev/null && echo clean || echo dirty" 3)
    _unstaged=$(cache_get "git-unstaged" "timeout 2 git --no-optional-locks -C '$clean_cwd' diff --quiet 2>/dev/null && echo clean || echo dirty" 3)
    [ "$_staged" = "dirty" ] && SL_GIT_DIRTY="${CLR_GIT_STAGED}+${CLR_RST}"
    [ "$_unstaged" = "dirty" ] && SL_GIT_DIRTY="${SL_GIT_DIRTY}${CLR_GIT_UNSTAGED}~${CLR_RST}"
  fi
fi

if [ -n "$gh_repo" ]; then
  SL_GITHUB="${gh_user}/${gh_repo}/${SL_BRANCH}"
else
  SL_GITHUB="$SL_BRANCH"
fi

# --- Cost ---
cost_raw="${SL_J_cost_total_cost_usd:-0}"
if [ -z "$cost_raw" ] || [ "$cost_raw" = "0" ]; then
  SL_COST='$0.00'
else
  SL_COST=$(awk -v c="$cost_raw" 'BEGIN { if (c < 0.01) printf "$%.4f", c; else printf "$%.2f", c }')
fi

# --- Tokens (window vs cumulative) ---
SL_TOKENS_WIN_IN=$(fmt_tok "$cur_input")
SL_TOKENS_WIN_OUT=$(fmt_tok "$cur_output")

cum_input="${SL_J_context_window_total_input_tokens:-0}"
cum_output="${SL_J_context_window_total_output_tokens:-0}"
SL_TOKENS_CUM_IN=$(fmt_tok "$cum_input")
SL_TOKENS_CUM_OUT=$(fmt_tok "$cum_output")

# --- Skill detection (with caching) ---
SL_SKILL="Idle"

_detect_skill() {
  local cwd="$1"
  local tpath="" search_path="$cwd" proj_hash proj_dir

  while [ -n "$search_path" ] && [ "$search_path" != "/" ]; do
    proj_hash=$(echo "$search_path" | sed 's|^/\([a-zA-Z]\)/|\U\1--|; s|^[A-Z]:/|&|; s|:/|--|; s|/|-|g')
    proj_dir="$HOME/.claude/projects/${proj_hash}"
    if [ -d "$proj_dir" ]; then
      tpath=$(ls -t "$proj_dir"/*.jsonl 2>/dev/null | head -1)
      [ -n "$tpath" ] && break
    fi
    search_path=$(echo "$search_path" | sed 's|/[^/]*$||')
  done

  if [ -n "$tpath" ] && [ -f "$tpath" ]; then
    local last_tool
    last_tool=$(tail -50 "$tpath" 2>/dev/null | grep -o '"type":"tool_use","id":"[^"]*","name":"[^"]*"' | tail -1 | sed 's/.*"name":"\([^"]*\)".*/\1/')

    if [ -n "$last_tool" ]; then
      case "$last_tool" in
        Task)            echo "Agent" ;;
        Read)            echo "Read" ;;
        Write)           echo "Write" ;;
        Edit)            echo "Edit" ;;
        MultiEdit)       echo "Multi Edit" ;;
        Glob)            echo "Search(Files)" ;;
        Grep)            echo "Search(Content)" ;;
        Bash)            echo "Terminal" ;;
        WebSearch)       echo "Web Search" ;;
        WebFetch)        echo "Web Fetch" ;;
        Skill)           echo "Skill" ;;
        AskUserQuestion) echo "Asking..." ;;
        EnterPlanMode)   echo "Planning" ;;
        ExitPlanMode)    echo "Plan Ready" ;;
        TaskCreate)      echo "Task Create" ;;
        TaskUpdate)      echo "Task Update" ;;
        NotebookEdit)    echo "Notebook" ;;
        *)               echo "$last_tool" ;;
      esac
      return
    fi
  fi

  echo "Idle"
}

if [ -n "$clean_cwd" ]; then
  SL_SKILL=$(cache_get "skill-label" "_detect_skill '$clean_cwd'" 5)
fi

# --- Extra fields ---
dur_ms="${SL_J_cost_total_duration_ms:-0}"
SL_DURATION=$(fmt_duration "$dur_ms")

SL_LINES_ADDED="${SL_J_cost_total_lines_added:-0}"
SL_LINES_REMOVED="${SL_J_cost_total_lines_removed:-0}"

api_ms="${SL_J_cost_total_api_duration_ms:-0}"
SL_API_DURATION=$(fmt_duration "$api_ms")

SL_VIM_MODE=""
[ "$cfg_show_vim" = "true" ] && SL_VIM_MODE="${SL_J_vim_mode}"

SL_AGENT_NAME=""
[ "$cfg_show_agent" = "true" ] && SL_AGENT_NAME="${SL_J_agent_name}"

SL_CACHE_CREATE=$(fmt_tok "$cur_cache_create")
SL_CACHE_READ=$(fmt_tok "$cur_cache_read")

SL_BURN_RATE=""
if [ "$cfg_show_burn_rate" = "true" ] && [ "$dur_ms" -gt 60000 ] 2>/dev/null; then
  SL_BURN_RATE=$(awk -v cost="$cost_raw" -v ms="$dur_ms" \
    'BEGIN { if (ms > 0 && cost+0 > 0) { rate = cost / (ms / 60000); printf "$%.2f/m", rate } }')
fi

SL_EXCEEDS_200K="${SL_J_exceeds_200k_tokens}"
SL_VERSION="${SL_J_version}"
SL_SESSION_ID="${SL_J_session_id:-unknown}"

# --- Session Limit Tracking & Multi-Level Warnings ---
# Plan limits (approximate — Claude Code subscription tiers)
# Free: ~$5/session, Pro: varies, Max: higher
# We track context % as the primary limit indicator

# Session cost estimation
session_cost_usd="${cost_raw}"
SL_SESSION_COST="${SL_COST}"

# Estimated cost per API call (accurate: total_cost / api_call_count)
SL_EST_COST_ACTION=""

# Multi-level context warnings (3 levels + final at 95%)
# Level 1: 75% — "Approaching limit"
# Level 2: 85% — "Context high"
# Level 3: 90% — "Critical — save your work"
# Final:   95% — "STOP — 5% remaining, completing safely"
SL_SESSION_WARNING=""
SL_SESSION_WARN_LEVEL=0
if [ "$SL_CTX_PCT" -ge 95 ] 2>/dev/null; then
  SL_SESSION_WARNING="${CLR_CTX_CRIT}${CLR_BOLD}LIMIT 5%! Finishing safely...${CLR_RST}"
  SL_SESSION_WARN_LEVEL=4
elif [ "$SL_CTX_PCT" -ge 90 ] 2>/dev/null; then
  SL_SESSION_WARNING="${CLR_CTX_CRIT}${CLR_BOLD}CRITICAL ${SL_CTX_REMAINING}% — Save work!${CLR_RST}"
  SL_SESSION_WARN_LEVEL=3
elif [ "$SL_CTX_PCT" -ge 85 ] 2>/dev/null; then
  SL_SESSION_WARNING="${CLR_CTX_HIGH}HIGH ${SL_CTX_REMAINING}% remaining${CLR_RST}"
  SL_SESSION_WARN_LEVEL=2
elif [ "$SL_CTX_PCT" -ge 75 ] 2>/dev/null; then
  SL_SESSION_WARNING="${CLR_CTX_MED}Approaching limit (${SL_CTX_REMAINING}% left)${CLR_RST}"
  SL_SESSION_WARN_LEVEL=1
fi

# --- Active Agent & Cron Detection ---
SL_ACTIVE_AGENTS=0
SL_ACTIVE_CRONS=0
SL_API_CALLS=0

# Locate the current session transcript
_find_transcript() {
  local cwd="$1"
  local tpath="" search_path="$cwd" proj_hash proj_dir
  while [ -n "$search_path" ] && [ "$search_path" != "/" ]; do
    proj_hash=$(echo "$search_path" | sed 's|^/\([a-zA-Z]\)/|\U\1--|; s|^[A-Z]:/|&|; s|:/|--|; s|/|-|g')
    proj_dir="$HOME/.claude/projects/${proj_hash}"
    if [ -d "$proj_dir" ]; then
      tpath=$(ls -t "$proj_dir"/*.jsonl 2>/dev/null | head -1)
      [ -n "$tpath" ] && break
    fi
    search_path=$(echo "$search_path" | sed 's|/[^/]*$||')
  done
  echo "$tpath"
}

# Detect active agents by matching Agent tool_use IDs to their tool_results
_detect_agents() {
  local tpath="$1"
  if [ -n "$tpath" ] && [ -f "$tpath" ]; then
    # Extract Agent tool_use IDs and tool_result IDs from recent transcript
    # Agent calls: "type":"tool_use","id":"toolu_XXX","name":"Agent"
    # Completions: "tool_use_id":"toolu_XXX" in tool_result entries
    local tail_data
    tail_data=$(tail -500 "$tpath" 2>/dev/null)

    # Get all Agent tool_use IDs (started)
    local started_ids
    started_ids=$(echo "$tail_data" | grep -o '"id":"toolu_[^"]*","name":"Agent"' 2>/dev/null | grep -o 'toolu_[^"]*' | sort)

    if [ -z "$started_ids" ]; then
      echo 0
      return
    fi

    # Get all completed tool_result IDs
    local completed_ids
    completed_ids=$(echo "$tail_data" | grep -o '"tool_use_id":"toolu_[^"]*"' 2>/dev/null | grep -o 'toolu_[^"]*' | sort)

    # Count started IDs not found in completed IDs
    local active=0
    for id in $started_ids; do
      if ! echo "$completed_ids" | grep -q "^${id}$" 2>/dev/null; then
        active=$((active + 1))
      fi
    done

    # Cap at reasonable max
    [ "$active" -gt 20 ] && active=0
    echo "$active"
  else
    echo 0
  fi
}

# Detect active cron jobs
_detect_crons() {
  # Check for active cron jobs in ~/.claude/cron/ or similar
  local count=0
  if [ -d "$HOME/.claude/cron" ]; then
    count=$(ls "$HOME/.claude/cron/"*.json 2>/dev/null | wc -l)
  fi
  # Also check the cron registry if it exists
  if [ -f "$HOME/.claude/cron-registry.json" ]; then
    local cron_count
    cron_count=$(grep -c '"schedule"' "$HOME/.claude/cron-registry.json" 2>/dev/null || echo 0)
    [ "$cron_count" -gt "$count" ] && count="$cron_count"
  fi
  echo "$count"
}

# Count API calls from transcript (actual API interactions, not lines_added)
_count_api_calls() {
  local tpath="$1"
  if [ -n "$tpath" ] && [ -f "$tpath" ]; then
    # Each assistant response = 1 API call; count "type":"assistant" entries
    local api_count
    api_count=$(grep -c '"role":"assistant"' "$tpath" 2>/dev/null || echo 0)
    echo "$api_count"
  else
    echo 0
  fi
}

if [ -n "$clean_cwd" ]; then
  _sl_transcript=$(cache_get "transcript-path" "_find_transcript '$clean_cwd'" 10)
  SL_ACTIVE_AGENTS=$(cache_get "active-agents" "_detect_agents '$_sl_transcript'" 3)
  SL_ACTIVE_CRONS=$(cache_get "active-crons" "_detect_crons" 10)
  SL_API_CALLS=$(cache_get "api-calls" "_count_api_calls '$_sl_transcript'" 5)
  [ -z "$SL_ACTIVE_AGENTS" ] && SL_ACTIVE_AGENTS=0
  [ -z "$SL_ACTIVE_CRONS" ] && SL_ACTIVE_CRONS=0
  [ -z "$SL_API_CALLS" ] && SL_API_CALLS=0
fi

# Format agent display
SL_AGENTS_DISPLAY=""
if [ "$SL_ACTIVE_AGENTS" -gt 0 ] 2>/dev/null; then
  SL_AGENTS_DISPLAY="${CLR_AGENT_ACTIVE}${SL_ACTIVE_AGENTS} agents${CLR_RST}"
fi

# Format cron display
SL_CRONS_DISPLAY=""
if [ "$SL_ACTIVE_CRONS" -gt 0 ] 2>/dev/null; then
  SL_CRONS_DISPLAY="${CLR_CRON_ACTIVE}${SL_ACTIVE_CRONS} cron${CLR_RST}"
fi

# Compute cost per API call now that SL_API_CALLS is known
if [ "$SL_API_CALLS" -gt 0 ] 2>/dev/null && [ "$session_cost_usd" != "0" ] 2>/dev/null; then
  SL_EST_COST_ACTION=$(awk -v cost="$session_cost_usd" -v calls="$SL_API_CALLS" \
    'BEGIN { if (calls > 0) printf "$%.4f", cost / calls }')
fi

# Format session info line
SL_SESSION_TOKENS_TOTAL=$(fmt_tok $(( cum_input + cum_output )))
SL_SESSION_INFO="${SL_SESSION_TOKENS_TOTAL} total (${SL_API_CALLS} calls)"

# ── 8. Dynamic column widths ──
SL_C1=$(( SL_TERM_WIDTH / 2 - 4 ))
[ "$SL_C1" -lt 25 ] && SL_C1=25
[ "$SL_C1" -gt 42 ] && SL_C1=42

# ── 9. Source layout and render ──
layout_file="${STATUSLINE_DIR}/layouts/${active_layout}.sh"
if [ -f "$layout_file" ]; then
  source "$layout_file"
else
  source "${STATUSLINE_DIR}/layouts/standard.sh"
fi

render_layout

