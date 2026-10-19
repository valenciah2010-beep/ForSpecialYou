import { test } from "node:test";
import assert from "node:assert/strict";
import { createR2Store } from "../src/storage/r2Store.js";
import { startS3Fixture } from "./helpers/s3Fixture.js";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { serverConfig } from "../src/config.js";
import {
  writeImage,
  readImage,
  removeImage,
  uploadDirectory,
  imageObjectKey,
  remoteImageStore,
} from "../src/storage/imageStore.js";

test("S3 images stay private, preserve bytes, paginate only their prefix and delete idempotently", async () => {
  const fixture = await startS3Fixture();
  const store = createR2Store(fixture.settings);
  try {
    const bytes = Buffer.from([0xff, 0xd8, 0x00, 0xff, 0xd9]);
    for (const key of ["app/a", "app/b", "app/c", "other/private"])
      await store.put(key, bytes);
    assert.deepEqual(await store.get("app/a"), bytes);
    assert.equal(await store.get("app/missing"), null);
    const keys = [];
    for await (const key of store.keys("app/")) keys.push(key);
    assert.deepEqual(keys, ["app/a", "app/b", "app/c"]);
    const put = fixture.requests.find((r) => r.method === "PUT");
    assert.equal(put.headers["content-type"], "image/jpeg");
    assert.equal(put.headers["cache-control"], "private, no-store");
    assert.equal(put.headers["x-amz-acl"], undefined);
    await store.remove("app/a");
    await store.remove("app/a");
    assert.equal(await store.get("app/a"), null);
    assert.ok(fixture.objects.has("other/private"));
  } finally {
    store.close();
    await fixture.close();
  }
});

test("R2 outages fail retryably without leaking upstream details or credentials", async () => {
  const fixture = await startS3Fixture();
  const store = createR2Store(fixture.settings);
  fixture.fail(true);
  try {
    for (const action of [
      () => store.get("app/a"),
      () => store.put("app/a", Buffer.from("test")),
      () => store.remove("app/a"),
    ])
      await assert.rejects(action, (error) => {
        assert.equal(error.status, 503);
        assert.doesNotMatch(
          error.message,
          /Private upstream|fixture|AccessDenied/,
        );
        return true;
      });
  } finally {
    store.close();
    await fixture.close();
  }
});

test("interrupted R2 writes retry, legacy fallback works only for missing objects and outages preserve deletion metadata", async () => {
  const fixture = await startS3Fixture();
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "fsy-storage-"));
  const previous = {
    imageStorage: serverConfig.imageStorage,
    r2: serverConfig.r2,
    uploadPath: serverConfig.uploadPath,
  };
  const id = crypto.randomUUID();
  const bytes = Buffer.from("synthetic image store bytes");
  Object.assign(serverConfig, {
    imageStorage: "r2",
    r2: { ...fixture.settings, prefix: "app/" },
    uploadPath: directory,
  });
  try {
    fixture.fail(true);
    await assert.rejects(() => writeImage(id, bytes), { status: 503 });
    assert.equal(fixture.objects.size, 0);
    fixture.fail(false);
    await writeImage(id, bytes);
    await fs.rm(uploadDirectory(id), { recursive: true });
    assert.deepEqual(await readImage(id), bytes);
    await fs.mkdir(uploadDirectory(id));
    await fs.writeFile(path.join(uploadDirectory(id), "image.jpg"), bytes);
    fixture.objects.delete(imageObjectKey(id));
    assert.deepEqual(await readImage(id), bytes);
    fixture.fail(true);
    // A real upstream outage must never be masked by a local cached copy.
    await assert.rejects(() => readImage(id), { status: 503 });
    await assert.rejects(() => removeImage(id), { status: 503 });
    assert.deepEqual(
      await fs.readFile(path.join(uploadDirectory(id), "image.jpg")),
      bytes,
    );
    fixture.fail(false);
    await removeImage(id);
    await assert.rejects(() => readImage(id), { status: 404 });
  } finally {
    remoteImageStore()?.close();
    Object.assign(serverConfig, previous);
    await fs.rm(directory, { recursive: true, force: true });
    await fixture.close();
  }
});
