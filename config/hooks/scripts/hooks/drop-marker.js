#!/usr/bin/env node
/**
 * Drops a workflow marker for the current branch.
 * Usage: node drop-marker.js <skill-name>
 * Example: node drop-marker.js review
 *
 * Called after /review or /qa completes to record that
 * the skill was run on this branch. Pre-push-reminder
 * checks for these markers.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const skill = process.argv[2];
if (!skill) {
  process.stderr.write('Usage: drop-marker.js <skill-name>\n');
  process.exit(1);
}

const r = spawnSync('git', ['branch', '--show-current'], { encoding: 'utf8' });
const branch = r.status === 0 ? r.stdout.trim() : null;
if (!branch) process.exit(0);

const markerDir = path.join(os.tmpdir(), 'claude-workflow-markers');
fs.mkdirSync(markerDir, { recursive: true });

const slug = branch.replace(/[^a-zA-Z0-9_-]/g, '_');
const markerFile = path.join(markerDir, `${slug}-${skill}`);
fs.writeFileSync(markerFile, new Date().toISOString(), 'utf8');

process.stderr.write(`[marker] ${skill} recorded for branch ${branch}\n`);
