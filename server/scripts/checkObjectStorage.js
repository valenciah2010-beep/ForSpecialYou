import assert from "node:assert/strict";
import crypto from "node:crypto";
import sharp from "sharp";
import { serverConfig, validateEnvironment } from "../src/config.js";
import { createR2Store } from "../src/storage/r2Store.js";

validateEnvironment();
if (serverConfig.imageStorage !== "r2")
  throw new Error("IMAGE_STORAGE must be r2 for this check.");
const store = createR2Store(serverConfig.r2);
const key = `${serverConfig.r2.prefix}_checks/${crypto.randomUUID()}.jpg`;
try {
  // Synthetic pixels only; never use an existing user's photo or health record.
  const bytes = await sharp({
    create: { width: 8, height: 8, channels: 3, background: "#336644" },
  })
    .jpeg()
    .toBuffer();
  await store.put(key, bytes);
  assert.deepEqual(await store.get(key), bytes);
  const keys = [];
  for await (const found of store.keys(key)) keys.push(found);
  assert.ok(keys.includes(key));
  const unsigned = await fetch(
    `${serverConfig.r2.endpoint}/${serverConfig.r2.bucket}/${key}`,
    { signal: AbortSignal.timeout(15000) },
  );
  assert.ok(
    [400, 401, 403, 404].includes(unsigned.status),
    "Object must reject unsigned access",
  );
  await store.remove(key);
  assert.equal(await store.get(key), null);
  console.log(
    "R2_CHECK_PASSED: put/get/list/delete, exact bytes, unsigned access denied; no business data used.",
  );
} finally {
  try {
    await store.remove(key);
  } finally {
    store.close();
  }
}
