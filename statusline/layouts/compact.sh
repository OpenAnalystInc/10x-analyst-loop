#!/usr/bin/env bash
# Layout: Compact (2 rows — minimal for narrow terminals)
# Row 1: Model │ Dir │ Cost  Context%
# Row 2: Context bar

render_layout() {
  local S
  S=$(printf '%b' " ${CLR_SEP}${SEP_CHAR}${CLR_RST} ")

  # Row 1: Model │ Dir │ Cost + Context%
  printf ' '
  rpad "${CLR_MODEL}${CLR_BOLD}${SL_MODEL}${CLR_RST}" 16
  printf '%b' "$S"
  rpad "${CLR_DIR}${SL_DIR}${CLR_RST}" 22
  printf '%b' "$S"
  printf '%b\n' "${CTX_CLR}${SL_CTX_PCT}%%${CLR_RST} ${CLR_COST}${SL_COST}${CLR_RST}"

  # Row 2: Context bar
  printf ' '
  printf '%b' "${CTX_CLR}Context:${CLR_RST} ${SL_CTX_BAR}${SL_COMPACT_WARNING}"
}
