import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const REQUIRED_TEMPLATES = [
  {
    fileName: "설정_기본 템플릿.md",
    content: `---
title: '문서이름'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: ''
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

내용

## 항목

내용
`,
  },
  {
    fileName: "설정_국가 템플릿.md",
    content: `---
title: '국가'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '국가'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

이 국가는 어떤 환경과 배경 위에서 형성되었는지 정리한다.

## 영토와 환경

주요 지형, 기후, 자원, 전략적 위치를 정리한다.

## 정치와 통치

통치 체계와 권력 구조를 정리한다.

## 문화와 사회

생활양식, 신앙, 계층, 관습을 정리한다.

## 대외 관계

주변 국가 및 세력과의 관계를 정리한다.
`,
  },
  {
    fileName: "설정_단체 템플릿.md",
    content: `---
title: '단체'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '단체'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

이 단체가 무엇을 목표로 활동하는지 정리한다.

## 기원과 설립

설립 배경과 초기 목적을 정리한다.

## 조직 구조

지도부, 실무 조직, 규율 구조를 정리한다.

## 현재 동향

현재 주요 활동과 갈등 요소를 정리한다.
`,
  },
  {
    fileName: "설정_대륙 템플릿.md",
    content: `---
title: '대륙'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '지형'
subtype: '대륙'
region: ''
created_at: ''
updated_at: ''
---

## 개요

이 대륙의 전반적인 성격과 위치를 정리한다.

## 지리와 기후

지형, 기후대, 자원 분포를 정리한다.

## 주요 세력

대륙 내 국가와 주요 세력을 정리한다.

## 역사적 특징

대륙의 큰 흐름과 분기점을 정리한다.
`,
  },
  {
    fileName: "설정_종족 템플릿.md",
    content: `---
title: '종족명'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '종족'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

종족의 핵심 정체성과 첫인상을 정리한다.

## 기원

종족의 유래와 역사적 배경을 정리한다.

## 신체와 능력

외형적 특징과 타고난 능력을 정리한다.

## 문화와 사회

생활양식, 가치관, 공동체 구조를 정리한다.

## 대외 관계

다른 종족 및 세력과의 관계를 정리한다.
`,
  },
  {
    fileName: "설정_인물 템플릿.md",
    content: `---
title: '인물명'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '인물'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

인물의 역할과 현재 위치를 정리한다.

## 배경

출신, 성장 과정, 형성된 가치관을 정리한다.

## 성격과 관계

성향, 대인 관계, 핵심 갈등을 정리한다.

## 능력과 자원

전문성, 전투력, 영향력, 보유 자원을 정리한다.

## 현재 목표

지금 무엇을 원하고 무엇에 얽혀 있는지 정리한다.
`,
  },
  {
    fileName: "설정_아이템 템플릿.md",
    content: `---
title: '아이템명'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '아이템'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

아이템의 정체와 용도를 정리한다.

## 외형과 구조

형태, 재질, 제작 방식의 특징을 정리한다.

## 기능과 효과

실제 사용 효과와 제약을 정리한다.

## 기원과 유통

누가 만들고 누가 쓰며 어떻게 퍼졌는지 정리한다.
`,
  },
  {
    fileName: "설정_사건 템플릿.md",
    content: `---
title: '사건명'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: '사건'
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요

사건의 성격과 중요성을 정리한다.

## 발단

어떤 배경과 원인으로 사건이 시작되었는지 정리한다.

## 전개

주요 국면과 핵심 참여 세력을 정리한다.

## 결과와 영향

사건 이후 변화와 후속 파장을 정리한다.
`,
  },
  {
    fileName: "신격_기본 템플릿.md",
    content: `---
title: '신격 기본 템플릿'
uuid: '${crypto.randomUUID()}'
docType: 'template'
thumbnail: ''
status: '시작 전'
created_at: ''
updated_at: ''
pantheon: false
cheongyeon_pantheon: false
rank: ''
alignment: ''
domain: []
portfolio: []
---

## 개요

내용

## 교단명

- **교단이름**

부가설명

## 교리

- 교리 항목

## 부가 항목

신격에 대한 특징들을 서술하기 위한 섹션 여러개일 수도 있다. 반드시 교리 섹션과 계시와 가호 섹션 사이에만 존재해야 한다.

## 계시와 가호

내용

## 신앙의 성향

내용

## 요약

- **분류**:
- **교단명**:
- **주요 교리**:
- **신앙의 역할**:
- **금기**:
- **대표 전승**:
`,
  },
];

function parseArgs(argv) {
  const args = { root: process.cwd() };
  for (let index = 0; index < argv.length; index += 1) {
    if (argv[index] === "--root") {
      args.root = path.resolve(argv[index + 1]);
      index += 1;
    }
  }
  return args;
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

function findIndex(lines, key) {
  return lines.findIndex((entry) => entry.startsWith(`${key}:`));
}

function upsertLine(lines, key, rawValue, preferredIndex = lines.length) {
  const line = `${key}: ${rawValue}`;
  const existingIndex = findIndex(lines, key);
  if (existingIndex >= 0) {
    lines[existingIndex] = line;
    return;
  }

  const insertIndex = Math.max(0, Math.min(preferredIndex, lines.length));
  lines.splice(insertIndex, 0, line);
}

function normalizeExistingTemplate(filePath) {
  const original = fs.readFileSync(filePath, "utf8");
  const parts = extractFrontmatterParts(original);
  if (!parts) {
    return false;
  }

  const eol = original.includes("\r\n") ? "\r\n" : "\n";
  const lines = parts.frontmatter.split(/\r?\n/);
  const titleIndex = Math.max(0, findIndex(lines, "title"));

  upsertLine(lines, "uuid", `'${crypto.randomUUID()}'`, titleIndex + 1);
  upsertLine(lines, "docType", "'template'", titleIndex + 2);
  upsertLine(lines, "thumbnail", "''", titleIndex + 3);

  const updated = `${parts.opening}${lines.join(eol)}${parts.closing}${parts.body}`;
  if (updated === original) {
    return false;
  }

  fs.writeFileSync(filePath, updated, "utf8");
  return true;
}

function ensureTemplate(templateDir, template) {
  const filePath = path.join(templateDir, template.fileName);
  if (fs.existsSync(filePath)) {
    normalizeExistingTemplate(filePath);
    return;
  }

  fs.writeFileSync(filePath, template.content.replaceAll("\n", "\r\n"), "utf8");
}

function main() {
  const { root } = parseArgs(process.argv.slice(2));
  const templateDir = path.join(root, "룩스테라", "템플릿");
  fs.mkdirSync(templateDir, { recursive: true });

  for (const template of REQUIRED_TEMPLATES) {
    ensureTemplate(templateDir, template);
  }
}

main();
