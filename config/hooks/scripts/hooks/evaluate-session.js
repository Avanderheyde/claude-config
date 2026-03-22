#!/usr/bin/env node
/**
 * Session Evaluator - Signal when sessions have extractable patterns
 * Adapted from everything-claude-code by @affaan-m
 */

const fs = require('fs');
const { getLearnedSkillsDir, ensureDir, countInFile, log } = require('../lib/utils');

const MAX_STDIN = 1024 * 1024;
let stdinData = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  if (stdinData.length < MAX_STDIN) stdinData += chunk.substring(0, MAX_STDIN - stdinData.length);
});
process.stdin.on('end', () => { main().catch(() => process.exit(0)); });

async function main() {
  let transcriptPath = null;
  try {
    const input = JSON.parse(stdinData);
    transcriptPath = input.transcript_path;
  } catch { /* no transcript */ }

  const learnedSkillsPath = getLearnedSkillsDir();
  ensureDir(learnedSkillsPath);

  if (!transcriptPath || !fs.existsSync(transcriptPath)) process.exit(0);

  const messageCount = countInFile(transcriptPath, /"type"\s*:\s*"user"/g);

  if (messageCount < 10) {
    log(`[ContinuousLearning] Session too short (${messageCount} messages), skipping`);
    process.exit(0);
  }

  log(`[ContinuousLearning] Session has ${messageCount} messages - evaluate for extractable patterns`);
  log(`[ContinuousLearning] Save learned skills to: ${learnedSkillsPath}`);

  process.exit(0);
}
