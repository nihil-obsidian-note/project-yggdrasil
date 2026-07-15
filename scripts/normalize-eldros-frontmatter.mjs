import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

function parseArgs(argv) {
  const args = {
    root: process.cwd(),
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--root") {
      args.root = path.resolve(argv[index + 1]);
      index += 1;
    }
  }

  return args;
}

function collectMarkdownFiles(dirPath) {
  if (!fs.existsSync(dirPath)) {
    return [];
  }

  const files = [];
  for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectMarkdownFiles(fullPath));
      continue;
    }

    if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(fullPath);
    }
  }

  return files.sort((left, right) => left.localeCompare(right, "ko"));
}

function stripBom(text) {
  return text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
}

function extractFrontmatterParts(content) {
  const normalizedContent = stripBom(content);
  const match = normalizedContent.match(/^(---\r?\n)([\s\S]*?)(\r?\n---)(\r?\n?[\s\S]*)$/);
  if (!match) {
    return null;
  }

  return {
    opening: match[1],
    frontmatter: match[2],
    closing: match[3],
    body: match[4],
  };
}

function upsertLine(lines, key, rawValue, preferredIndex = lines.length) {
  const line = `${key}: ${rawValue}`;
  const existingIndex = lines.findIndex((entry) => entry.startsWith(`${key}:`));
  if (existingIndex >= 0) {
    lines[existingIndex] = line;
    return;
  }

  const insertIndex = Math.max(0, Math.min(preferredIndex, lines.length));
  lines.splice(insertIndex, 0, line);
}

function findIndex(lines, key) {
  return lines.findIndex((entry) => entry.startsWith(`${key}:`));
}

function normalizeScalarLine(lines, key) {
  const index = findIndex(lines, key);
  if (index < 0) {
    return;
  }

  if (lines[index] === `${key}: '-'`) {
    lines[index] = `${key}: ''`;
  }
}

function normalizeFile(filePath, kind) {
  const original = fs.readFileSync(filePath, "utf8");
  const parts = extractFrontmatterParts(original);
  if (!parts) {
    return false;
  }

  const eol = original.includes("\r\n") ? "\r\n" : "\n";
  const lines = parts.frontmatter.split(/\r?\n/);
  const titleIndex = Math.max(0, findIndex(lines, "title"));

  const uuidIndex = titleIndex + 1;
  const docTypeIndex = titleIndex + 2;
  const thumbnailIndex = titleIndex + 3;

  upsertLine(lines, "uuid", `'${crypto.randomUUID()}'`, uuidIndex);
  upsertLine(lines, "docType", `'${kind}'`, docTypeIndex);
  upsertLine(lines, "thumbnail", "''", thumbnailIndex);

  normalizeScalarLine(lines, "region");
  normalizeScalarLine(lines, "created_at");
  normalizeScalarLine(lines, "updated_at");

  const updated = `${parts.opening}${lines.join(eol)}${parts.closing}${parts.body}`;
  if (updated === original) {
    return false;
  }

  fs.writeFileSync(filePath, updated, "utf8");
  return true;
}

function main() {
  const { root } = parseArgs(process.argv.slice(2));
  const settingDir = path.join(root, "엘드로스", "설정");
  const templateDir = path.join(root, "엘드로스", "템플릿");

  for (const filePath of collectMarkdownFiles(settingDir)) {
    normalizeFile(filePath, "setting");
  }

  for (const filePath of collectMarkdownFiles(templateDir)) {
    normalizeFile(filePath, "template");
  }
}

main();
