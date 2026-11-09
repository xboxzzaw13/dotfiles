#!/usr/bin/env python3
"""Stage Firefox extension settings with Firefox itself, then back up and apply.

The real browser must be closed. Website data, sessions and browser preferences
are never opened or replaced. All staging browsers use private temporary profiles.
"""
import argparse
import configparser
import contextlib
from datetime import datetime, timezone
import hashlib
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import socket
import sqlite3
import subprocess
import sys
import time
import zipfile

sys.path.insert(0, str(Path(__file__).parent / 'lib'))
from marionette import Marionette

ROOT = Path(__file__).resolve().parent
VM = '{aecec67f-0d10-4fa7-b7c7-609a2db280cf}'


@contextlib.contextmanager
def profile_lock(profile):
    """Use Firefox's own Unix profile lock and hold it for the whole operation."""
    with (profile / '.parentlock').open('a+b') as stream:
        try:
            fcntl.lockf(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError('This Firefox profile is running; close it first.') from error
        try:
            yield
        finally:
            fcntl.lockf(stream, fcntl.LOCK_UN)


def discover_profile():
    for base in (Path.home() / '.config/mozilla/firefox', Path.home() / '.mozilla/firefox'):
        ini = configparser.ConfigParser()
        ini.read(base / 'profiles.ini')
        for section in ini.sections():
            if section.startswith('Install') and ini.has_option(section, 'Default'):
                return base / ini.get(section, 'Default')
    raise RuntimeError('Cannot find the default Firefox profile; use --profile.')


def uuids(profile):
    prefs = (profile / 'prefs.js').read_text()
    match = re.search(r'^user_pref\("extensions\.webextensions\.uuids", (.*)\);$', prefs, re.M)
    if not match:
        raise RuntimeError('Firefox extension UUID mapping was not found.')
    return json.loads(json.loads(match[1]))


def origins(profile, uuid):
    base = profile / 'storage/default'
    return [p.relative_to(profile) for p in base.glob(f'moz-extension+++{uuid}*')
            if p.is_dir() and '.bak' not in p.name]


def copy_path(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_dir():
        shutil.copytree(source, target, dirs_exist_ok=True, copy_function=copy_file,
                        ignore=shutil.ignore_patterns('*-wal', '*-shm', '*-journal'))
    else:
        copy_file(source, target)


def copy_file(source, target):
    source, target = Path(source), Path(target)
    if source.suffix == '.sqlite':
        deadline = time.monotonic() + 15
        def check_progress(status, remaining, total):
            if time.monotonic() > deadline:
                raise RuntimeError(f'Timed out snapshotting {source.name}; ensure Firefox is closed.')
        with contextlib.closing(sqlite3.connect(source.as_uri() + '?mode=ro', uri=True)) as incoming:
            with contextlib.closing(sqlite3.connect(target)) as outgoing:
                incoming.backup(outgoing, pages=256, progress=check_progress, sleep=0.05)
        shutil.copystat(source, target)
    else:
        shutil.copy2(source, target)
    return str(target)


def fingerprint(profile, paths):
    digest = hashlib.sha256()
    for relative in sorted(paths, key=str):
        item = profile / relative
        files = sorted(item.rglob('*')) if item.is_dir() else [item]
        for file in files:
            if file.is_file():
                if file.name.endswith('-shm') or (file.name.endswith('-wal') and file.stat().st_size == 0):
                    continue
                digest.update(str(file.relative_to(profile)).encode())
                with file.open('rb') as stream:
                    for block in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(block)
    return digest.hexdigest()


def make_profile(source, target, mapping, extension_ids):
    target.mkdir(parents=True)
    for relative in [Path('storage.sqlite'), Path('storage-sync-v2.sqlite')]:
        if (source / relative).exists():
            copy_path(source / relative, target / relative)
    for addon in extension_ids:
        for relative in origins(source, mapping[addon]):
            copy_path(source / relative, target / relative)
    with socket.socket() as port_socket:
        port_socket.bind(('127.0.0.1', 0))
        automation_port = port_socket.getsockname()[1]
    prefs = {
        'marionette.port': automation_port,
        'browser.startup.page': 0,
        'browser.shell.checkDefaultBrowser': False,
        'browser.startup.homepage_override.mstone': 'ignore',
        'extensions.update.enabled': False,
        'datareporting.policy.dataSubmissionEnabled': False,
        'extensions.webextensions.uuids': json.dumps(mapping),
    }
    (target / 'user.js').write_text(''.join(
        f'user_pref({json.dumps(k)}, {json.dumps(v)});\n' for k, v in prefs.items()))


@contextlib.contextmanager
def browser(profile):
    automation_port = int(re.search(r'"marionette.port", (\d+)', (profile / 'user.js').read_text())[1])
    with (profile.parent / f'{profile.name}.log').open('w') as log:
        process = subprocess.Popen([
            shutil.which('firefox') or 'firefox', '--headless', '--no-remote',
            '--profile', str(profile), '--marionette', 'about:blank',
        ], stdout=log, stderr=subprocess.STDOUT,
            env={**os.environ, 'MOZ_REMOTE_ALLOW_SYSTEM_ACCESS': '1'})
        client = None
        try:
            for _ in range(120):
                if process.poll() is not None:
                    raise RuntimeError('Staging Firefox exited; inspect the staging log.')
                try:
                    client = Marionette(automation_port)
                    break
                except (ConnectionRefusedError, socket.timeout):
                    time.sleep(0.5)
            if client is None:
                raise RuntimeError('Timed out waiting for staging Firefox.')
            client.start()
            actual_profile = client.execute('return Services.dirsvc.get("ProfD", Ci.nsIFile).path;')
            if Path(actual_profile).resolve() != profile.resolve():
                raise RuntimeError('Automation connected to a different Firefox profile.')
            yield client
        finally:
            if client:
                try:
                    client.quit()
                except (OSError, RuntimeError, EOFError):
                    pass
            try:
                process.wait(timeout=30)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=15)


def async_js(client, code, args=None):
    result = client.execute(code, args, asynchronous=True)
    if isinstance(result, str):
        result = json.loads(result)
    if isinstance(result, dict) and result.get('error'):
        raise RuntimeError(result['error'])
    return result


def vm_message(client, command, data):
    return async_js(client, '''
      const done=arguments[arguments.length-1], page=window.wrappedJSObject;
      page.browser.runtime.sendMessage(page.JSON.parse(arguments[0])).then(
        result=>done(page.JSON.stringify(result ?? null)), error=>done(JSON.stringify({error:String(error)})));
    ''', [json.dumps({'cmd': command, 'data': data})])


def install_script(profile, work, mapping, addons, values):
    worker = work / 'installer-profile'
    make_profile(profile, worker, {VM: mapping[VM]}, [VM])
    script_path = ROOT / 'userscripts/linkswift.user.js'
    metadata = json.loads((ROOT / 'userscripts/linkswift.json').read_text())
    if hashlib.sha256(script_path.read_bytes()).hexdigest() != metadata['sha256']:
        raise RuntimeError('LinkSwift source checksum mismatch.')
    with browser(worker) as client:
        async_js(client, '''
          const done=arguments[arguments.length-1];
          const {AddonManager}=ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs");
          const file=Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
          file.initWithPath(arguments[0]);
          AddonManager.installTemporaryAddon(file).then(a=>done({id:a.id}),e=>done({error:String(e)}));
        ''', [addons[VM]['path']])
        client.command('Marionette:SetContext', value='content')
        client.command('WebDriver:Navigate', url=f'moz-extension://{mapping[VM]}/options/index.html')
        result = vm_message(client, 'ParseScript', {
            'code': script_path.read_text(encoding='utf-8-sig'),
            'url': metadata['downloadURL'], 'cache': True,
            'config': {'enabled': 1, 'shouldUpdate': 1},
        })
        if result.get('errors'):
            raise RuntimeError('LinkSwift metadata was rejected: ' + str(result['errors']))
        script_id = str(result['where']['id'])
        raw = async_js(client, '''
          const done=arguments[arguments.length-1], page=window.wrappedJSObject;
          page.browser.storage.local.get(null).then(v=>done(page.JSON.stringify(v)),e=>done(JSON.stringify({error:String(e)})));
        ''')
        script = raw['scr:' + script_id]
        required = ['req:' + url for url in script['meta']['require']]
        required += ['cac:' + url for url in script['meta']['resources'].values()]
        missing = [key for key in required if not raw.get(key)]
        if missing:
            raise RuntimeError('Missing LinkSwift dependencies: ' + ', '.join(missing))
        stored_values = raw.get('val:' + script_id, {}).copy()
        for key, value in values.items():
            # Violentmonkey's value serialization, as used by its value editor.
            prefix = 's' if isinstance(value, str) else 'b' if isinstance(value, bool) else 'n' if isinstance(value, (int, float)) else 'o'
            stored_values[key] = prefix + (value if isinstance(value, str) else json.dumps(value, ensure_ascii=False, separators=(',', ':')))
        vm_message(client, 'SetValueStores', {script_id: stored_values})
        keys = ['scr:' + script_id, 'code:' + script_id, *required]
        patch = {key: raw[key] for key in keys}
        patch['val:' + script_id] = stored_values
        print(f'LinkSwift {script["meta"]["version"]}: enabled; {len(required)} dependencies cached.', flush=True)
        return patch


EDIT_STORAGE = r'''
const done=arguments[arguments.length-1];
(async()=>{
  const payload=JSON.parse(arguments[0]);
  const {ExtensionStorageIDB}=ChromeUtils.importESModule("resource://gre/modules/ExtensionStorageIDB.sys.mjs");
  const {extensionStorageSync}=ChromeUtils.importESModule("resource://gre/modules/ExtensionStorageSync.sys.mjs");
  const merge=(old,patch)=>{
    if (!patch || Array.isArray(patch) || typeof patch!=="object") return patch;
    const result={...(old && typeof old==="object" && !Array.isArray(old)?old:{})};
    for (const [key,value] of Object.entries(patch)) result[key]=merge(result[key],value);
    return result;
  };
  const results={};
  for (const [id,plan] of Object.entries(payload.plans)) {
    const policy=new WebExtensionPolicy({id,name:plan.name||id,mozExtensionHostname:payload.uuids[id],baseURL:"file:///tmp/",localizeCallback:s=>s,allowedOrigins:new MatchPatternSet([])});
    policy.active=true;
    const principal=Services.scriptSecurityManager.createContentPrincipal(Services.io.newURI(`moz-extension://${payload.uuids[id]}/`),{userContextId:4294967295});
    const db=await ExtensionStorageIDB.open(principal,false);
    try {
      const old=await db.get(null), patch={};
      for (const [key,value] of Object.entries(plan.local||{})) patch[key]=merge(old[key],value);
      for (const key of ["keyMappings","searchEngines"]) if (plan[key]) {
        let lines=(old[key]||"").split("\n").filter(Boolean);
        for (const line of plan[key]) {
          if (key==="searchEngines") lines=lines.filter(s=>s.split(":",1)[0]!==line.split(":",1)[0]);
          if (!lines.includes(line)) lines.push(line);
        }
        patch[key]=lines.join("\n");
      }
      if (plan.exclusionRules) {
        patch.exclusionRules=(old.exclusionRules||[{pattern:":https://mail.google.com/",passKeys:""}]).filter(r=>!plan.exclusionRules.some(p=>p.pattern===r.pattern)).concat(plan.exclusionRules);
      }
      if (plan.enabledEngines) {
        patch.engines=[...new Set([...plan.enabledEngines,...old.engines||[]])];
        patch.disabledEngines=patch.engines.filter(e=>!plan.enabledEngines.includes(e));
      }
      if (plan.disabledFor) patch.disabledFor=[...new Set([...old.disabledFor||[],...plan.disabledFor])];
      if (payload.verify) {
        for (const [key,value] of Object.entries(patch)) if (JSON.stringify(old[key])!==JSON.stringify(value)) throw new Error(`${id}: setting ${key} did not persist`);
      } else {
        await db.set(patch);
        const after=await db.get(null);
        for (const [key,value] of Object.entries(patch)) if (JSON.stringify(after[key])!==JSON.stringify(value)) throw new Error(`${id}: failed to write ${key}`);
        for (const [key,value] of Object.entries(old)) if (!(key in patch) && JSON.stringify(value)!==JSON.stringify(after[key])) throw new Error(`${id}: unmanaged data changed: ${key}`);
      }
      const syncPatch=plan.sync||{};
      if (Object.keys(syncPatch).length) {
        if (!payload.verify) await extensionStorageSync.set({id},syncPatch);
        const actual=await extensionStorageSync.get({id},Object.keys(syncPatch));
        if (JSON.stringify(actual)!==JSON.stringify(syncPatch)) throw new Error(`${id}: sync settings did not persist`);
      }
      results[id]={localKeys:Object.keys(patch),syncKeys:Object.keys(syncPatch)};
    } finally { db.close();policy.active=false; }
  }
  done(results);
})().catch(e=>done({error:String(e)}));
'''


def prepare(profile, work):
    work.mkdir(mode=0o700, parents=True, exist_ok=False)
    plan = json.loads((ROOT / 'settings.json').read_text())
    mapping = uuids(profile)
    addons = {a['id']: a for a in json.loads((profile / 'extensions.json').read_text())['addons']}
    selected = [*plan['extensions'], VM]
    for addon in selected:
        if addon not in addons or not addons[addon].get('active'):
            raise RuntimeError(f'Required extension is missing or disabled: {addon}')
    source_paths = [p for addon in selected for p in origins(profile, mapping[addon])]
    if (profile / 'storage-sync-v2.sqlite').exists():
        source_paths.append(Path('storage-sync-v2.sqlite'))
    before = fingerprint(profile, source_paths)
    values = plan['linkswift'].copy()
    # Machine-local credentials are read only at runtime and never stored in Git.
    rpc_file = Path.home() / '.config/aria2/linkswift-rpc.json'
    if rpc_file.exists():
        values['setting_aria2_rpc'] = [json.loads(rpc_file.read_text())]
    vm_patch = install_script(profile, work, mapping, addons, values)
    plans = {**plan['extensions'], VM: {'name': 'Violentmonkey / LinkSwift', 'local': vm_patch}}
    editor = work / 'editor-profile'
    make_profile(profile, editor, mapping, selected)
    payload = {'plans': plans, 'uuids': mapping, 'verify': False}
    with browser(editor) as client:
        result = async_js(client, EDIT_STORAGE, [json.dumps(payload)])
    payload['verify'] = True
    with browser(editor) as client:
        async_js(client, EDIT_STORAGE, [json.dumps(payload)])
    destination_paths = [p for addon in selected for p in origins(editor, mapping[addon])]
    destination_paths.append(Path('storage-sync-v2.sqlite'))
    manifest = {'profile': str(profile), 'sourceFingerprint': before,
                'sourcePaths': [str(p) for p in source_paths],
                'paths': [str(p) for p in destination_paths], 'settings': result}
    (work / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f'Validated {len(result)} extension stores after restarting Firefox.', flush=True)
    print(f'Staged configuration: {work}', flush=True)


def commit(work, backup_root=None):
    manifest = json.loads((work / 'manifest.json').read_text())
    profile = Path(manifest['profile'])
    if fingerprint(profile, map(Path, manifest['sourcePaths'])) != manifest['sourceFingerprint']:
        raise RuntimeError('Firefox data changed after staging. Stage again before applying.')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = (backup_root or Path.home() / '.local/state/dotfiles/firefox/backups') / stamp
    backup.mkdir(parents=True, mode=0o700)
    paths = [Path(p) for p in manifest['paths']]
    absent = []
    for relative in paths:
        if (profile / relative).exists():
            copy_path(profile / relative, backup / relative)
        else:
            absent.append(str(relative))
    (backup / 'restore.json').write_text(json.dumps({'profile': str(profile), 'paths': manifest['paths'], 'absent': absent}, indent=2))
    try:
        for relative in paths:
            copy_path(work / 'editor-profile' / relative, profile / relative)
    except Exception:
        restore(backup)
        raise
    print(f'Applied extension settings and LinkSwift. Backup: {backup}')


def restore(backup):
    manifest = json.loads((backup / 'restore.json').read_text())
    profile = Path(manifest['profile'])
    for item in manifest['paths']:
        target = profile / item
        if target.is_dir():
            shutil.rmtree(target)
        elif target.exists():
            target.unlink()
        if item not in manifest['absent']:
            copy_path(backup / item, target)
    print(f'Restored Firefox extension data from {backup}')


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path)
    parser.add_argument('--backup-root', type=Path, help='override backup directory (useful for isolated validation)')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--stage', type=Path, help='build and verify configuration in a NEW private directory')
    group.add_argument('--commit', type=Path, help='back up and apply a previously verified staging directory')
    group.add_argument('--restore', type=Path, help='restore an extension backup with Firefox closed')
    args = parser.parse_args()
    if args.stage:
        profile = (args.profile or discover_profile()).resolve()
        with profile_lock(profile):
            prepare(profile, args.stage.resolve())
    elif args.commit:
        work = args.commit.resolve()
        profile = Path(json.loads((work / 'manifest.json').read_text())['profile'])
        with profile_lock(profile):
            commit(work, args.backup_root)
    else:
        backup = args.restore.resolve()
        profile = Path(json.loads((backup / 'restore.json').read_text())['profile'])
        with profile_lock(profile):
            restore(backup)


if __name__ == '__main__':
    main()
