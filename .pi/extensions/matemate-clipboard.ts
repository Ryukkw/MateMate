// Console-only clipboard support: saved PNG paths in the composer and original
// image bytes attached to the model. No widgets, viewers, or desktop UI.
import { createRequire } from "node:module";
import { existsSync, realpathSync, mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { delimiter, join } from "node:path";
import { tmpdir } from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

function dependencies() {
  const entry = process.argv[1];
  const executable = entry && existsSync(entry) && /pi-coding-agent/.test(realpathSync(entry))
    ? entry
    : (process.env.PATH ?? "").split(delimiter).map(dir => join(dir, "pi")).find(path => existsSync(path));
  if (!executable) throw new Error("Не найден установленный Pi");
  return createRequire(realpathSync(executable));
}

export default function clipboardExtension(pi: ExtensionAPI) {
  let busy = false;
  let revision = 0;
  const attachments = new Set<string>();
  const paste = async (ctx: ExtensionContext) => {
    if (!ctx.hasUI || busy) return;
    busy = true;
    const current = revision;
    try {
      const clipboard = dependencies()("@mariozechner/clipboard");
      if (!clipboard.hasImage()) {
        const text = await clipboard.getText();
        if (text && current === revision) ctx.ui.pasteToEditor(text);
        return;
      }
      const bytes = Uint8Array.from(await clipboard.getImageBinary());
      if (!bytes.length || current !== revision) return;
      const file = join(mkdtempSync(join(tmpdir(), "matemate-clipboard-")), "image.png");
      writeFileSync(file, bytes, { mode: 0o600 });
      attachments.add(file);
      ctx.ui.pasteToEditor(` ${file} `);
    } catch (error) {
      ctx.ui.notify(`Не удалось вставить из буфера: ${error instanceof Error ? error.message : String(error)}`, "error");
    } finally { busy = false; }
  };
  pi.registerShortcut("ctrl+v", { description: "Вставить картинку или текст из буфера", handler: paste });
  pi.on("input", (event, ctx) => {
    revision++;
    if (event.source !== "interactive" || event.text.trimStart().startsWith("!")) return;
    const images = [...(event.images ?? [])];
    for (const file of attachments) {
      const escaped = file.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      if (new RegExp(`(^|[\\s"'])${escaped}(?=$|[\\s"'])`).test(event.text)) {
        try { images.push({ type: "image", data: readFileSync(file).toString("base64"), mimeType: "image/png" }); }
        catch { ctx.ui.notify("Файл картинки больше недоступен. Вставь её ещё раз.", "warning"); }
      }
    }
    if (images.length > (event.images?.length ?? 0)) return { action: "transform" as const, text: event.text, images };
  });
  pi.on("session_start", () => { revision++; attachments.clear(); });
}
