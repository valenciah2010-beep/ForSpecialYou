import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs/promises";
import sharp from "sharp";
import bcrypt from "bcryptjs";
import { pool } from "../src/db.js";
import { createServerApp } from "../src/app.js";
import { createSession, hashToken } from "../src/services/sessions.js";
import { reserveQuota } from "../src/services/aiQuota.js";
import { serverConfig } from "../src/config.js";
import { cleanupUploads } from "../src/services/uploads.js";
import { getRetentionPolicy } from "../src/services/storageRetention.js";
import {
  remoteImageStore,
  imageObjectKey,
  uploadDirectory,
} from "../src/storage/imageStore.js";
import path from "node:path";
let server, base, alice, bob, admin, token, adminCookie;
const browserHeaders = {
  origin: "http://localhost:5223",
  "X-Requested-With": "CarePortal",
};
async function request(
  path,
  { body, auth = token, headers = {}, method = "POST" } = {},
) {
  const response = await fetch(base + path, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(auth ? { authorization: "Bearer " + auth } : {}),
      ...headers,
    },
    body:
      body === undefined
        ? method === "GET"
          ? undefined
          : "{}"
        : JSON.stringify(body),
  });
  const data = await response.json().catch(() => null);
  return { response, data, status: response.status };
}
before(async () => {
  const hash = await bcrypt.hash("FixturePassword1", 4);
  for (const name of ["alice", "bob", "admin"]) {
    const [result] = await pool.execute(
      "INSERT INTO users (username,email,password_hash,role) VALUES (?,?,?,?)",
      [
        name,
        name + "@example.test",
        hash,
        name === "admin" ? "admin" : "parent",
      ],
    );
    if (name === "alice") alice = result.insertId;
    else if (name === "bob") bob = result.insertId;
    else admin = result.insertId;
  }
  token = await createSession(alice, "app");
  const adminToken = await createSession(admin, "admin");
  adminCookie = "care_portal_admin_session=" + adminToken;
  server = createServerApp().listen(0, "127.0.0.1");
  await new Promise((r) => server.once("listening", r));
  base = "http://127.0.0.1:" + server.address().port;
});
after(async () => {
  await new Promise((r) => server.close(r));
  remoteImageStore()?.close();
  await pool.end();
  await fs.rm(serverConfig.uploadPath, { recursive: true, force: true });
});
test("health endpoint stays independent from authenticated APIs", async () => {
  assert.equal(
    (await request("/api/health", { method: "GET", auth: null })).status,
    200,
  );
});
test("anonymous and forged-token access cannot read or write health data", async () => {
  for (const path of [
    "/api/app-data/load",
    "/api/app-data",
    "/api/app-session",
    "/api/app-settings",
    "/api/analyze-meal",
    "/api/health-insights",
  ]) {
    assert.equal(
      (await request(path, { auth: null, body: { userId: alice } })).status,
      401,
    );
    assert.equal(
      (await request(path, { auth: "0".repeat(64), body: { userId: alice } }))
        .status,
      401,
    );
  }
});
test("authenticated users cannot use another account id", async () => {
  for (const path of [
    "/api/app-data/load",
    "/api/app-data",
    "/api/app-session",
    "/api/app-settings",
  ])
    assert.equal(
      (await request(path, { body: { userId: bob, healthLogs: [] } })).status,
      403,
    );
});
test("partial sync preserves omitted collections and rejects malformed arrays", async () => {
  assert.equal(
    (
      await request("/api/app-data", {
        body: {
          userId: alice,
          healthLogs: [{ id: "h1", title: "sleep" }],
          savedMeals: [],
        },
      })
    ).status,
    200,
  );
  assert.equal(
    (
      await request("/api/app-data", {
        body: {
          userId: alice,
          childProfile: { fullName: "private" },
          healthLogs: null,
          savedMeals: null,
        },
      })
    ).status,
    200,
  );
  assert.equal(
    (await request("/api/app-data/load", { body: { userId: alice } })).data
      .healthLogs.length,
    1,
  );
  assert.equal(
    (await request("/api/app-data", { body: { healthLogs: "invalid" } }))
      .status,
    400,
  );
});
test("blocked and expired sessions are rejected on every request", async () => {
  await pool.execute("UPDATE users SET blocked_indefinitely=1 WHERE id=?", [
    alice,
  ]);
  assert.equal(
    (await request("/api/app-data", { body: { healthLogs: [] } })).status,
    403,
  );
  await pool.execute("UPDATE users SET blocked_indefinitely=0 WHERE id=?", [
    alice,
  ]);
  const expired = await createSession(alice, "app");
  await pool.execute(
    "UPDATE auth_sessions SET expires_at=DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 SECOND) WHERE token_hash=?",
    [hashToken(expired)],
  );
  assert.equal(
    (await request("/api/app-session", { auth: expired })).status,
    401,
  );
});
test("server quota is atomic across devices and cannot be reset by sync", async () => {
  await pool.execute(
    "INSERT INTO parent_app_data (user_id,nutrient_daily_limit) VALUES (?,3) ON DUPLICATE KEY UPDATE nutrient_daily_limit=3",
    [alice],
  );
  const results = await Promise.allSettled(
    Array.from({ length: 8 }, () => reserveQuota(alice, "meal")),
  );
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 3);
  await request("/api/app-data", {
    body: { nutrientDailyUsage: { estimateCount: 0 } },
  });
  assert.equal(
    (await request("/api/app-settings")).data.nutrientDailyUsage.estimateCount,
    3,
  );
});
test("AI endpoints require separate consent and operator configuration", async () => {
  assert.equal(
    (
      await request("/api/health-insights", {
        body: { logs: [{ title: "sleep" }] },
      })
    ).status,
    403,
  );
  assert.equal(
    (await request("/api/analyze-meal", { body: { aiConsent: true } })).status,
    503,
  );
});
test("session survives app recreation and logout revokes the bearer token", async () => {
  const login = await request("/api/login", {
    auth: null,
    body: { username: "bob", password: "FixturePassword1" },
  });
  assert.equal(login.status, 200);
  const saved = login.data.token;
  assert.match(saved, /^[a-f0-9]{64}$/);
  const second = createServerApp().listen(0, "127.0.0.1");
  await new Promise((r) => second.once("listening", r));
  const response = await fetch(
    "http://127.0.0.1:" + second.address().port + "/api/app-session",
    {
      method: "POST",
      headers: {
        authorization: "Bearer " + saved,
        "Content-Type": "application/json",
      },
      body: "{}",
    },
  );
  assert.equal(response.status, 200);
  await new Promise((r) => second.close(r));
  assert.equal((await request("/api/app-logout", { auth: saved })).status, 200);
  assert.equal(
    (await request("/api/app-session", { auth: saved })).status,
    401,
  );
});
test("admin cookie uses Lax, rejects CSRF and records successful mutations", async () => {
  const login = await request("/api/admin/login", {
    auth: null,
    headers: browserHeaders,
    body: { username: "admin", password: "FixturePassword1" },
  });
  assert.equal(login.status, 200);
  assert.match(login.response.headers.get("set-cookie"), /SameSite=Lax/);
  assert.equal(
    (
      await request("/api/users/" + bob, {
        auth: null,
        method: "PUT",
        headers: { cookie: adminCookie },
        body: { nickname: "bob", email: "bob@example.test" },
      })
    ).status,
    403,
  );
  const success = await request(
    "/api/admin/app-users/" + bob + "/nutrient-limit",
    {
      auth: null,
      method: "PATCH",
      headers: { ...browserHeaders, cookie: adminCookie },
      body: { dailyLimit: 2 },
    },
  );
  assert.equal(success.status, 200);
  const [events] = await pool.execute(
    "SELECT * FROM audit_events WHERE actor_id=?",
    [admin],
  );
  assert.ok(events.length > 0);
});
test("password change revokes all existing user sessions", async () => {
  const [[oldCredential]] = await pool.execute(
    "SELECT password_hash FROM users WHERE id=?",
    [bob],
  );
  const saved = await createSession(bob, "app");
  const result = await request("/api/users/" + bob, {
    auth: null,
    method: "PUT",
    headers: { ...browserHeaders, cookie: adminCookie },
    body: {
      nickname: "bob",
      email: "bob@example.test",
      password: "NewPassword123",
    },
  });
  assert.equal(result.status, 200);
  await assert.rejects(
    () => createSession(bob, "app", oldCredential.password_hash),
    { status: 401 },
  );
  assert.equal(
    (await request("/api/app-session", { auth: saved })).status,
    401,
  );
});
test("chunk uploads enforce ownership, missing chunks, checksums and real image content", async () => {
  const image = await sharp({
    create: { width: 400, height: 300, channels: 3, background: "#335544" },
  })
    .png()
    .toBuffer();
  const checksum = crypto.createHash("sha256").update(image).digest("hex");
  const init = await request("/api/uploads", {
    body: { size: image.length, checksum },
  });
  assert.equal(init.status, 201);
  const id = init.data.id;
  assert.equal((await request("/api/uploads/" + id + "/complete")).status, 409);
  const other = await createSession(bob, "app");
  assert.equal(
    (await request("/api/uploads/" + id, { method: "GET", auth: other }))
      .status,
    404,
  );
  const chunk = await request("/api/uploads/" + id + "/chunks/0", {
    method: "PUT",
    body: { data: image.toString("base64") },
  });
  assert.equal(chunk.status, 200);
  const status = await request("/api/uploads/" + id, { method: "GET" });
  assert.deepEqual(status.data.chunks, [0]);
  const completed = await request("/api/uploads/" + id + "/complete");
  assert.equal(completed.status, 200);
  assert.equal((await request("/api/uploads/" + id + "/complete")).status, 200);
  const content = await fetch(base + completed.data.url, {
    headers: { authorization: "Bearer " + token },
  });
  assert.equal(content.status, 200);
  assert.equal(content.headers.get("content-type"), "image/jpeg");
  const expected = Buffer.from(await content.arrayBuffer());
  if (serverConfig.imageStorage === "r2") {
    // Remove the local final copy: authenticated display must come from R2.
    await fs.unlink(path.join(uploadDirectory(id), "image.jpg"));
    const fromR2 = await fetch(base + completed.data.url, {
      headers: { authorization: "Bearer " + token },
    });
    assert.equal(fromR2.status, 200);
    assert.deepEqual(Buffer.from(await fromR2.arrayBuffer()), expected);
    assert.deepEqual(
      await remoteImageStore().get(imageObjectKey(id)),
      expected,
    );
  }
  assert.equal(
    (await request(completed.data.url, { method: "GET", auth: null })).status,
    401,
  );
  assert.equal(
    (await request(completed.data.url, { method: "GET", auth: other })).status,
    404,
  );
  const wrong = await request("/api/uploads", {
    body: { size: image.length, checksum: "0".repeat(64) },
  });
  await request("/api/uploads/" + wrong.data.id + "/chunks/0", {
    method: "PUT",
    body: { data: image.toString("base64") },
  });
  assert.equal(
    (await request("/api/uploads/" + wrong.data.id + "/complete")).status,
    400,
  );
});
test("login rate limit is enforced by the shared DB store", async () => {
  for (let i = 0; i < 11; i++)
    await request("/api/login", {
      auth: null,
      body: { username: "missing", password: "bad" },
    });
  assert.equal(
    (
      await request("/api/login", {
        auth: null,
        body: { username: "missing", password: "bad" },
      })
    ).status,
    429,
  );
});

test("multi-chunk images resume out of order and tolerate repeated chunks", async () => {
  const image = await sharp(crypto.randomBytes(800 * 800 * 3), {
    raw: { width: 800, height: 800, channels: 3 },
  })
    .png()
    .toBuffer();
  const chunkBytes = 512 * 1024;
  assert.ok(image.length > chunkBytes * 2);
  const init = await request("/api/uploads", {
    body: {
      size: image.length,
      checksum: crypto.createHash("sha256").update(image).digest("hex"),
    },
  });
  assert.equal(init.status, 201);
  const path = "/api/uploads/" + init.data.id;
  const sendChunk = (index) =>
    request(path + "/chunks/" + index, {
      method: "PUT",
      body: {
        data: image
          .subarray(index * chunkBytes, (index + 1) * chunkBytes)
          .toString("base64"),
      },
    });
  assert.equal((await sendChunk(1)).status, 200);
  assert.equal((await sendChunk(1)).status, 200);
  assert.deepEqual((await request(path, { method: "GET" })).data.chunks, [1]);
  assert.equal((await request(path + "/complete")).status, 409);
  for (let index = 0; index < Math.ceil(image.length / chunkBytes); index++) {
    if (index !== 1) assert.equal((await sendChunk(index)).status, 200);
  }
  assert.equal((await request(path + "/complete")).status, 200);
  const content = await fetch(base + path + "/content", {
    headers: { authorization: "Bearer " + token },
  });
  const metadata = await sharp(
    Buffer.from(await content.arrayBuffer()),
  ).metadata();
  assert.equal(metadata.width, 800);
  assert.equal((await request(path, { method: "DELETE" })).status, 204);
  assert.equal((await request(path, { method: "GET" })).status, 404);
  if (serverConfig.imageStorage === "r2")
    assert.equal(
      await remoteImageStore().get(imageObjectKey(init.data.id)),
      null,
    );
});

test("storage cleanup removes expired images and cascade orphans, preserving legacy images", async () => {
  const image = await sharp({
    create: { width: 8, height: 8, channels: 3, background: "#336644" },
  })
    .jpeg()
    .toBuffer();
  // A pre-R2 completed upload remains readable without any business-data migration.
  const legacy = crypto.randomUUID();
  await pool.execute(
    "INSERT INTO image_uploads (id,user_id,total_bytes,chunk_count,checksum,completed,expires_at) VALUES (?,?,?,1,?,1,DATE_ADD(UTC_TIMESTAMP(), INTERVAL 1 DAY))",
    [
      legacy,
      alice,
      image.length,
      crypto.createHash("sha256").update(image).digest("hex"),
    ],
  );
  await fs.mkdir(uploadDirectory(legacy), { recursive: true, mode: 0o700 });
  await fs.writeFile(path.join(uploadDirectory(legacy), "image.jpg"), image);
  const response = await fetch(base + `/api/uploads/${legacy}/content`, {
    headers: { authorization: "Bearer " + token },
  });
  assert.equal(response.status, 200);
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), image);
  const expired = crypto.randomUUID(),
    orphan = crypto.randomUUID();
  await pool.execute(
    "INSERT INTO image_uploads (id,user_id,total_bytes,chunk_count,checksum,completed,expires_at) VALUES (?,?,?,1,?,1,DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY))",
    [expired, alice, image.length, "0".repeat(64)],
  );
  for (const id of [expired, orphan]) {
    await fs.mkdir(uploadDirectory(id), { recursive: true });
    await fs.writeFile(path.join(uploadDirectory(id), "image.jpg"), image);
    await remoteImageStore()?.put(imageObjectKey(id), image);
  }
  await cleanupUploads();
  for (const id of [expired, orphan]) {
    await assert.rejects(fs.access(uploadDirectory(id)));
    if (serverConfig.imageStorage === "r2")
      assert.equal(await remoteImageStore().get(imageObjectKey(id)), null);
  }
  assert.ok(await fs.readFile(path.join(uploadDirectory(legacy), "image.jpg")));
  const [[row]] = await pool.query(
    "SELECT COUNT(*) AS count FROM image_uploads WHERE id=?",
    [expired],
  );
  assert.equal(row.count, 0);
});

test("storage settings require an admin session, CSRF and strict durations", async () => {
  const route = "/api/admin/settings/storage";
  const headers = { ...browserHeaders, cookie: adminCookie };
  assert.equal(
    (await request(route, { method: "GET", auth: null })).status,
    401,
  );
  assert.equal((await request(route, { method: "GET" })).status, 401);
  const read = await request(route, { method: "GET", headers });
  assert.equal(read.status, 200);
  assert.deepEqual(read.data.policy, {
    incompleteHours: 24,
    completedDays: 30,
    revision: 1,
  });
  assert.equal(
    (
      await request(route, {
        method: "PUT",
        headers: { cookie: adminCookie },
        body: { ...read.data.policy, applyToExisting: false },
      })
    ).status,
    403,
  );
  assert.equal(
    (
      await request(route, {
        method: "PUT",
        headers: browserHeaders,
        body: { ...read.data.policy, applyToExisting: false },
      })
    ).status,
    401,
  );
  for (const patch of [
    { incompleteHours: 0 },
    { incompleteHours: 721 },
    { incompleteHours: 1.5 },
    { incompleteHours: "24" },
    { completedDays: 0 },
    { completedDays: 36501 },
    { completedDays: false },
    { applyToExisting: "true" },
    { revision: 0 },
  ]) {
    assert.equal(
      (
        await request(route, {
          method: "PUT",
          headers,
          body: { ...read.data.policy, applyToExisting: false, ...patch },
        })
      ).status,
      400,
    );
  }
  assert.deepEqual(await getRetentionPolicy(), read.data.policy);
});

test("retention settings persist, detect stale saves and determine new upload deadlines", async () => {
  const route = "/api/admin/settings/storage";
  const headers = { ...browserHeaders, cookie: adminCookie };
  const initial = await getRetentionPolicy();
  const save = await request(route, {
    method: "PUT",
    headers,
    body: {
      incompleteHours: 2,
      completedDays: 7,
      revision: initial.revision,
      applyToExisting: false,
    },
  });
  assert.equal(save.status, 200);
  assert.deepEqual(
    (await request(route, { method: "GET", headers })).data.policy,
    save.data.policy,
  );
  assert.equal(
    (
      await request(route, {
        method: "PUT",
        headers,
        body: { ...initial, applyToExisting: false },
      })
    ).status,
    409,
  );
  const image = await sharp({
    create: { width: 8, height: 8, channels: 3, background: "#336644" },
  })
    .png()
    .toBuffer();
  const checksum = crypto.createHash("sha256").update(image).digest("hex");
  const init = await request("/api/uploads", {
    body: { size: image.length, checksum },
  });
  assert.equal(init.status, 201);
  const id = init.data.id;
  const [[pending]] = await pool.query(
    "SELECT TIMESTAMPDIFF(SECOND,retention_started_at,expires_at) AS ttl FROM image_uploads WHERE id=?",
    [id],
  );
  assert.equal(pending.ttl, 7200);
  await request(`/api/uploads/${id}/chunks/0`, {
    method: "PUT",
    body: { data: image.toString("base64") },
  });
  assert.equal((await request(`/api/uploads/${id}/complete`)).status, 200);
  const [[finished]] = await pool.query(
    "SELECT expires_at,retention_started_at,TIMESTAMPDIFF(SECOND,retention_started_at,expires_at) AS ttl FROM image_uploads WHERE id=?",
    [id],
  );
  assert.equal(finished.ttl, 7 * 86400);
  assert.equal((await request(`/api/uploads/${id}/complete`)).status, 200);
  const [[repeated]] = await pool.query(
    "SELECT expires_at,retention_started_at FROM image_uploads WHERE id=?",
    [id],
  );
  assert.equal(repeated.expires_at.getTime(), finished.expires_at.getTime());
  assert.equal(
    repeated.retention_started_at.getTime(),
    finished.retention_started_at.getTime(),
  );
  assert.equal(
    (
      await request(route, {
        method: "PUT",
        headers,
        body: {
          ...save.data.policy,
          completedDays: null,
          applyToExisting: false,
        },
      })
    ).status,
    200,
  );
  const [[unchanged]] = await pool.query(
    "SELECT expires_at FROM image_uploads WHERE id=?",
    [id],
  );
  assert.equal(unchanged.expires_at.getTime(), finished.expires_at.getTime());
  await request(`/api/uploads/${id}`, { method: "DELETE" });
});

test("permanent files survive both storage cleanup and account quotas still include them", async () => {
  const image = await sharp({
    create: { width: 8, height: 8, channels: 3, background: "#336644" },
  })
    .png()
    .toBuffer();
  const init = await request("/api/uploads", {
    body: {
      size: image.length,
      checksum: crypto.createHash("sha256").update(image).digest("hex"),
    },
  });
  const id = init.data.id;
  await request(`/api/uploads/${id}/chunks/0`, {
    method: "PUT",
    body: { data: image.toString("base64") },
  });
  assert.equal((await request(`/api/uploads/${id}/complete`)).status, 200);
  const [[row]] = await pool.query(
    "SELECT expires_at FROM image_uploads WHERE id=?",
    [id],
  );
  assert.equal(row.expires_at, null);
  await cleanupUploads();
  const content = await fetch(base + `/api/uploads/${id}/content`, {
    headers: { authorization: "Bearer " + token },
  });
  assert.equal(content.status, 200);
  if (serverConfig.imageStorage === "r2")
    assert.ok(await remoteImageStore().get(imageObjectKey(id)));
  await pool.execute("UPDATE image_uploads SET total_bytes=? WHERE id=?", [
    100 * 1024 * 1024,
    id,
  ]);
  assert.equal(
    (
      await request("/api/uploads", {
        body: { size: image.length, checksum: "0".repeat(64) },
      })
    ).status,
    429,
  );
  await request(`/api/uploads/${id}`, { method: "DELETE" });
});

test("explicit existing-file updates keep start times, never revive expired files and clean newly expired resources", async () => {
  const route = "/api/admin/settings/storage";
  const headers = { ...browserHeaders, cookie: adminCookie };
  const active = crypto.randomUUID(),
    expired = crypto.randomUUID(),
    incomplete = crypto.randomUUID();
  const image = await sharp({
    create: { width: 8, height: 8, channels: 3, background: "#336644" },
  })
    .jpeg()
    .toBuffer();
  for (const [id, completed, deadline] of [
    [active, 1, "DATE_ADD(UTC_TIMESTAMP(), INTERVAL 1 DAY)"],
    [expired, 1, "DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)"],
    [incomplete, 0, "DATE_ADD(UTC_TIMESTAMP(), INTERVAL 1 DAY)"],
  ]) {
    await pool.query(
      `INSERT INTO image_uploads (id,user_id,total_bytes,chunk_count,checksum,completed,expires_at,retention_started_at) VALUES (?,?,?,1,?,?,${deadline},DATE_SUB(UTC_TIMESTAMP(),INTERVAL 10 DAY))`,
      [id, alice, image.length, "0".repeat(64), completed],
    );
    await fs.mkdir(uploadDirectory(id), { recursive: true });
    await fs.writeFile(path.join(uploadDirectory(id), "image.jpg"), image);
    if (completed) await remoteImageStore()?.put(imageObjectKey(id), image);
  }
  const current = await getRetentionPolicy();
  const [[pendingBefore]] = await pool.query(
    "SELECT expires_at FROM image_uploads WHERE id=?",
    [incomplete],
  );
  const permanent = await request(route, {
    method: "PUT",
    headers,
    body: {
      ...current,
      incompleteHours: 2,
      completedDays: null,
      applyToExisting: true,
    },
  });
  assert.equal(permanent.status, 200);
  const [[preserved]] = await pool.query(
    "SELECT expires_at,retention_started_at FROM image_uploads WHERE id=?",
    [active],
  );
  assert.equal(preserved.expires_at, null);
  const [[alreadyExpired]] = await pool.query(
    "SELECT expires_at<UTC_TIMESTAMP() AS expired FROM image_uploads WHERE id=?",
    [expired],
  );
  assert.equal(alreadyExpired.expired, 1);
  const [[shortPending]] = await pool.query(
    "SELECT expires_at<UTC_TIMESTAMP() AS expired FROM image_uploads WHERE id=?",
    [incomplete],
  );
  assert.equal(shortPending.expired, 1);
  const limited = await request(route, {
    method: "PUT",
    headers,
    body: { ...permanent.data.policy, completedDays: 3, applyToExisting: true },
  });
  assert.equal(limited.status, 200);
  const [[shortened]] = await pool.query(
    "SELECT expires_at<UTC_TIMESTAMP() AS expired,retention_started_at FROM image_uploads WHERE id=?",
    [active],
  );
  assert.equal(shortened.expired, 1);
  assert.equal(
    shortened.retention_started_at.getTime(),
    preserved.retention_started_at.getTime(),
  );
  await cleanupUploads();
  for (const id of [active, expired, incomplete]) {
    const [[count]] = await pool.query(
      "SELECT COUNT(*) AS count FROM image_uploads WHERE id=?",
      [id],
    );
    assert.equal(count.count, 0);
    await assert.rejects(fs.access(uploadDirectory(id)));
    if (serverConfig.imageStorage === "r2")
      assert.equal(await remoteImageStore().get(imageObjectKey(id)), null);
  }
  const [[audit]] = await pool.query(
    "SELECT COUNT(*) AS count FROM audit_events WHERE actor_id=? AND action LIKE 'Storage:%'",
    [admin],
  );
  assert.ok(audit.count >= 4);
  const reset = await request(route, {
    method: "PUT",
    headers,
    body: {
      ...limited.data.policy,
      incompleteHours: 24,
      completedDays: 30,
      applyToExisting: false,
    },
  });
  assert.equal(reset.status, 200);
});

test("AI success uses authenticated quota, opt-in and minimized upstream payloads", async () => {
  const [created] = await pool.execute(
    "INSERT INTO users (username,email,password_hash,role) VALUES ('ai-fixture','ai-fixture@example.test','unused','parent')",
  );
  const auth = await createSession(created.insertId, "app");
  const originalFetch = globalThis.fetch;
  const previousEnabled = serverConfig.aiEnabled;
  const previousKey = process.env.OPENAI_API_KEY;
  const upstream = [];
  serverConfig.aiEnabled = true;
  process.env.OPENAI_API_KEY = "test-fixture-never-sent";
  globalThis.fetch = async (url, options) => {
    if (String(url) === "https://api.openai.com/v1/responses") {
      const payload = JSON.parse(options.body);
      upstream.push(payload);
      return new Response(
        JSON.stringify({
          output_text: JSON.stringify({
            insights: [
              { title: "Notice", message: "Review the selected records." },
            ],
          }),
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    return originalFetch(url, options);
  };
  try {
    const result = await request("/api/health-insights", {
      auth,
      body: {
        aiConsent: true,
        childName: "Private Child",
        logs: [
          {
            title: "sleep",
            timestamp: new Date().toISOString(),
            value: "7 hours",
            comments: "Secret address and contact",
          },
        ],
      },
    });
    assert.equal(result.status, 200);
    assert.equal(upstream.length, 1);
    assert.equal(upstream[0].store, false);
    assert.ok(!JSON.stringify(upstream[0]).includes("Private Child"));
    assert.ok(!JSON.stringify(upstream[0]).includes("Secret address"));
    assert.equal(upstream[0].text.format.type, "json_object");
    const [usage] = await pool.execute(
      "SELECT used FROM ai_daily_usage WHERE user_id=? AND kind='insight'",
      [created.insertId],
    );
    assert.equal(usage[0].used, 1);
  } finally {
    globalThis.fetch = originalFetch;
    serverConfig.aiEnabled = previousEnabled;
    if (previousKey === undefined) delete process.env.OPENAI_API_KEY;
    else process.env.OPENAI_API_KEY = previousKey;
  }
});
