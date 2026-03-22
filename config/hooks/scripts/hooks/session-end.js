#!/usr/bin/env node
/**
 * Stop Hook - Persist session state after each response
 * Adapted from everything-claude-code by @affaan-m
 */

const path = require('path');
const fs = require('fs');
const { getSessionsDir, getDateString, getTimeString, getSessionIdShort, ensureDir, readFile, writeFile, replaceInFile, log } = require('../lib/utils');

const SUMMARY_START_MARKER = '<!-- ECC:SUMMARY:START -->';
const SUMMARY_END_MARKER = '<!-- ECC:SUMMARY:END -->';

function extractSessionSummary(transcriptPath) {
  const content = readFile(transcriptPath);
  if (!content) return null;

  const lines = content.split('\n').filter(Boolean);
  const userMessages = [];
  const toolsUsed = new Set();
  const filesModified = new Set();

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);

      if (entry.type === 'user' || entry.role === 'user' || entry.message?.role === 'user') {
        const rawContent = entry.message?.content ?? entry.content;
        const text = typeof rawContent === 'string'
          ? rawContent
          : Array.isArray(rawContent)
            ? rawContent.map(c => (c && c.text) || '').join(' ')
            : '';
        if (text.trim()) userMessages.push(text.trim().slice(0, 200));
      }

      if (entry.type === 'tool_use' || entry.tool_name) {
        const toolName = entry.tool_name || entry.name || '';
        if (toolName) toolsUsed.add(toolName);
        const filePath = entry.tool_input?.file_path || entry.input?.file_path || '';
        if (filePath && (toolName === 'Edit' || toolName === 'Write')) filesModified.add(filePath);
      }

      if (entry.type === 'assistant' && Array.isArray(entry.message?.content)) {
        for (const block of entry.message.content) {
          if (block.type === 'tool_use') {
            const toolName = block.name || '';
            if (toolName) toolsUsed.add(toolName);
            const filePath = block.input?.file_path || '';
            if (filePath && (toolName === 'Edit' || toolName === 'Write')) filesModified.add(filePath);
          }
        }
      }
    } catch { /* skip unparseable lines */ }
  }

  if (userMessages.length === 0) return null;

  return {
    userMessages: userMessages.slice(-10),
    toolsUsed: Array.from(toolsUsed).slice(0, 20),
    filesModified: Array.from(filesModified).slice(0, 30),
    totalMessages: userMessages.length
  };
}

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

  const sessionsDir = getSessionsDir();
  const today = getDateString();
  const shortId = getSessionIdShort();
  const sessionFile = path.join(sessionsDir, `${today}-${shortId}-session.tmp`);

  ensureDir(sessionsDir);
  const currentTime = getTimeString();

  let summary = null;
  if (transcriptPath && fs.existsSync(transcriptPath)) {
    summary = extractSessionSummary(transcriptPath);
  }

  if (fs.existsSync(sessionFile)) {
    replaceInFile(sessionFile, /\*\*Last Updated:\*\*.*/, `**Last Updated:** ${currentTime}`);

    if (summary) {
      const existing = readFile(sessionFile);
      if (existing) {
        const summaryBlock = buildSummaryBlock(summary);
        let updatedContent;
        if (existing.includes(SUMMARY_START_MARKER) && existing.includes(SUMMARY_END_MARKER)) {
          updatedContent = existing.replace(
            new RegExp(`${escapeRegExp(SUMMARY_START_MARKER)}[\\s\\S]*?${escapeRegExp(SUMMARY_END_MARKER)}`),
            summaryBlock
          );
        } else {
          updatedContent = existing.replace(
            /## (?:Session Summary|Current State)[\s\S]*?$/,
            `${summaryBlock}\n\n### Notes for Next Session\n-\n`
          );
        }
        writeFile(sessionFile, updatedContent);
      }
    }
    log(`[SessionEnd] Updated session file: ${sessionFile}`);
  } else {
    const summarySection = summary
      ? `${buildSummaryBlock(summary)}\n\n### Notes for Next Session\n-`
      : `## Current State\n\n[Session context goes here]\n\n### Notes for Next Session\n-`;

    writeFile(sessionFile, `# Session: ${today}\n**Date:** ${today}\n**Started:** ${currentTime}\n**Last Updated:** ${currentTime}\n\n---\n\n${summarySection}\n`);
    log(`[SessionEnd] Created session file: ${sessionFile}`);
  }

  process.exit(0);
}

function buildSummaryBlock(summary) {
  let section = '## Session Summary\n\n### Tasks\n';
  for (const msg of summary.userMessages) {
    section += `- ${msg.replace(/\n/g, ' ').replace(/`/g, '\\`')}\n`;
  }
  if (summary.filesModified.length > 0) {
    section += '\n### Files Modified\n';
    for (const f of summary.filesModified) section += `- ${f}\n`;
  }
  if (summary.toolsUsed.length > 0) {
    section += `\n### Tools Used\n${summary.toolsUsed.join(', ')}\n`;
  }
  section += `\n### Stats\n- Total user messages: ${summary.totalMessages}\n`;
  return `${SUMMARY_START_MARKER}\n${section.trim()}\n${SUMMARY_END_MARKER}`;
}

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
