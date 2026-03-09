#!/usr/bin/env bash
# Layout: Full (7 rows — everything + session tracking)
# Row 1: Skill    │  GitHub
# Row 2: Model    │  Dir
# Row 3: Window   │  Cost + burn rate
# Row 4: Session  │  Lines + Duration
# Row 5: Cache    │  Vim/Agent + Active Agents
# Row 6: Session limit bar (multi-level warnings)
# Row 7: Context bar

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

  # Row 3: Window tokens │ Cost + Burn rate
  printf ' '
  local win_label="${SL_TOKENS_WIN_IN} in + ${SL_TOKENS_WIN_OUT} out"
  if [ "$cur_input" -eq 0 ] 2>/dev/null && [ "$cum_input" -gt 0 ] 2>/dev/null; then
    win_label="${SL_TOKENS_CUM_IN} in + ${SL_TOKENS_CUM_OUT} out"
  fi
  rpad "${CLR_TOKENS}Tokens:${CLR_RST} ${CLR_TOKENS}${win_label}${CLR_RST}" "$C1"
  printf '%b' "$S"
  local cost_display="${CLR_COST}Cost:${CLR_RST} ${CLR_COST}${SL_COST}${CLR_RST}"
  [ -n "$SL_BURN_RATE" ] && cost_display="${cost_display} ${CLR_LABEL}(${SL_BURN_RATE})${CLR_RST}"
  printf '%b\n' "$cost_display"

  # Row 4: Session total │ Lines + Duration
  printf ' '
  rpad "${CLR_TOKENS}Session:${CLR_RST} ${CLR_LABEL}${SL_SESSION_INFO}${CLR_RST}" "$C1"
  printf '%b' "$S"
  printf '%b\n' "${CLR_LABEL}+${SL_LINES_ADDED}/-${SL_LINES_REMOVED}  ${SL_DURATION}${CLR_RST}"

  # Row 5: Cache │ Vim/Agent + Active Agents
  printf ' '
  rpad "${CLR_AGENT}Cache:${CLR_RST} ${CLR_LABEL}W:${SL_CACHE_CREATE} R:${SL_CACHE_READ}${CLR_RST}" "$C1"
  printf '%b' "$S"
  local vim_agent=""
  if [ -n "$SL_VIM_MODE" ] && [ "$SL_VIM_MODE" != "null" ]; then
    vim_agent="${CLR_VIM}${SL_VIM_MODE}${CLR_RST}"
  fi
  if [ -n "$SL_AGENT_NAME" ] && [ "$SL_AGENT_NAME" != "null" ]; then
    [ -n "$vim_agent" ] && vim_agent="${vim_agent} "
    vim_agent="${vim_agent}${CLR_AGENT}@${SL_AGENT_NAME}${CLR_RST}"
  fi
  if [ -n "$SL_AGENTS_DISPLAY" ]; then
    [ -n "$vim_agent" ] && vim_agent="${vim_agent} "
    vim_agent="${vim_agent}${SL_AGENTS_DISPLAY}"
  fi
  if [ -n "$SL_CRONS_DISPLAY" ]; then
    [ -n "$vim_agent" ] && vim_agent="${vim_agent} "
    vim_agent="${vim_agent}${SL_CRONS_DISPLAY}"
  fi
  printf '%b\n' "$vim_agent"

  # Row 6: Session limit warnings (if any)
  if [ "$SL_SESSION_WARN_LEVEL" -gt 0 ] 2>/dev/null; then
    printf ' '
    printf '%b\n' "${SL_SESSION_WARNING}"
  fi

  # Row 7: Context bar (full width)
  printf ' '
  printf '%b' "${CTX_CLR}Context:${CLR_RST} ${SL_CTX_BAR}${SL_COMPACT_WARNING}"
}
