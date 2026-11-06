#!/usr/bin/env bash
# Exercise the real installer and launcher with an isolated HOME/native process.
# No models, credentials, hooks, or working Herdr sessions are accessed.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v python3 >/dev/null || { echo 'skip: python3 is not installed'; exit 0; }
python3 - "$ROOT" <<'PY'
import json, os, pathlib, subprocess, sys, tempfile
root = pathlib.Path(sys.argv[1])
installer = root / 'setup/bin/codex-session-setup.sh'
with tempfile.TemporaryDirectory(prefix='matemate codex test ') as tmp:
    home = pathlib.Path(tmp)
    native = home / '.codex/packages/standalone/current/bin/codex'
    native.parent.mkdir(parents=True)
    native.write_text('''#!/usr/bin/env python3
import json, sys
if sys.argv[1:] == ['--help']: print('native Codex --no-daemon'); sys.exit(0)
print(json.dumps(sys.argv[1:]))
''')
    native.chmod(0o755)
    original = native.read_bytes()
    destination = home / '.local/bin/codex'
    destination.parent.mkdir(parents=True)
    destination.symlink_to(native)
    environment = dict(os.environ, HOME=tmp)
    def setup(*args):
        return subprocess.run(['bash', str(installer), *args], env=environment, capture_output=True, text=True)
    assert setup('--check').returncode != 0
    result = setup()
    assert result.returncode == 0, result.stderr
    assert setup('--check').returncode == 0
    backups = list(destination.parent.glob('codex.matemate-backup-*'))
    assert len(backups) == 1 and backups[0].is_symlink()
    assert native.read_bytes() == original
    assert setup().returncode == 0
    assert len(list(destination.parent.glob('codex.matemate-backup-*'))) == 1
    cases = [
        ('1', [], ['--no-daemon']),
        ('1', ['resume', 'thread-id'], ['--no-daemon', 'resume', 'thread-id']),
        ('1', ['fork', 'thread-id'], ['--no-daemon', 'fork', 'thread-id']),
        ('1', ['--yolo'], ['--no-daemon', '--yolo']),
        ('1', ['--model', 'chosen-model', 'resume', 'thread-id'], ['--no-daemon', '--model', 'chosen-model', 'resume', 'thread-id']),
        ('1', ['exec', 'test'], ['exec', 'test']),
        ('1', ['--model', 'chosen-model', 'exec', 'test'], ['--model', 'chosen-model', 'exec', 'test']),
        ('1', ['app-server', 'proxy'], ['app-server', 'proxy']),
        ('1', ['update'], ['update']),
        ('1', ['--remote', 'ws://localhost:1234'], ['--remote', 'ws://localhost:1234']),
        ('1', ['--no-daemon', 'resume', 'thread-id'], ['--no-daemon', 'resume', 'thread-id']),
        ('0', ['resume', 'thread-id'], ['resume', 'thread-id']),
    ]
    for marker, arguments, expected in cases:
        env = dict(environment, HERDR_ENV=marker)
        actual = json.loads(subprocess.check_output([str(destination), *arguments], env=env, text=True))
        assert actual == expected, (arguments, actual, expected)
    destination.unlink()
    destination.write_text('#!/bin/sh\necho custom launcher\n')
    destination.chmod(0o755)
    custom = destination.read_bytes()
    assert setup().returncode != 0 and destination.read_bytes() == custom
    destination.unlink()
    unrelated = home / 'unrelated'
    unrelated.write_text('#!/bin/sh\nexit 0\n'); unrelated.chmod(0o755)
    destination.symlink_to(unrelated)
    assert setup().returncode != 0 and destination.resolve() == unrelated.resolve()
    assert setup('--check').returncode != 0
print('ok - standalone Codex installation, idempotence, 12 argv cases, and custom-launcher refusal')
PY
