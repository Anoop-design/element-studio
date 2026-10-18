#!/usr/bin/env python3
"""Validate portable skills, Markdown links, and native mesh buffers (standard library only)."""
import argparse
from array import array
import json
import math
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def check_skills(folder):
    skills = sorted(folder.glob('*/SKILL.md'))
    require(bool(skills), f'No skills in {folder}')
    for path in skills:
        text = path.read_text()
        match = re.match(r'\A---\n(.*?)\n---\n', text, re.S)
        require(match, f'{path}: missing YAML frontmatter')
        # These packages deliberately use plain scalar metadata, not arbitrary YAML.
        fields = dict(line.split(': ', 1) for line in match[1].splitlines() if ': ' in line)
        name = fields.get('name', '')
        require(re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', name) and len(name) <= 64,
                f'{path}: invalid skill name')
        require(name == path.parent.name, f'{path}: name must match folder')
        require(1 <= len(fields.get('description', '')) <= 1024, f'{path}: invalid description')
        require(fields.get('license') == 'MIT', f'{path}: expected MIT metadata')
        require((path.parent / 'LICENSE').is_file(), f'{path}: missing distributable license')
        for resource in path.parent.rglob('*.md'):
            for link in links(resource):
                require(link.is_relative_to(path.parent.resolve()), f'{resource}: skill link leaves its package: {link}')
        for resource in path.parent.rglob('*'):
            require(not resource.is_symlink(), f'{resource}: packaged skills must not depend on symlinks')
    return len(skills)


def links(path):
    # Inline Markdown links/images; fragment targets need no filesystem lookup.
    for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', path.read_text()):
        target = target.strip().strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        linked = (path.parent / unquote(parsed.path)).resolve()
        require(linked.exists(), f'{path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}: missing link {target}')
        yield linked


def check_docs():
    paths = list(ROOT.glob('*.md'))
    for folder in ('Documentation', 'Authoring', 'skills'):
        paths += [p for p in (ROOT / folder).rglob('*.md') if 'vendor' not in p.parts and 'verification' not in p.parts]
    for path in paths:
        list(links(path))
        require(not re.search(r'/Users/[^/\s]+/', path.read_text()), f'{path}: personal home path')
    for name in ('project.yml', 'ElementStudio.xcodeproj/project.pbxproj'):
        text = (ROOT / name).read_text()
        require(not re.search(r'(?:DEVELOPMENT_TEAM|DevelopmentTeam)\s*[:=]\s*[A-Z0-9]{10}', text), f'{name}: personal signing team')
    return len(paths)


def check_geometry(folder):
    manifests = sorted(folder.glob('ElementStudio-*.json'))
    require(bool(manifests), f'No mesh manifests in {folder}')
    batches = 0
    for path in manifests:
        manifest = json.loads(path.read_text())
        binary = path.with_suffix('.bin').read_bytes()
        require(bool(manifest.get('batches')), f'{path.name}: no batches')
        for batch in manifest['batches']:
            values = {}
            for key, stride in (('positions', 3), ('normals', 3), ('uv', 2), ('indices', 3)):
                bounds = batch[key]
                offset, count = bounds['offset'], bounds['count']
                require(type(offset) is int and type(count) is int and offset >= 0 and count > 0,
                        f'{path.name}/{key}: invalid range')
                require(offset % 4 == 0 and count % stride == 0 and offset + count * 4 <= len(binary),
                        f'{path.name}/{key}: misaligned or out-of-bounds range')
                data = array('I' if key == 'indices' else 'f')
                require(data.itemsize == 4, 'This checker requires 32-bit float and unsigned int arrays')
                data.frombytes(binary[offset:offset + count * 4])
                if sys.byteorder != 'little':
                    data.byteswap()
                if key != 'indices':
                    require(all(math.isfinite(v) for v in data), f'{path.name}/{key}: nonfinite value')
                values[key] = data
            vertices = len(values['positions']) // 3
            require(len(values['normals']) == vertices * 3 and len(values['uv']) == vertices * 2,
                    f'{path.name}: attribute counts disagree')
            require(max(values['indices']) < vertices, f'{path.name}: index outside vertex array')
            require(len(batch['color']) == 3 and all(math.isfinite(v) for v in batch['color']),
                    f'{path.name}: invalid color')
            require(isinstance(batch['role'], str) and bool(batch['role']), f'{path.name}: missing role')
            batches += 1
    return len(manifests), batches


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--geometry', type=Path, help='Validate only candidate geometry in this directory')
    parser.add_argument('--skills', type=Path, help='Validate only installed skill packages in this directory')
    args = parser.parse_args()
    try:
        if args.geometry:
            meshes, batches = check_geometry(args.geometry.resolve())
            print(f'Geometry passed: {meshes} manifests, {batches} batches')
        elif args.skills:
            print(f'Skills passed: {check_skills(args.skills.resolve())} packages')
        else:
            skills = check_skills(ROOT / 'skills')
            docs = check_docs()
            meshes, batches = check_geometry(ROOT / 'Resources')
            print(f'Passed: {skills} portable skills, {docs} Markdown documents, {meshes} mesh manifests, {batches} batches')
    except (ValueError, KeyError, OSError, TypeError, OverflowError) as error:
        print(f'FAILED: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
