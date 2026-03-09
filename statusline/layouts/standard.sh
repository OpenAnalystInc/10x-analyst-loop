#!/usr/bin/env bash
# Layout: Standard (4 rows — default, backward compatible)
# Row 1: Skill    │  GitHub
# Row 2: Model    │  Dir
# Row 3: Window   │  Cost
# Row 4: Context (wide bar)

render_layout() {
  local C1="$SL_C1"
  local S
  S=$(printf '%b' "  ${CLR_SEP}${SEP_CHAR}${CLR_RST}  ")

  # Row 1: Skill │ GitHub
  printf ' '
  rpad "${CLR_SKILL}Skill:${CLR_RST} ${CLR_SKILL}${SL_SKILL}${CLR_RST}" "$C1"
  printf '%b' "$S"
  printf '%b\n' "${CLR_GITHUB}GitHub:${CLR_RST} ${CLR_GITHUB}${SL_GITHUB}${CLR_RST}${SL_GIT_DIRTY}"

  # Row 2: Model │ Dir
  printf ' '
  rpad "${CLR_MODEL}Model:${CLR_RST} ${CLR_MODEL}${CLR_BOLD}${SL_MODEL}${CLR_RST}" "$C1"
  printf '%b' "$S"
  printf '%b\n' "${CLR_DIR}Dir:${CLR_RST} ${CLR_DIR}${SL_DIR}${CLR_RST}"

  # Row 3: Window tokens │ Cost
  printf ' '
  local win_label="${SL_TOKENS_WIN_IN} + ${SL_TOKENS_WIN_OUT}"
  # If window tokens are 0 (before first API call), show cumulative instead
  if [ "$cur_input" -eq 0 ] 2>/dev/null && [ "$cum_input" -gt 0 ] 2>/dev/null; then
    win_label="${SL_TOKENS_CUM_IN} + ${SL_TOKENS_CUM_OUT}"
  fi
  rpad "${CLR_TOKENS}Tokens:${CLR_RST} ${CLR_TOKENS}${win_label}${CLR_RST}" "$C1"
  printf '%b' "$S"
  printf '%b\n' "${CLR_COST}Cost:${CLR_RST} ${CLR_COST}${SL_COST}${CLR_RST}"

  # Row 4: Agents/Cron (conditional) + Context bar
  local status_extra=""
  if [ "$SL_ACTIVE_AGENTS" -gt 0 ] 2>/dev/null; then
    status_extra="${CLR_AGENT_ACTIVE}${SL_ACTIVE_AGENTS}ag${CLR_RST}"
  fi
  if [ "$SL_ACTIVE_CRONS" -gt 0 ] 2>/dev/null; then
    [ -n "$status_extra" ] && status_extra="${status_extra} "
    status_extra="${status_extra}${CLR_CRON_ACTIVE}${SL_ACTIVE_CRONS}cr${CLR_RST}"
  fi

  # Row 4a: Session warning (if any)
  if [ "$SL_SESSION_WARN_LEVEL" -gt 0 ] 2>/dev/null; then
    printf ' '
    printf '%b\n' "${SL_SESSION_WARNING}"
  fi

  # Row 5: Context bar (full width) + inline agent/cron indicators
  printf ' '
  local ctx_suffix="${SL_COMPACT_WARNING}"
  [ -n "$status_extra" ] && ctx_suffix="${ctx_suffix} ${status_extra}"
  printf '%b' "${CTX_CLR}Context:${CLR_RST} ${SL_CTX_BAR}${ctx_suffix}"
}
