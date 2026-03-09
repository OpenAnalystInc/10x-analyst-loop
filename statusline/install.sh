#!/usr/bin/env bash
# 10x-analyst-loop — Statusline Installer
# Copies statusline files to ~/.claude/ for Claude Code integration
# Run: bash statusline/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SL_DIR="${CLAUDE_DIR}/statusline"

echo "10x-analyst-loop — Statusline Installer"
echo "========================================"

# Check if Claude Code directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Error: ~/.claude/ directory not found. Is Claude Code installed?"
  exit 1
fi

# Backup existing statusline if present
if [ -d "$SL_DIR" ]; then
  backup_dir="${SL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing statusline to ${backup_dir}..."
  cp -r "$SL_DIR" "$backup_dir"
fi

# Create directories
echo "Creating statusline directories..."
mkdir -p "${SL_DIR}/themes"
mkdir -p "${SL_DIR}/layouts"

# Copy core engine
echo "Installing core engine..."
cp "${SCRIPT_DIR}/core.sh" "${SL_DIR}/core.sh"
cp "${SCRIPT_DIR}/helpers.sh" "${SL_DIR}/helpers.sh"
cp "${SCRIPT_DIR}/json-parser.sh" "${SL_DIR}/json-parser.sh"

# Copy themes
echo "Installing themes (5)..."
for theme in default nord tokyo-night catppuccin gruvbox; do
  if [ -f "${SCRIPT_DIR}/themes/${theme}.sh" ]; then
    cp "${SCRIPT_DIR}/themes/${theme}.sh" "${SL_DIR}/themes/${theme}.sh"
  fi
done

# Copy layouts
echo "Installing layouts (4)..."
for layout in compact standard full 10x-swarm; do
  if [ -f "${SCRIPT_DIR}/layouts/${layout}.sh" ]; then
    cp "${SCRIPT_DIR}/layouts/${layout}.sh" "${SL_DIR}/layouts/${layout}.sh"
  fi
done

# Copy Node.js fallback
echo "Installing Node.js fallback renderer..."
cp "${SCRIPT_DIR}/statusline-node.js" "${CLAUDE_DIR}/statusline-node.js"

# Copy entry point
echo "Installing entry point..."
cp "${SCRIPT_DIR}/statusline-command.sh" "${CLAUDE_DIR}/statusline-command.sh"

# Create default config if not exists
if [ ! -f "${CLAUDE_DIR}/statusline-config.json" ]; then
  echo "Creating default config (10x-swarm layout)..."
  cp "${SCRIPT_DIR}/statusline-config.json" "${CLAUDE_DIR}/statusline-config.json"
  # Set 10x-swarm as default for plugin users
  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PYTHON=$(command -v python3 || command -v python)
    $PYTHON -c "
import json
with open('${CLAUDE_DIR}/statusline-config.json', 'r') as f:
    cfg = json.load(f)
cfg['layout'] = '10x-swarm'
with open('${CLAUDE_DIR}/statusline-config.json', 'w') as f:
    json.dump(cfg, f, indent=2)
" 2>/dev/null || true
  fi
else
  echo "Config already exists, keeping current settings."
fi

# Configure Claude Code settings to use the statusline
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Check if statusline is already configured
  if grep -q "statusline" "$SETTINGS_FILE" 2>/dev/null; then
    echo "Statusline already configured in settings.json"
  else
    echo "Note: Add statusline to ${SETTINGS_FILE} manually:"
    echo '  "statusline": { "command": "bash ~/.claude/statusline-command.sh" }'
  fi
else
  echo "Note: No settings.json found. Create it with:"
  echo '  { "statusline": { "command": "bash ~/.claude/statusline-command.sh" } }'
fi

echo ""
echo "Installation complete!"
echo "  Themes: default, nord, tokyo-night, catppuccin, gruvbox"
echo "  Layouts: compact, standard, full, 10x-swarm"
echo "  Default: 10x-swarm layout with agent/cron monitoring"
echo ""
echo "Restart Claude Code to activate the statusline."
