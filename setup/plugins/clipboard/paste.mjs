// Attach the saved clipboard image by path, without opening a viewer or submitting
// a prompt. Saving first avoids rereading a clipboard that may change meanwhile.
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

export async function paste({ clipboard, herdr, pane, save }) {
  if (!pane) throw new Error('Focus an agent before pasting.');
  if (!clipboard.hasImage()) {
    const text = await clipboard.getText();
    if (text) herdr('pane', 'send-text', pane, text);
    return;
  }
  const bytes = Buffer.from(await clipboard.getImageBinary());
  if (!bytes.length) throw new Error('Clipboard image is empty');
  const file = save(bytes);
  herdr('pane', 'send-text', pane, ` "${file}" `);
}

if (process.env.HERDR_PLUGIN_ACTION_ID) {
  const require = createRequire(import.meta.url);
  const context = JSON.parse(process.env.HERDR_PLUGIN_CONTEXT_JSON || '{}');
  const pane = process.env.HERDR_PANE_ID || context.focused_pane_id || context.pane_id;
  const binary = process.env.HERDR_BIN_PATH || 'herdr';
  await paste({ clipboard: require('@mariozechner/clipboard'), pane,
    herdr: (...args) => execFileSync(binary, args, { windowsHide: true, maxBuffer: 4 * 1024 * 1024 }),
    save(bytes) {
      const file = join(mkdtempSync(join(tmpdir(), 'matemate-clipboard-')), 'image.png');
      writeFileSync(file, bytes, { mode: 0o600 });
      return file;
    },
  });
}
