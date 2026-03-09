#!/usr/bin/env bash
# Layout: 10x-Swarm (8 rows — full agent swarm monitoring + session economics)
# Row 1: Skill    │  GitHub
# Row 2: Model    │  Dir
# Row 3: Tokens (in/out) │  Cost + burn rate
# Row 4: Session (total tokens, API calls)  │  Cost/call + Est. remaining
# Row 5: Cache    │  Vim/Agent
# Row 6: Agents + Cron status bar
# Row 7: Session limit bar (multi-level warnings)
# Row 8: Context bar

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

  # Row 4: Session economics │ Cost per call + Lines
  printf ' '
  rpad "${CLR_TOKENS}Session:${CLR_RST} ${CLR_LABEL}${SL_SESSION_INFO}${CLR_RST}" "$C1"
  printf '%b' "$S"
  local econ_display="${CLR_LABEL}+${SL_LINES_ADDED}/-${SL_LINES_REMOVED}${CLR_RST}"
  if [ -n "$SL_EST_COST_ACTION" ]; then
    econ_display="${CLR_COST}${SL_EST_COST_ACTION}/call${CLR_RST}  ${econ_display}"
  fi
  econ_display="${econ_display}  ${CLR_LABEL}${SL_DURATION}${CLR_RST}"
  printf '%b\n' "$econ_display"

  # Row 5: Cache │ Vim/Agent
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
  printf '%b\n' "$vim_agent"

  # Row 6: Swarm status bar (agents + cron)
  printf ' '
  local swarm_parts=""
  if [ "$SL_ACTIVE_AGENTS" -gt 0 ] 2>/dev/null; then
    local agent_dots=""
    local a=0
    while [ $a -lt "$SL_ACTIVE_AGENTS" ] && [ $a -lt 10 ]; do
      agent_dots="${agent_dots}●"
      a=$((a + 1))
    done
    swarm_parts="${CLR_AGENT_ACTIVE}Agents: ${agent_dots} (${SL_ACTIVE_AGENTS})${CLR_RST}"
  else
    swarm_parts="${CLR_LABEL}Agents: none${CLR_RST}"
  fi

  if [ "$SL_ACTIVE_CRONS" -gt 0 ] 2>/dev/null; then
    local cron_dots=""
    local c=0
    while [ $c -lt "$SL_ACTIVE_CRONS" ] && [ $c -lt 5 ]; do
      cron_dots="${cron_dots}◆"
      c=$((c + 1))
    done
    swarm_parts="${swarm_parts}  ${CLR_SEP}${SEP_CHAR}${CLR_RST}  ${CLR_CRON_ACTIVE}Cron: ${cron_dots} (${SL_ACTIVE_CRONS})${CLR_RST}"
  fi
  printf '%b\n' "$swarm_parts"

  # Row 7: Session limit warnings (if any)
  if [ "$SL_SESSION_WARN_LEVEL" -gt 0 ] 2>/dev/null; then
    printf ' '
    # Build a warning bar with color intensity matching level
    local warn_bar=""
    local warn_clr=""
    case "$SL_SESSION_WARN_LEVEL" in
      1) warn_clr="$CLR_WARN_LOW"  ; warn_bar="▰▰▰▱▱▱▱▱" ;;
      2) warn_clr="$CLR_WARN_MED"  ; warn_bar="▰▰▰▰▰▱▱▱" ;;
      3) warn_clr="$CLR_WARN_HIGH" ; warn_bar="▰▰▰▰▰▰▰▱" ;;
      4) warn_clr="$CLR_WARN_CRIT" ; warn_bar="▰▰▰▰▰▰▰▰" ;;
    esac
    printf '%b\n' "${warn_clr}${warn_bar} ${SL_SESSION_WARNING}${CLR_RST}"
  fi

  # Row 8: Context bar (full width)
  printf ' '
  printf '%b' "${CTX_CLR}Context:${CLR_RST} ${SL_CTX_BAR}${SL_COMPACT_WARNING}"
}
