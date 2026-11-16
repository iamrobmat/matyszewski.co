import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, readdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

test("prepare-deck wyciąga obrazy, poprawia CSP i jest deterministyczny", async () => {
  const directory = await mkdtemp(join(tmpdir(), "live-deck-"));
  const source = join(directory, "source.html");
  const output = join(directory, "deck", "index.html");
  const pixel = Buffer.from("89504e470d0a1a0a00000000", "hex").toString("base64");
  await writeFile(source, `<!doctype html><meta http-equiv="Content-Security-Policy" content="img-src data: blob:;"><section class="deck-slide"><img src="data:image/png;base64,${pixel}"></section>`);

  const args = [resolve("scripts/prepare-deck.mjs"), "--source", source, "--output", output];
  await execFileAsync(process.execPath, args);
  const firstHtml = await readFile(output, "utf8");
  const firstHash = createHash("sha256").update(firstHtml).digest("hex");
  const images = await readdir(join(directory, "deck", "img"));

  assert.match(firstHtml, /img-src 'self' data: blob:/);
  assert.match(firstHtml, /src="img\/image-01-[a-f0-9]{12}\.png"/);
  assert.equal(images.length, 1);

  await execFileAsync(process.execPath, args);
  const secondHtml = await readFile(output, "utf8");
  assert.equal(createHash("sha256").update(secondHtml).digest("hex"), firstHash);
});
