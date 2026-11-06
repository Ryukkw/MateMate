import { readFileSync, writeFileSync, copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';

// Windows Terminal accepts comments and trailing commas. Preserve quoted strings,
// including URLs, escaped quotes, and Windows paths while removing JSONC syntax.
export function parseJsonc(source) {
  let output = '', quoted = false, escape = false;
  for (let i = 0; i < source.length; i++) {
    const char = source[i];
    if (quoted) {
      output += char;
      if (escape) escape = false;
      else if (char === '\\') escape = true;
      else if (char === '"') quoted = false;
    } else if (char === '"') { quoted = true; output += char; }
    else if (char === '/' && source[i+1] === '/') {
      while (i < source.length && source[i] !== '\n') i++;
      output += '\n';
    } else if (char === '/' && source[i+1] === '*') {
      i += 2;
      while (i < source.length && !(source[i] === '*' && source[i+1] === '/')) i++;
      i++;
    } else if (char === ',') {
      // Defer trailing-comma removal to a second string-aware pass.
      output += char;
    } else output += char;
  }
  let cleaned = ''; quoted = false; escape = false;
  for (let i = 0; i < output.length; i++) {
    const char = output[i];
    if (quoted) {
      cleaned += char;
      if (escape) escape = false;
      else if (char === '\\') escape = true;
      else if (char === '"') quoted = false;
    } else if (char === '"') { quoted = true; cleaned += char; }
    else if (char === ',' && /^[\s]*[}\]]/.test(output.slice(i+1))) continue;
    else cleaned += char;
  }
  return JSON.parse(cleaned.replace(/^\uFEFF/, ''));
}

export function terminalSettings(settings) {
  const id = 'MateMate.ClipboardPaste';
  settings.actions ??= [];
  // A dedicated key emits the byte Herdr needs; Ctrl+Shift+V remains text paste.
  const command = { action: 'sendInput', input: '\u0016' };
  if (Array.isArray(settings.keybindings)) {
    settings.actions = settings.actions.filter(action => action.id !== id);
    settings.actions.push({ id, command });
    settings.keybindings = settings.keybindings.filter(binding => binding.keys !== 'ctrl+v');
    settings.keybindings.push({ id, keys: 'ctrl+v' });
  } else {
    settings.actions = settings.actions.filter(action => action.id !== id && action.keys !== 'ctrl+v');
    settings.actions.push({ id, command, keys: 'ctrl+v' });
  }
  return settings;
}

export function herdrSettings(source, { platform = process.platform } = {}) {
  const shortcut = platform === 'darwin' ? 'ctrl+alt+v' : 'ctrl+v';
  const stanza = `[[keys.command]]\nkey = "${shortcut}"\ntype = "plugin_action"\ncommand = "matemate.clipboard.paste"\ndescription = "Paste image file or text"\n`;
  const blocks = [...source.matchAll(/\[\[keys\.command\]\][\s\S]*?(?=\n\[|$)/g)];
  const owned = blocks.filter(block => /command\s*=\s*["']matemate\.clipboard\.(paste|attach)["']/.test(block[0]));
  const keyPattern = new RegExp(`key\\s*=\\s*["']${shortcut.replace(/\+/g, '\\+')}["']`);
  if (blocks.some(block => !owned.includes(block) && keyPattern.test(block[0]))) {
    throw new Error(`Herdr already has a custom ${shortcut} binding; it has been left unchanged.`);
  }
  if (owned.length) {
    let updated = source;
    for (let index = owned.length - 1; index >= 0; index--) {
      const block = owned[index];
      updated = updated.slice(0, block.index) + (index === 0 ? stanza : '') + updated.slice(block.index + block[0].length);
    }
    return updated.replace('# MateMate: optional image preview; native Ctrl+V remains available.', '# MateMate: console clipboard support.');
  }
  return source + '\n# MateMate: console clipboard support.\n' + stanza;
}

function update(path, transform) {
  const original = existsSync(path) ? readFileSync(path, 'utf8') : '';
  const updated = transform(original);
  if (original === updated) return;
  mkdirSync(dirname(path), { recursive: true });
  if (existsSync(path)) copyFileSync(path, `${path}.matemate-backup-${Date.now()}`);
  writeFileSync(path, updated);
  console.log(`Configured: ${path}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const args = process.argv.slice(2);
  const value = key => args.includes(key) ? args[args.indexOf(key)+1] : undefined;
  const config = value('--herdr-config') || (process.platform === 'win32'
    ? join(process.env.APPDATA, 'herdr', 'config.toml')
    : join(process.env.XDG_CONFIG_HOME || join(homedir(), '.config'), 'herdr', 'config.toml'));
  update(config, herdrSettings);
  const terminal = value('--terminal-settings');
  if (terminal) {
    if (!existsSync(terminal)) throw new Error(`Windows Terminal settings not found: ${terminal}`);
    update(terminal, text => JSON.stringify(terminalSettings(parseJsonc(text)), null, 4) + '\n');
  }
}
