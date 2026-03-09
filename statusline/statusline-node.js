#!/usr/bin/env node
// skill-statusline v2.3 — Node.js statusline renderer
// Zero bash dependency — works on Windows, macOS, Linux
// Async stdin with hard 1.5s timeout to prevent hangs

'use strict';
const fs = require('fs');
const path = require('path');

// Hard kill — prevents hanging if stdin pipe never closes on Windows
setTimeout(() => process.exit(0), 1500);

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => input += c);
process.stdin.on('end', () => {
  try { if (input) render(JSON.parse(input)); } catch (e) {}
  process.exit(0);
});
process.stdin.on('error', () => process.exit(0));
process.stdin.resume();

function getActivity(transcriptPath) {
  if (!transcriptPath) return 'Idle';
  try {
    const stat = fs.statSync(transcriptPath);
    const readSize = Math.min(16384, stat.size);
    const buf = Buffer.alloc(readSize);
    const fd = fs.openSync(transcriptPath, 'r');
    fs.readSync(fd, buf, 0, readSize, Math.max(0, stat.size - readSize));
    fs.closeSync(fd);
    const lines = buf.toString('utf8').split('\n').filter(l => l.trim());
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const entry = JSON.parse(lines[i]);
        if (entry.type === 'assistant' && Array.isArray(entry.message?.content)) {
          const toolUses = entry.message.content.filter(c => c.type === 'tool_use');
          if (toolUses.length) {
            const last = toolUses[toolUses.length - 1];
            const name = last.name;
            const inp = last.input || {};
            if (name === 'Task' && inp.subagent_type) {
              const desc = inp.description ? ': ' + inp.description.slice(0, 25) : '';
              return `Task(${inp.subagent_type}${desc})`;
            }
            if (name === 'Skill' && inp.skill) return `Skill(${inp.skill})`;
            return name;
          }
        }
      } catch (e) { continue; }
    }
  } catch (e) { /* ignore */ }
  return 'Idle';
}

function getGitInfo(projectDir) {
  let branch = '', remote = '';
  try {
    const gitHead = fs.readFileSync(path.join(projectDir, '.git', 'HEAD'), 'utf8').trim();
    branch = gitHead.startsWith('ref: refs/heads/') ? gitHead.slice(16) : gitHead.slice(0, 7);
  } catch (e) { return 'no-git'; }
  try {
    const config = fs.readFileSync(path.join(projectDir, '.git', 'config'), 'utf8');
    const urlMatch = config.match(/\[remote "origin"\][^[]*url\s*=\s*(.+)/);
    if (urlMatch) {
      const url = urlMatch[1].trim();
      const ghMatch = url.match(/github\.com[:/]([^/]+)\/([^/.]+)/);
      if (ghMatch) remote = ghMatch[1] + '/' + ghMatch[2];
    }
  } catch (e) { /* ignore */ }
  return remote ? `${remote}:${branch}` : branch;
}

function render(data) {
  const RST = '\x1b[0m', BOLD = '\x1b[1m';
  const CYAN = '\x1b[38;2;6;182;212m', PURPLE = '\x1b[38;2;168;85;247m';
  const GREEN = '\x1b[38;2;34;197;94m', YELLOW = '\x1b[38;2;245;158;11m';
  const RED = '\x1b[38;2;239;68;68m', ORANGE = '\x1b[38;2;251;146;60m';
  const WHITE = '\x1b[38;2;228;228;231m';
  const SEP = '\x1b[38;2;55;55;62m', DIM = '\x1b[38;2;140;140;150m';
  const BAR_DIM = '\x1b[38;2;40;40;45m';
  const BLUE = '\x1b[38;2;59;130;246m';

  const model = data.model?.display_name || 'unknown';

  const cwd = (data.workspace?.current_dir || data.cwd || '').replace(/\\/g, '/').replace(/\/\/+/g, '/');
  const parts = cwd.split('/').filter(Boolean);
  const dir = parts.length > 3 ? parts.slice(-3).join('/') : parts.length > 0 ? parts.join('/') : '~';

  const projectDir = data.workspace?.project_dir || data.workspace?.current_dir || data.cwd || '';
  const gitInfo = getGitInfo(projectDir);

  const activity = getActivity(data.transcript_path);

  let pct = Math.floor(data.context_window?.used_percentage || 0);
  if (pct > 100) pct = 100;
  const ctxClr = pct > 90 ? RED : pct > 75 ? ORANGE : pct > 40 ? YELLOW : WHITE;
  const barW = 40;
  const filled = Math.min(Math.floor(pct * barW / 100), barW);
  const bar = ctxClr + '\u2588'.repeat(filled) + RST + BAR_DIM + '\u2591'.repeat(barW - filled) + RST;

  const costRaw = data.cost?.total_cost_usd || 0;
  const cost = costRaw === 0 ? '$0.00' : costRaw < 0.01 ? `$${costRaw.toFixed(4)}` : `$${costRaw.toFixed(2)}`;

  const fmtTok = n => n >= 1000000 ? `${(n/1000000).toFixed(1)}M` : n >= 1000 ? `${(n/1000).toFixed(1)}k` : `${n}`;
  const totIn = data.context_window?.total_input_tokens || 0;
  const totOut = data.context_window?.total_output_tokens || 0;
  const tokTotal = fmtTok(totIn + totOut);
  const tokIn = fmtTok(totIn);
  const tokOut = fmtTok(totOut);

  const durMs = data.cost?.total_duration_ms || 0;
  const durMin = Math.floor(durMs / 60000);
  const durSec = Math.floor((durMs % 60000) / 1000);
  const duration = durMin > 0 ? `${durMin}m ${durSec}s` : `${durSec}s`;

  const linesAdded = data.cost?.total_lines_added || 0;
  const linesRemoved = data.cost?.total_lines_removed || 0;

  // Count API calls from transcript for accurate cost-per-call
  let apiCalls = 0;
  try {
    if (data.transcript_path && fs.existsSync(data.transcript_path)) {
      const stat = fs.statSync(data.transcript_path);
      const readSize = Math.min(65536, stat.size);
      const buf = Buffer.alloc(readSize);
      const fd = fs.openSync(data.transcript_path, 'r');
      fs.readSync(fd, buf, 0, readSize, Math.max(0, stat.size - readSize));
      fs.closeSync(fd);
      const content = buf.toString('utf8');
      apiCalls = (content.match(/"role":"assistant"/g) || []).length;
    }
  } catch (e) { /* ignore */ }

  const costPerCall = apiCalls > 0 && costRaw > 0 ? `$${(costRaw / apiCalls).toFixed(4)}/call` : '';

  // Session limit warnings
  const AMBER = '\x1b[38;2;251;191;36m', DEEP_RED = '\x1b[38;2;220;38;38m';
  let warnLevel = 0, warnMsg = '';
  if (pct >= 95) { warnLevel = 4; warnMsg = `${DEEP_RED}${BOLD}LIMIT 5%! Finishing safely...${RST}`; }
  else if (pct >= 90) { warnLevel = 3; warnMsg = `${RED}${BOLD}CRITICAL ${100 - pct}% — Save work!${RST}`; }
  else if (pct >= 85) { warnLevel = 2; warnMsg = `${ORANGE}HIGH ${100 - pct}% remaining${RST}`; }
  else if (pct >= 75) { warnLevel = 1; warnMsg = `${AMBER}Approaching limit (${100 - pct}% left)${RST}`; }

  const actClr = activity === 'Idle' ? DIM : GREEN;

  const S = `  ${SEP}\u2502${RST}  `;
  const rpad = (s, w) => {
    const plain = s.replace(/\x1b\[[0-9;]*m/g, '');
    return s + (plain.length < w ? ' '.repeat(w - plain.length) : '');
  };
  const C1 = 44;

  // Compute burn rate (cost per minute)
  let burnRate = '';
  if (durMs > 60000 && costRaw > 0) {
    const rate = costRaw / (durMs / 60000);
    burnRate = `$${rate.toFixed(2)}/m`;
  }

  // Current window tokens (from current_usage if available)
  const curIn = data.context_window?.current_usage?.input_tokens || 0;
  const curOut = data.context_window?.current_usage?.output_tokens || 0;
  const curCacheCreate = data.context_window?.current_usage?.cache_creation_input_tokens || 0;
  const curCacheRead = data.context_window?.current_usage?.cache_read_input_tokens || 0;

  let out = '';
  out += ' ' + rpad(`${actClr}Action:${RST} ${actClr}${activity}${RST}`, C1) + S + `${WHITE}Git:${RST} ${WHITE}${gitInfo}${RST}\n`;
  out += ' ' + rpad(`${PURPLE}Model:${RST} ${PURPLE}${BOLD}${model}${RST}`, C1) + S + `${CYAN}Dir:${RST} ${CYAN}${dir}${RST}\n`;
  out += ' ' + rpad(`${YELLOW}Tokens:${RST} ${YELLOW}${tokIn} in + ${tokOut} out = ${BOLD}${tokTotal}${RST}`, C1) + S + `${GREEN}Cost:${RST} ${GREEN}${cost}${RST}${burnRate ? ` ${DIM}(${burnRate})${RST}` : ''}\n`;

  // Session row: API calls, cost/call, lines, duration
  const callInfo = apiCalls > 0 ? `${apiCalls} calls` : '';
  const costCallInfo = costPerCall ? ` ${costPerCall}` : '';
  const sessionLeft = `+${linesAdded}/-${linesRemoved}  ${duration}`;
  out += ' ' + rpad(`${BLUE}Session:${RST} ${BLUE}${callInfo}${costCallInfo}${RST} ${DIM}${sessionLeft}${RST}`, C1) + S + `${ctxClr}Context:${RST} ${bar} ${ctxClr}${pct}%${RST}`;

  if (warnLevel > 0) {
    out += '\n ' + warnMsg;
  }

  process.stdout.write(out);
}
