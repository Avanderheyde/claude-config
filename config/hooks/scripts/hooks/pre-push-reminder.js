#!/usr/bin/env node
/**
 * Pre-push reminder — nudges to run /review and /qa before pushing.
 * Checks for marker files dropped by running those skills.
 * Non-blocking: warns but never prevents the push.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

function getBranch() {
  const r = spawnSync('git', ['branch', '--show-current'], { encoding: 'utf8' });
  return r.status === 0 ? r.stdout.trim() : null;
}

function getMarkerDir() {
  return path.join(os.tmpdir(), 'claude-workflow-markers');
}

function branchSlug(branch) {
  return branch.replace(/[^a-zA-Z0-9_-]/g, '_');
}

function checkMarker(branch, skill) {
  const markerFile = path.join(getMarkerDir(), `${branchSlug(branch)}-${skill}`);
  if (!fs.existsSync(markerFile)) return false;
  const stat = fs.statSync(markerFile);
  const ageHours = (Date.now() - stat.mtimeMs) / (1000 * 60 * 60);
  // Markers older than 24h are stale
  return ageHours < 24;
}

const MAX_STDIN = 1024 * 1024;
let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (raw.length < MAX_STDIN) raw += chunk.substring(0, MAX_STDIN - raw.length);
});
process.stdin.on('end', () => {
  // Only activate on git push commands
  try {
    const input = JSON.parse(raw);
    const cmd = String(input.tool_input?.command || '');
    if (!cmd.match(/\bgit\s+push\b/)) {
      process.exit(0);
    }
  } catch {
    process.exit(0);
  }

  const branch = getBranch();
  if (!branch || branch === 'main' || branch === 'master') {
    process.exit(0);
  }

  const warnings = [];

  if (!checkMarker(branch, 'review')) {
    warnings.push('/review has not been run on this branch');
  }
  if (!checkMarker(branch, 'qa')) {
    warnings.push('/qa has not been run on this branch');
  }

  if (warnings.length > 0) {
    const msg = [
      '⚠️  Pre-push checklist:',
      ...warnings.map(w => `   • ${w}`),
      '   Run these before merging for best results.',
    ].join('\n');
    process.stderr.write(`${msg}\n`);
  }

  process.exit(0);
});
