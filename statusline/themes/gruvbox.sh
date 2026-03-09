#!/usr/bin/env bash
# Theme: Gruvbox Dark (retro groovy)
THEME_NAME="Gruvbox"

CLR_RST='\033[0m'
CLR_BOLD='\033[1m'
CLR_DIM='\033[2m'

CLR_SKILL='\033[38;2;211;134;155m'       # Red
CLR_MODEL='\033[38;2;177;98;134m'        # Purple
CLR_DIR='\033[38;2;131;165;152m'         # Aqua
CLR_GITHUB='\033[38;2;235;219;178m'      # FG
CLR_TOKENS='\033[38;2;250;189;47m'       # Yellow
CLR_COST='\033[38;2;184;187;38m'         # Green
CLR_VIM='\033[38;2;131;165;152m'         # Aqua
CLR_AGENT='\033[38;2;69;133;136m'        # Blue

CLR_CTX_LOW='\033[38;2;235;219;178m'     # FG
CLR_CTX_MED='\033[38;2;254;128;25m'      # Orange
CLR_CTX_HIGH='\033[38;2;251;73;52m'      # Red
CLR_CTX_CRIT='\033[38;2;204;36;29m'      # Dark red

CLR_SEP='\033[38;2;80;73;69m'            # BG2
CLR_BAR_EMPTY='\033[38;2;60;56;54m'      # BG1
CLR_LABEL='\033[38;2;124;111;100m'       # Gray

CLR_GIT_STAGED='\033[38;2;184;187;38m'
CLR_GIT_UNSTAGED='\033[38;2;250;189;47m'

# Session limit warning colors
CLR_WARN_LOW='\033[38;2;250;189;47m'       # Yellow — Level 1 (75%)
CLR_WARN_MED='\033[38;2;254;128;25m'       # Orange — Level 2 (85%)
CLR_WARN_HIGH='\033[38;2;251;73;52m'       # Red — Level 3 (90%)
CLR_WARN_CRIT='\033[38;2;204;36;29m'       # Dark red — Final (95%)
CLR_AGENT_ACTIVE='\033[38;2;69;133;136m'   # Blue — Active agents
CLR_CRON_ACTIVE='\033[38;2;131;165;152m'   # Aqua — Active cron

BAR_FILLED='█'
BAR_EMPTY='░'
SEP_CHAR='│'
