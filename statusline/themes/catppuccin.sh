#!/usr/bin/env bash
# Theme: Catppuccin Mocha (warm pastels)
THEME_NAME="Catppuccin"

CLR_RST='\033[0m'
CLR_BOLD='\033[1m'
CLR_DIM='\033[2m'

CLR_SKILL='\033[38;2;245;194;231m'       # Pink
CLR_MODEL='\033[38;2;203;166;247m'       # Mauve
CLR_DIR='\033[38;2;137;220;235m'         # Sky
CLR_GITHUB='\033[38;2;205;214;244m'      # Text
CLR_TOKENS='\033[38;2;249;226;175m'      # Yellow
CLR_COST='\033[38;2;166;227;161m'        # Green
CLR_VIM='\033[38;2;148;226;213m'         # Teal
CLR_AGENT='\033[38;2;137;180;250m'       # Blue

CLR_CTX_LOW='\033[38;2;205;214;244m'     # Text
CLR_CTX_MED='\033[38;2;250;179;135m'     # Peach
CLR_CTX_HIGH='\033[38;2;243;139;168m'    # Red
CLR_CTX_CRIT='\033[38;2;235;111;146m'    # Maroon

CLR_SEP='\033[38;2;69;71;90m'            # Surface 1
CLR_BAR_EMPTY='\033[38;2;49;50;68m'      # Surface 0
CLR_LABEL='\033[38;2;108;112;134m'       # Overlay 0

CLR_GIT_STAGED='\033[38;2;166;227;161m'
CLR_GIT_UNSTAGED='\033[38;2;249;226;175m'

# Session limit warning colors
CLR_WARN_LOW='\033[38;2;249;226;175m'      # Yellow — Level 1 (75%)
CLR_WARN_MED='\033[38;2;250;179;135m'      # Peach — Level 2 (85%)
CLR_WARN_HIGH='\033[38;2;243;139;168m'     # Red — Level 3 (90%)
CLR_WARN_CRIT='\033[38;2;235;111;146m'     # Maroon — Final (95%)
CLR_AGENT_ACTIVE='\033[38;2;137;180;250m'  # Blue — Active agents
CLR_CRON_ACTIVE='\033[38;2;148;226;213m'   # Teal — Active cron

BAR_FILLED='█'
BAR_EMPTY='░'
SEP_CHAR='│'
