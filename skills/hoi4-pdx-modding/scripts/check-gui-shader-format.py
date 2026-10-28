#!/usr/bin/env python3
"""Read-only guards for the line-sensitive HOI4 shader wrapper format.

This is NOT the Clausewitz parser or an HLSL compiler. Check selected .shader
and .fxh files before extracting HLSL for compilation; keep native testing.
Uses only the Python standard library. Paths/globs are relative to --root.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def inspect_text(text: str) -> list[dict]:
    # Keep offsets/newlines when ignoring comments. Preprocessor directives in
    # HLSL are irrelevant to these wrapper-format guards.
    clean = re.sub(r'/\*.*?\*/|//[^\n]*|(?m:^[ \t]*#[^\n]*)',
                   lambda m: re.sub(r'[^\n]', ' ', m.group()), text, flags=re.S)
    issues = []

    def add(offset, code, message):
        issues.append({'line': clean.count('\n', 0, offset) + 1,
                       'code': code, 'message': message})

    for match in re.finditer(r'\bVertexStruct\s+(\w+)\s*\{(.*?)\}\s*;', clean, re.S):
        body = match.group(2)
        if '\n' not in body or body.split('\n', 1)[0].strip() or body.rsplit('\n', 1)[-1].strip():
            add(match.start(), 'WRAPPER_STRUCT_LINES',
                f'{match.group(1)}: put members below the opening brace and the closing brace on its own line')
        for line in body.splitlines():
            if line.count(';') > 1:
                add(match.start(), 'WRAPPER_MEMBER_LINES',
                    f'{match.group(1)}: put each member declaration on its own line')
                break

    for match in re.finditer(r'\bMainCode\s+(\w+)\s*\[\[', clean):
        prefix = clean[clean.rfind('\n', 0, match.start()) + 1:match.start()]
        if prefix.strip():
            add(match.start(), 'WRAPPER_MAINCODE_LINE',
                f'{match.group(1)}: start MainCode on its own line inside the shader stage')

    # Covers MainCode and shared Code bodies. Never merge a closing fence with
    # an HLSL statement or the enclosing PDX brace during code generation.
    for match in re.finditer(r'\]\]', clean):
        start = clean.rfind('\n', 0, match.start()) + 1
        end = clean.find('\n', match.end())
        if end < 0:
            end = len(clean)
        if clean[start:end].strip() != ']]':
            add(match.start(), 'WRAPPER_CODE_END_LINE', 'put ]] on its own line')
    return issues


def self_test() -> int:
    good = '''VertexStruct VS_OUTPUT {
    float4 vPosition : PDX_POSITION;
    float2 vTexCoord : TEXCOORD0;
};
VertexShader = {
    MainCode VertexShader [[
        VS_OUTPUT main(const VS_INPUT v) { return (VS_OUTPUT)0; }
    ]]
}
Effect Up { VertexShader = "VertexShader" PixelShader = "PixelShaderUp" }
'''
    assert not inspect_text(good)
    # The actual failed form: extracted HLSL remains valid, native wrapper does not.
    compact = re.sub(r'VertexStruct.*?};',
                     'VertexStruct VS_OUTPUT { float4 vPosition : PDX_POSITION; float2 vTexCoord : TEXCOORD0; };',
                     good, flags=re.S)
    cases = [
        (compact, 'WRAPPER_STRUCT_LINES'),
        (good.replace('PDX_POSITION;\n    float2', 'PDX_POSITION; float2'), 'WRAPPER_MEMBER_LINES'),
        (good.replace('VertexShader = {\n    MainCode', 'VertexShader = { MainCode'), 'WRAPPER_MAINCODE_LINE'),
        (good.replace('    ]]\n}', '    ]] }'), 'WRAPPER_CODE_END_LINE'),
    ]
    for text, expected in cases:
        assert expected in {i['code'] for i in inspect_text(text)}, expected
    assert not inspect_text('// VertexStruct BAD { float x; };\n' + good)
    assert not inspect_text(good.replace('VS_OUTPUT {', 'VS_OUTPUT\n{'))
    return len(cases)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--files', nargs='+', help='Selected relative paths/globs; quote globs in the shell')
    parser.add_argument('--json', action='store_true', help='Print the report as JSON')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    regressions = self_test() if args.self_test else None
    if not args.files and not args.self_test:
        parser.error('supply --files or --self-test')
    root = args.root.resolve()
    files = set()
    issues = []
    for pattern in args.files or []:
        if Path(pattern).is_absolute() or '..' in Path(pattern).parts:
            parser.error('use paths/globs inside --root')
        matches = sorted(root.glob(pattern))
        if not matches:
            issues.append({'file': pattern, 'line': 0, 'code': 'MISSING_FILE', 'message': 'no matching file'})
        for path in matches:
            resolved = path.resolve()
            if not resolved.is_relative_to(root) or not resolved.is_file() or resolved.suffix.lower() not in {'.shader', '.fxh'}:
                parser.error(f'expected .shader/.fxh file inside --root: {path}')
            files.add(resolved)
    for path in sorted(files):
        for issue in inspect_text(path.read_text(encoding='utf-8-sig')):
            issues.append({'file': path.relative_to(root).as_posix(), **issue})
    result = {'passed': not issues, 'checked_files': len(files), 'issues': issues,
              'negative_regressions': regressions, 'native_parser_run': False,
              'scope': 'conservative wrapper line-format guards only; no edits, HLSL compilation or game launch'}
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        for issue in issues:
            print(f"{issue['file']}:{issue['line']} {issue['code']}: {issue['message']}")
        print(f"Wrapper format: {len(files)} files, {len(issues)} issues; native parser not run.")
        if regressions is not None:
            print(f'Negative regressions: {regressions} passed.')
    return int(bool(issues))


if __name__ == '__main__':
    raise SystemExit(main())
