#!/usr/bin/env python3
"""Build and test the native RealityKit/SwiftUI app in a simulator or on an iPhone."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]


def simulator(dry_run):
    listing = subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json'], text=True)
    choices = []
    for runtime, devices in json.loads(listing)['devices'].items():
        version = re.search(r'iOS-(\d+)-(\d+)(?:-(\d+))?$', runtime)
        if not version or int(version[1]) < 26:
            continue
        for device in devices:
            if device.get('isAvailable') and 'iPhone' in device.get('deviceTypeIdentifier', ''):
                choices.append((tuple(int(v or 0) for v in version.groups()), runtime, device))
    choices.sort(key=lambda item: item[0], reverse=True)
    for _, _, device in choices:
        if device['name'].startswith('Element Studio') and 'QA' in device['name']:
            return device['udid']
    if not choices:
        raise ValueError('Install an iOS 26+ iPhone simulator runtime in Xcode, or pass --device with a connected iPhone UDID.')
    _, runtime, template = choices[0]
    command = ['xcrun', 'simctl', 'create', 'Element Studio QA', template['deviceTypeIdentifier'], runtime]
    if dry_run:
        raise ValueError('No dedicated QA simulator exists. Run without --dry-run to create one, or supply --simulator UUID.')
    print('Creating a dedicated Element Studio QA simulator.', flush=True)
    return subprocess.check_output(command, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    destination = parser.add_mutually_exclusive_group()
    destination.add_argument('--simulator', metavar='UUID', help='Existing simulator; default reuses or creates a dedicated Element Studio QA iPhone')
    destination.add_argument('--device', metavar='UDID', help='Paired, unlocked physical iPhone shown by xcodebuild -showdestinations')
    parser.add_argument('--team', help='Your Apple development team for a device build; never stored in the project')
    parser.add_argument('--allow-provisioning-updates', action='store_true', help='Explicitly allow Xcode to update signing profiles')
    parser.add_argument('--suite', choices=['all', 'unit', 'ui'], default='all')
    parser.add_argument('--only-testing', action='append', default=[], metavar='TARGET/CLASS/METHOD', help='Narrow the selected suite, repeatable')
    parser.add_argument('--dry-run', action='store_true', help='Print the command without building, installing, or testing')
    args = parser.parse_args()
    if (args.team or args.allow_provisioning_updates) and not args.device:
        parser.error('Signing options apply only to --device')
    if args.only_testing and args.suite != 'all':
        parser.error('Use either --suite or --only-testing, not both')
    if any(not value.startswith(('ElementStudioTests/', 'ElementStudioUITests/')) for value in args.only_testing):
        parser.error('--only-testing must name an ElementStudioTests or ElementStudioUITests class/test')
    if args.team and not re.fullmatch(r'[A-Za-z0-9]+', args.team):
        parser.error('--team must be an Apple team identifier')
    try:
        selected = args.device or args.simulator or simulator(args.dry_run)
        if not re.fullmatch(r'[A-Za-z0-9-]+', selected):
            parser.error('Use a simulator UUID or physical-device UDID, not a device name')
        platform = 'iOS' if args.device else 'iOS Simulator'
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid4().hex[:6]
        result = ROOT / 'build' / f'NativeTests-{stamp}.xcresult'
        log = result.with_suffix('.log')
        command = ['xcodebuild', '-project', str(ROOT / 'ElementStudio.xcodeproj'), '-scheme', 'ElementStudio',
                   '-configuration', 'Debug', '-destination', f'platform={platform},id={selected}',
                   '-derivedDataPath', str(ROOT / 'build'), '-resultBundlePath', str(result),
                   '-parallel-testing-enabled', 'NO', 'test']
        if args.suite == 'unit':
            command.append('-only-testing:ElementStudioTests')
        elif args.suite == 'ui':
            command.append('-only-testing:ElementStudioUITests')
        command += ['-only-testing:' + value for value in args.only_testing]
        if args.team:
            command.append('DEVELOPMENT_TEAM=' + args.team)
        if args.allow_provisioning_updates:
            command.append('-allowProvisioningUpdates')
        print(shlex.join(command), flush=True)
        if args.dry_run:
            return 0
        (ROOT / 'build').mkdir(exist_ok=True)
        print(f'Native test log: {log}\nNative results and UI captures: {result}', flush=True)
        with log.open('w') as output:
            completed = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
        if completed.returncode:
            print('\n'.join(log.read_text(errors='replace').splitlines()[-45:]), file=sys.stderr)
            print('Native validation failed; inspect the log and xcresult before claiming success.', file=sys.stderr)
        else:
            print('Native build and selected tests passed. Review the xcresult UI attachments for visual changes.', flush=True)
        return completed.returncode
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'Native validation could not run: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
