#!/usr/bin/env bash
# Theme: Tokyo Night (vibrant neon)
THEME_NAME="Tokyo Night"

CLR_RST='\033[0m'
CLR_BOLD='\033[1m'
CLR_DIM='\033[2m'

CLR_SKILL='\033[38;2;255;117;127m'       # Red/pink
CLR_MODEL='\033[38;2;187;154;247m'       # Purple
CLR_DIR='\033[38;2;125;207;255m'         # Cyan
CLR_GITHUB='\033[38;2;192;202;245m'      # Foreground
CLR_TOKENS='\033[38;2;224;175;104m'      # Yellow/orange
CLR_COST='\033[38;2;158;206;106m'        # Green
CLR_VIM='\033[38;2;115;218;202m'         # Teal
CLR_AGENT='\033[38;2;122;162;247m'       # Blue

CLR_CTX_LOW='\033[38;2;192;202;245m'     # Foreground
CLR_CTX_MED='\033[38;2;255;158;100m'     # Orange
CLR_CTX_HIGH='\033[38;2;247;118;142m'    # Red
CLR_CTX_CRIT='\033[38;2;219;75;75m'      # Deep red

CLR_SEP='\033[38;2;59;66;97m'            # Comment color
CLR_BAR_EMPTY='\033[38;2;41;46;66m'      # Dark bg
CLR_LABEL='\033[38;2;86;95;137m'         # Muted

CLR_GIT_STAGED='\033[38;2;158;206;106m'
CLR_GIT_UNSTAGED='\033[38;2;224;175;104m'

# Session limit warning colors
CLR_WARN_LOW='\033[38;2;224;175;104m'      # Yellow — Level 1 (75%)
CLR_WARN_MED='\033[38;2;255;158;100m'      # Orange — Level 2 (85%)
CLR_WARN_HIGH='\033[38;2;247;118;142m'     # Red — Level 3 (90%)
CLR_WARN_CRIT='\033[38;2;219;75;75m'       # Deep red — Final (95%)
CLR_AGENT_ACTIVE='\033[38;2;122;162;247m'  # Blue — Active agents
CLR_CRON_ACTIVE='\033[38;2;115;218;202m'   # Teal — Active cron

BAR_FILLED='█'
BAR_EMPTY='░'
SEP_CHAR='│'
