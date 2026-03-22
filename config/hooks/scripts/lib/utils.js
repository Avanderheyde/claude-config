/**
 * Cross-platform utility functions for Claude Code hooks
 * Adapted from everything-claude-code by @affaan-m
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const isWindows = process.platform === 'win32';

function getHomeDir() { return os.homedir(); }
function getClaudeDir() { return path.join(getHomeDir(), '.claude'); }
function getSessionsDir() { return path.join(getClaudeDir(), 'sessions'); }
function getLearnedSkillsDir() { return path.join(getClaudeDir(), 'skills', 'learned'); }
function getTempDir() { return os.tmpdir(); }

function ensureDir(dirPath) {
  try {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
  return dirPath;
}

function getDateString() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

function getTimeString() {
  const now = new Date();
  return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
}

function getSessionIdShort(fallback = 'default') {
  const sessionId = process.env.CLAUDE_SESSION_ID;
  if (sessionId && sessionId.length > 0) return sessionId.slice(-8);
  return getProjectName() || fallback;
}

function getProjectName() {
  const result = runCommand('git', ['rev-parse', '--show-toplevel']);
  if (result.success) return path.basename(result.output);
  return path.basename(process.cwd()) || null;
}

function findFiles(dir, pattern, options = {}) {
  if (!dir || !pattern) return [];
  const { maxAge = null, recursive = false } = options;
  const results = [];
  if (!fs.existsSync(dir)) return results;

  const regexPattern = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*/g, '.*')
    .replace(/\?/g, '.');
  const regex = new RegExp(`^${regexPattern}$`);

  function searchDir(currentDir) {
    try {
      const entries = fs.readdirSync(currentDir, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);
        if (entry.isFile() && regex.test(entry.name)) {
          let stats;
          try { stats = fs.statSync(fullPath); } catch { continue; }
          if (maxAge !== null) {
            const ageInDays = (Date.now() - stats.mtimeMs) / (1000 * 60 * 60 * 24);
            if (ageInDays <= maxAge) results.push({ path: fullPath, mtime: stats.mtimeMs });
          } else {
            results.push({ path: fullPath, mtime: stats.mtimeMs });
          }
        } else if (entry.isDirectory() && recursive) {
          searchDir(fullPath);
        }
      }
    } catch { /* ignore permission errors */ }
  }

  searchDir(dir);
  results.sort((a, b) => b.mtime - a.mtime);
  return results;
}

function log(message) { console.error(message); }
function output(data) {
  if (typeof data === 'object') console.log(JSON.stringify(data));
  else console.log(data);
}

function readFile(filePath) {
  try { return fs.readFileSync(filePath, 'utf8'); } catch { return null; }
}

function writeFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, 'utf8');
}

function appendFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.appendFileSync(filePath, content, 'utf8');
}

/**
 * Run a command safely using spawnSync (no shell injection risk)
 * @param {string} cmd - The executable to run
 * @param {string[]} args - Array of arguments
 * @param {object} options - spawnSync options
 */
function runCommand(cmd, args = [], options = {}) {
  try {
    const result = spawnSync(cmd, args, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      ...options
    });
    if (result.status === 0) {
      return { success: true, output: (result.stdout || '').trim() };
    }
    return { success: false, output: (result.stderr || result.stdout || '').trim() };
  } catch (err) {
    return { success: false, output: err.message };
  }
}

function replaceInFile(filePath, search, replace, options = {}) {
  const content = readFile(filePath);
  if (content === null) return false;
  try {
    let newContent = options.all && typeof search === 'string'
      ? content.replaceAll(search, replace)
      : content.replace(search, replace);
    writeFile(filePath, newContent);
    return true;
  } catch { return false; }
}

function countInFile(filePath, pattern) {
  const content = readFile(filePath);
  if (content === null) return 0;
  let regex;
  try {
    if (pattern instanceof RegExp) {
      regex = new RegExp(pattern.source, pattern.flags.includes('g') ? pattern.flags : pattern.flags + 'g');
    } else {
      regex = new RegExp(pattern, 'g');
    }
  } catch { return 0; }
  const matches = content.match(regex);
  return matches ? matches.length : 0;
}

module.exports = {
  isWindows, getHomeDir, getClaudeDir, getSessionsDir, getLearnedSkillsDir,
  getTempDir, ensureDir, getDateString, getTimeString, getSessionIdShort,
  getProjectName, findFiles, readFile, writeFile, appendFile, replaceInFile,
  countInFile, log, output, runCommand
};
