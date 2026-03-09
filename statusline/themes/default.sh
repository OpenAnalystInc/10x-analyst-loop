#!/usr/bin/env bash
# Theme: Default (skill-statusline classic)
THEME_NAME="Default"

CLR_RST='\033[0m'
CLR_BOLD='\033[1m'
CLR_DIM='\033[2m'

# Semantic field colors
CLR_SKILL='\033[38;2;236;72;153m'       # Pink
CLR_MODEL='\033[38;2;168;85;247m'       # Purple
CLR_DIR='\033[38;2;6;182;212m'          # Cyan
CLR_GITHUB='\033[38;2;228;228;231m'     # White
CLR_TOKENS='\033[38;2;245;158;11m'      # Yellow/Amber
CLR_COST='\033[38;2;34;197;94m'         # Green
CLR_VIM='\033[38;2;20;184;166m'         # Teal
CLR_AGENT='\033[38;2;99;102;241m'       # Blue/Indigo

# Context bar thresholds
CLR_CTX_LOW='\033[38;2;228;228;231m'    # White (<=40%)
CLR_CTX_MED='\033[38;2;251;146;60m'     # Orange (41-75%)
CLR_CTX_HIGH='\033[38;2;239;68;68m'     # Red (76-90%)
CLR_CTX_CRIT='\033[38;2;220;38;38m'     # Deep red (>90%)

# Chrome
CLR_SEP='\033[38;2;55;55;62m'           # Separator pipe
CLR_BAR_EMPTY='\033[38;2;40;40;45m'     # Empty bar segments
CLR_LABEL='\033[38;2;120;120;130m'      # Dimmed secondary text

# Git dirty indicators
CLR_GIT_STAGED='\033[38;2;34;197;94m'   # Green +
CLR_GIT_UNSTAGED='\033[38;2;245;158;11m' # Yellow ~

# Session limit warning colors
CLR_WARN_LOW='\033[38;2;251;191;36m'     # Amber — Level 1 (75%)
CLR_WARN_MED='\033[38;2;249;115;22m'     # Orange — Level 2 (85%)
CLR_WARN_HIGH='\033[38;2;239;68;68m'     # Red — Level 3 (90%)
CLR_WARN_CRIT='\033[38;2;220;38;38m'     # Deep red — Final (95%)
CLR_AGENT_ACTIVE='\033[38;2;99;102;241m' # Indigo — Active agents
CLR_CRON_ACTIVE='\033[38;2;16;185;129m'  # Emerald — Active cron

# Bar characters
BAR_FILLED='█'
BAR_EMPTY='░'
SEP_CHAR='│'
