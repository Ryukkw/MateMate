import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { paste } from '../setup/plugins/clipboard/paste.mjs';
import { parseJsonc, terminalSettings, herdrSettings } from '../setup/plugins/clipboard/configure.mjs';

test('Windows Terminal JSONC preserves paths, strings and unrelated preferences', () => {
  const input = '{ // comment\n"profiles":{"list":[{"commandline":"C:\\\\Tools\\\\pwsh.exe","name":"keep,}",},],},"url":"https://example.com",/* end */}';
  const parsed = parseJsonc(input), configured = terminalSettings(parsed);
  assert.equal(configured.url, 'https://example.com');
  assert.equal(configured.profiles.list[0].name, 'keep,}');
  assert.equal(configured.profiles.list[0].commandline, 'C:\\Tools\\pwsh.exe');
  assert.equal(configured.actions.at(-1).command.input, '\x16');
  assert.equal(configured.actions.at(-1).keys, 'ctrl+v');
  assert.deepEqual(terminalSettings(structuredClone(configured)), configured);
});
test('modern Windows Terminal bindings preserve text paste and remain idempotent', () => {
  const result = terminalSettings({keybindings:[{keys:'ctrl+v', id:'old'}, {keys:'ctrl+shift+v',id:'paste'}]});
  assert.equal(result.keybindings.filter(k => k.keys === 'ctrl+v').length, 1);
  assert.ok(result.keybindings.some(k => k.keys === 'ctrl+shift+v' && k.id === 'paste'));
  assert.deepEqual(terminalSettings(structuredClone(result)), result);
});
test('Herdr configuration preserves user settings and refuses a conflicting shortcut', () => {
  for (const platform of ['darwin','win32']) {
    const text = herdrSettings('onboarding = false\n', { platform });
    assert.equal(herdrSettings(text, { platform }), text);
  }
  assert.throws(() => herdrSettings('[[keys.command]]\nkey = "ctrl+v"\ncommand = "custom"', {platform:'win32'}));
});
test('upgrade replaces only MateMate clipboard binding and keeps unrelated bindings', () => {
  const before = 'onboarding = false\n[[keys.command]]\nkey = "ctrl+alt+p"\ncommand = "matemate.clipboard.paste"\n[[keys.command]]\nkey = "ctrl+alt+x"\ncommand = "custom"\n';
  const after = herdrSettings(before, {platform:'darwin'});
  assert.equal(herdrSettings(after, {platform:'darwin'}), after);
  const config = JSON.parse(execFileSync('python3', ['-c',
    'import json, sys, tomllib; json.dump(tomllib.loads(sys.stdin.read()), sys.stdout)',
  ], {input: after, encoding: 'utf8'}));
  assert.equal(config.onboarding, false);
  assert.deepEqual(config.keys.command, [
    {key: 'ctrl+alt+v', type: 'plugin_action', command: 'matemate.clipboard.paste', description: 'Paste image file or text'},
    {key: 'ctrl+alt+x', command: 'custom'},
  ]);
});
test('image paste uses the exact saved PNG and never opens a viewer or sends Enter', async () => {
  const calls = []; let bytes;
  await paste({pane:'test:p1',
    clipboard:{hasImage:()=>true,getImageBinary:async()=>[137,80,78,71]},
    save(data) { assert.ok(Buffer.isBuffer(data)); bytes=data; return '/tmp/paste test/image.png'; },
    herdr(...args) { calls.push(args); },
  });
  assert.deepEqual([...bytes], [137,80,78,71]);
  assert.deepEqual(calls, [['pane','send-text','test:p1',' "/tmp/paste test/image.png" ']]);
});
test('plain text is pasted into the composer without submitting it', async () => {
  const calls=[];
  await paste({pane:'test:p1',clipboard:{hasImage:()=>false,getText:async()=>'line 1\nline 2'},herdr:(...args)=>calls.push(args)});
  assert.deepEqual(calls,[['pane','send-text','test:p1','line 1\nline 2']]);
});
test('missing pane and empty image fail without writing files or sending input', async () => {
  await assert.rejects(paste({pane:null}),/Focus an agent/);
  let changed=false;
  await assert.rejects(paste({pane:'test:p1',clipboard:{hasImage:()=>true,getImageBinary:async()=>[]},save:()=>{changed=true},herdr:()=>{changed=true}}),/empty/);
  assert.equal(changed,false);
});
