#!/usr/bin/env python3
"""Check translated documentation coverage, preserved evidence, and local links."""
from __future__ import annotations
from collections import Counter
from pathlib import Path
import json,re,sys

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=json.loads((ROOT/'docs/documentation.json').read_text())
LOCALES=MANIFEST['locales']
DOCUMENTS=MANIFEST['documents']
ERRORS=[]

def fail(message:str)->None:ERRORS.append(message)
def clean(text:str)->str:
 return re.sub(r'<!-- doc-navigation:start -->.*?<!-- doc-navigation:end -->\n*','',text,flags=re.S)
def structure(text:str)->dict:
 lines=clean(text).splitlines()
 return {
  'headings':Counter(len(m.group(1)) for line in lines if (m:=re.match(r'^(#+) ',line))),
  'tables':sum(line.startswith('|') and not re.match(r'^\|\s*[-: ]+\|',line) for line in lines),
  'fences':sum(line.startswith('```') for line in lines),
  'bullets':sum(bool(re.match(r'^\s*(?:[-*]|\d+\.) ',line)) for line in lines),
 }

for item in DOCUMENTS:
 src=ROOT/item['source']
 baseline=clean(src.read_text())
 base=structure(baseline)
 hashes=set(re.findall(r'(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])',baseline))
 literals=set(re.findall(r'`([^`\n]+)`',baseline))
 for lang in LOCALES:
  path=ROOT/'docs/i18n'/lang/item['target']
  if not path.is_file():fail(f'missing {path.relative_to(ROOT)}');continue
  text=path.read_text()
  if '<!-- doc-navigation:start -->' not in text:fail(f'no language navigation: {path.relative_to(ROOT)}')
  got=structure(text)
  code_blocks=lambda value:re.findall(r'(?ms)^```[^\n]*\n.*?^```',value)
  if code_blocks(text)!=code_blocks(baseline):fail(f'{lang} {item["source"]}: code blocks differ')
  for key in ('headings','tables','fences','bullets'):
   if got[key]!=base[key]:fail(f'{lang} {item["source"]}: {key} {got[key]} != {base[key]}')
  missing=hashes-set(re.findall(r'(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])',text))
  if missing:fail(f'{lang} {item["source"]}: missing SHA-256 {missing}')
  # Source-language inline code can contain prose; check only paths, commands, and identifiers.
  for literal in literals:
   if any(ch in literal for ch in ('/','.','_','--')) and literal not in text:
    fail(f'{lang} {item["source"]}: missing inline code {literal!r}')

for path in [ROOT/'README.md',*ROOT.glob('docs/**/*.md'),ROOT/'FORMATS.md',ROOT/'TEST-RESULTS.md',*ROOT.glob('Tests/Release-*.md'),*ROOT.glob('ThirdParty/README*.md'),ROOT/'Resources/Localizations/README.md']:
 content=path.read_text()
 for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)]+)\)',content):
  if target.startswith(('http:','https:','mailto:','#')):continue
  dest=(path.parent/target.split('#')[0]).resolve()
  if not dest.exists():fail(f'broken link {path.relative_to(ROOT)} -> {target}')

for lang in LOCALES:
 if not (ROOT/'docs/i18n'/lang/'INDEX.md').is_file():fail(f'missing index {lang}')
 if lang!='zh-Hans' and not (ROOT/'docs/readme'/f'README.{lang}.md').is_file():fail(f'missing legacy README {lang}')

if ERRORS:
 print('\n'.join(ERRORS[:200]),file=sys.stderr)
 print(f'{len(ERRORS)} documentation errors',file=sys.stderr)
 raise SystemExit(1)
print(f'Checked {len(LOCALES)} languages × {len(DOCUMENTS)} full documents; structure, hashes, code, and local links are valid.')
