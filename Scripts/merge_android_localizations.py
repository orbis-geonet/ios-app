#!/usr/bin/env python3
"""Fill iOS Localizable.strings translations from the Android project's strings.xml files.

Matching: iOS keys are English sentences; Android base values/strings.xml maps
name -> English. We invert that (English -> name), then per locale resolve
name -> translation and rewrite the iOS value. Structure/comments preserved.
"""
import re, sys, unicodedata
import xml.etree.ElementTree as ET
from pathlib import Path

IOS_STRINGS = Path('/Users/macbook/StudioProjects/orbis-ios-v3/Orbis-iOS/Resources/Strings')
AND_RES = Path('/Users/macbook/StudioProjects/orbis_v2_android/app/src/main/res')

# iOS lproj -> Android values-XX dir suffix
LOCALE_MAP = {
    'ar': 'ar', 'de': 'de', 'es': 'es', 'fr': 'fr', 'hi': 'hi',
    'id': 'in', 'it': 'it', 'ja': 'ja', 'ko': 'ko', 'ms': 'ms',
    'ne': 'ne', 'pl': 'pl', 'pt': 'pt', 'pt-BR': 'pt', 'ru': 'ru',
    'sw': 'sw', 'th': 'th', 'tr': 'tr', 'uk': 'uk', 'ur': 'ur',
    'vi': 'vi', 'zh': 'zh', 'zh-Hans': 'zh',
}

ENTRY_RE = re.compile(r'^(\s*)"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;(.*)$')


def android_unescape(s):
    # android XML string resource escapes
    s = s.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n').replace('\\t', '\t')
    s = re.sub(r'\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1), 16)), s)
    s = s.replace('\\\\', '\\')
    return s


def android_to_ios_format(s):
    # %1$s -> %1$@, %s -> %@ ; numeric specifiers stay as-is
    s = re.sub(r'%(\d+\$)?s', lambda m: '%' + (m.group(1) or '') + '@', s)
    return s


def strings_unescape(s):
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            out.append({'n': '\n', 't': '\t', '"': '"', '\\': '\\'}.get(nxt, '\\' + nxt))
            i += 2
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def strings_escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')


def norm(s):
    s = unicodedata.normalize('NFC', s)
    s = s.replace('’', "'").replace('‘', "'").replace('“', '"').replace('”', '"')
    s = s.replace('…', '...')
    # unify format tokens so "using %s" matches "using %@"
    s = re.sub(r'%(\d+\$)?[s@]', '%X', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s.casefold()


def parse_android(path):
    d = {}
    root = ET.parse(path).getroot()
    for el in root.iter('string'):
        name = el.get('name')
        if name is None:
            continue
        text = ''.join(el.itertext())
        d[name] = android_unescape(text.strip())
    return d


def norm2(s):
    # aggressive: letters/digits/format-tokens only — fallback tier, used only when unambiguous
    s = norm(s).replace('%x', '%X')
    return re.sub(r'[^\w%X]+', '', s, flags=re.UNICODE)


base = parse_android(AND_RES / 'values' / 'strings.xml')
en_to_name = {}
loose = {}
for name, en in base.items():
    if en:
        en_to_name.setdefault(norm(en), name)
        loose.setdefault(norm2(en), set()).add(name)


def lookup(key_en):
    name = en_to_name.get(norm(key_en))
    if name:
        return name
    cands = loose.get(norm2(key_en))
    if cands and len(cands) == 1:
        return next(iter(cands))
    return None

report = {}
unmatched_keys = None

for ios_loc, and_loc in sorted(LOCALE_MAP.items()):
    src = AND_RES / f'values-{and_loc}' / 'strings.xml'
    dst = IOS_STRINGS / f'{ios_loc}.lproj' / 'Localizable.strings'
    if not src.exists() or not dst.exists():
        report[ios_loc] = 'MISSING ' + str(src if not src.exists() else dst)
        continue
    trans = parse_android(src)
    lines = dst.read_text(encoding='utf-8').splitlines(keepends=False)
    out, hit, miss, miss_list = [], 0, 0, []
    for line in lines:
        m = ENTRY_RE.match(line)
        if not m:
            out.append(line)
            continue
        indent, rawkey, _rawval, tail = m.groups()
        key_en = strings_unescape(rawkey)
        name = lookup(key_en)
        t = trans.get(name) if name else None
        if t and norm(t) != norm(base.get(name, '')):  # skip untranslated (still-English) android rows
            t = android_to_ios_format(t)
            out.append(f'{indent}"{rawkey}" = "{strings_escape(t)}";{tail}')
            hit += 1
        else:
            out.append(line)
            miss += 1
            miss_list.append(key_en)
    dst.write_text('\n'.join(out) + '\n', encoding='utf-8')
    report[ios_loc] = f'{hit} translated, {miss} left English'
    if unmatched_keys is None:
        unmatched_keys = miss_list

for k, v in report.items():
    print(f'{k:8s} {v}')
print('\nSample keys left in English (first 25):')
for k in (unmatched_keys or [])[:25]:
    print('  -', k)
