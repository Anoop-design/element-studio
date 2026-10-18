#!/usr/bin/env python3
"""Copy the portable Element Studio skills to a user-selected agent directory."""
import argparse
from pathlib import Path
import shutil
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, required=True)
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1] / 'skills'
    destination = args.destination.expanduser().resolve()
    skills = sorted(p for p in source.iterdir() if (p / 'SKILL.md').is_file())
    if not skills:
        parser.error('No packaged skills found beside this script')
    for skill in skills:
        if destination == skill or skill in destination.parents:
            parser.error('The destination must not be inside a source skill')
        if (destination / skill.name).exists() or (destination / skill.name).is_symlink():
            parser.error(f'Refusing to replace {destination / skill.name}; compare and move the existing skill first')
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.element-studio-install-', dir=destination) as temporary:
        staged = Path(temporary)
        for skill in skills:
            shutil.copytree(skill, staged / skill.name)
        for skill in skills:
            # Recheck just before promotion; never merge into another skill.
            target = destination / skill.name
            if target.exists() or target.is_symlink():
                parser.error(f'Destination appeared during installation: {target}')
            (staged / skill.name).rename(target)
            print(f'Installed {target}')
    print('No agent configuration was changed. Enable skill discovery in your agent if needed.')


if __name__ == '__main__':
    main()
