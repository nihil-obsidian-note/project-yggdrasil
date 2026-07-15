import fs from "node:fs";
import path from "node:path";

function parseArgs(argv) {
  const args = {
    input: process.cwd(),
    output: null,
    series: null,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--input") {
      args.input = path.resolve(argv[i + 1]);
      i += 1;
    } else if (arg === "--output") {
      args.output = path.resolve(argv[i + 1]);
      i += 1;
    } else if (arg === "--series") {
      args.series = argv[i + 1];
      i += 1;
    }
  }

  return args;
}

function resolveSeriesOptions(series, inputRoot, outputPath) {
  const normalizedSeries = series?.trim();
  if (!normalizedSeries) {
    throw new Error("--series 인자가 필요합니다. 값은 '룩스테라' 또는 '엘드로스' 여야 합니다.");
  }

  if (normalizedSeries === "룩스테라") {
    return {
      contentRoot: path.join(inputRoot, "룩스테라"),
      outputPath: outputPath ?? path.join(process.cwd(), "luxterra-codex.json"),
    };
  }

  if (normalizedSeries === "엘드로스") {
    return {
      contentRoot: path.join(inputRoot, "엘드로스"),
      outputPath: outputPath ?? path.join(process.cwd(), "eldros-codex.json"),
    };
  }

  throw new Error(`지원하지 않는 시리즈입니다: ${normalizedSeries}`);
}

function stripBom(text) {
  return text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
}

function unquote(value) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith("'") && trimmed.endsWith("'")) ||
    (trimmed.startsWith('"') && trimmed.endsWith('"'))
  ) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function coerceScalar(value) {
  const trimmed = value.trim();
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  return unquote(trimmed);
}

function parseFrontmatter(fileContent) {
  const text = stripBom(fileContent);
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    return null;
  }

  const result = {};
  let currentArrayKey = null;

  for (const rawLine of match[1].split(/\r?\n/)) {
    if (!rawLine.trim()) {
      continue;
    }

    const arrayItemMatch = rawLine.match(/^\s*-\s*(.*)$/);
    if (arrayItemMatch && currentArrayKey) {
      result[currentArrayKey].push(coerceScalar(arrayItemMatch[1]));
      continue;
    }

    const keyMatch = rawLine.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!keyMatch) {
      continue;
    }

    let [, key, value] = keyMatch;
    if (key === "이름") {
      key = "title";
    }
    if (value === "") {
      result[key] = [];
      currentArrayKey = key;
    } else {
      result[key] = coerceScalar(value);
      currentArrayKey = null;
    }
  }

  return result;
}

function shouldSkipDir(dirName) {
  return dirName.startsWith(".") || dirName === "docs" || dirName === "scripts";
}

function collectMarkdownFiles(rootDir) {
  const files = [];

  function walk(currentDir) {
    for (const entry of fs.readdirSync(currentDir, { withFileTypes: true })) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        if (!shouldSkipDir(entry.name)) {
          walk(fullPath);
        }
        continue;
      }

      if (entry.isFile() && entry.name.endsWith(".md")) {
        files.push(fullPath);
      }
    }
  }

  walk(rootDir);
  return files.sort((a, b) => a.localeCompare(b, "ko"));
}

function classifyDocType(relativePath) {
  const segments = relativePath.split(path.sep);
  if (segments.includes("신격")) {
    return "deity";
  }
  if (segments.includes("설정")) {
    return "setting";
  }
  return null;
}

function buildCodexObject(inputRoot) {
  const result = {
    deityCount: 0,
    settingCount: 0,
    totalCount: 0,
    deity: [],
    setting: [],
  };

  for (const filePath of collectMarkdownFiles(inputRoot)) {
    const relativePath = path.relative(inputRoot, filePath);
    const docType = classifyDocType(relativePath);
    if (!docType) {
      continue;
    }

    const frontmatter = parseFrontmatter(fs.readFileSync(filePath, "utf8"));
    if (!frontmatter) {
      continue;
    }

    result[docType].push({
      ...frontmatter,
      docType,
    });
  }

  result.deityCount = result.deity.length;
  result.settingCount = result.setting.length;
  result.totalCount = result.deityCount + result.settingCount;

  return result;
}

function main() {
  const { input, output, series } = parseArgs(process.argv.slice(2));
  const { contentRoot, outputPath } = resolveSeriesOptions(series, input, output);
  const codex = buildCodexObject(contentRoot);
  fs.writeFileSync(outputPath, `${JSON.stringify(codex, null, 2)}\n`, "utf8");
}

main();
