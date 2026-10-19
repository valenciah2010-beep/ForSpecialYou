import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { Router } from "../http/router.js";
import { pool } from "../db.js";
import { requireParent } from "../services/sessions.js";
import { getAdminUser } from "../services/adminSession.js";
import { rateLimit } from "../middleware/security.js";
import { writeImage, readImage, removeImage } from "../storage/imageStore.js";
import {
  ACTIVE_UPLOAD_SQL,
  getRetentionPolicy,
  completeUploadRetention,
} from "../services/storageRetention.js";
import {
  sanitizeImage,
  decodeBase64,
  MAX_IMAGE_BYTES,
} from "../services/images.js";
import {
  findUpload,
  uploadDirectory,
  CHUNK_BYTES,
} from "../services/uploads.js";
async function requireUploadUser(ctx, next) {
  const admin = await getAdminUser(ctx);
  if (admin) {
    ctx.state.adminUser = admin;
    ctx.state.uploadUserId = admin.id;
    return next();
  }
  return requireParent(ctx, () => {
    ctx.state.uploadUserId = ctx.state.appUser.id;
    return next();
  });
}
export function createUploadRoutes() {
  const router = new Router();
  router.post(
    "/api/uploads",
    requireUploadUser,
    rateLimit({ name: "uploads", max: 20 }),
    async (ctx) => {
      const { size, checksum } = ctx.request.body || {};
      if (
        !Number.isInteger(size) ||
        size < 1 ||
        size > MAX_IMAGE_BYTES ||
        !/^[a-f0-9]{64}$/.test(checksum || "")
      )
        ctx.throw(400, "Invalid upload size or checksum.");
      const connection = await pool.getConnection();
      const id = crypto.randomUUID();
      try {
        await connection.beginTransaction();
        const policy = await getRetentionPolicy(connection, true);
        await connection.execute("SELECT id FROM users WHERE id=? FOR UPDATE", [
          ctx.state.uploadUserId,
        ]);
        const [[usage]] = await connection.execute(
          `SELECT COUNT(*) AS count,COALESCE(SUM(total_bytes),0) AS bytes FROM image_uploads WHERE user_id=? AND ${ACTIVE_UPLOAD_SQL}`,
          [ctx.state.uploadUserId],
        );
        if (
          usage.count >= 100 ||
          Number(usage.bytes) + size > 100 * 1024 * 1024
        )
          ctx.throw(429, "Image storage limit reached.");
        await connection.execute(
          "INSERT INTO image_uploads (id,user_id,total_bytes,chunk_count,checksum,expires_at,retention_started_at) VALUES (?,?,?,?,?,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? HOUR),UTC_TIMESTAMP())",
          [
            id,
            ctx.state.uploadUserId,
            size,
            Math.ceil(size / CHUNK_BYTES),
            checksum,
            policy.incompleteHours,
          ],
        );
        await connection.commit();
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
      await fs.mkdir(uploadDirectory(id), { recursive: true, mode: 0o700 });
      ctx.status = 201;
      ctx.body = { id, chunkBytes: CHUNK_BYTES };
    },
  );
  router.get("/api/uploads/:id", requireUploadUser, async (ctx) => {
    const upload = await findUpload(ctx.params.id, ctx.state.uploadUserId);
    if (!upload) ctx.throw(404, "Upload was not found.");
    const files = await fs.readdir(uploadDirectory(upload.id)).catch(() => []);
    ctx.body = {
      id: upload.id,
      completed: Boolean(upload.completed),
      chunks: files
        .filter((f) => /^\d+\.part$/.test(f))
        .map((f) => Number(f.split(".")[0])),
    };
  });
  router.put(
    "/api/uploads/:id/chunks/:index",
    requireUploadUser,
    async (ctx) => {
      const upload = await findUpload(ctx.params.id, ctx.state.uploadUserId);
      if (!upload || upload.completed) ctx.throw(404, "Upload was not found.");
      const index = Number(ctx.params.index);
      if (!Number.isInteger(index) || index < 0 || index >= upload.chunk_count)
        ctx.throw(400, "Invalid chunk index.");
      const encoded = ctx.request.body?.data;
      if (
        typeof encoded !== "string" ||
        encoded.length > CHUNK_BYTES * 1.34 + 4
      )
        ctx.throw(413, "Chunk is too large.");
      const bytes = decodeBase64(encoded);
      const expected =
        index === upload.chunk_count - 1
          ? upload.total_bytes - index * CHUNK_BYTES
          : CHUNK_BYTES;
      if (bytes.length !== expected)
        ctx.throw(400, "Chunk size does not match.");
      const filename = path.join(uploadDirectory(upload.id), `${index}.part`);
      const temp = filename + "." + crypto.randomUUID();
      await fs.writeFile(temp, bytes, { mode: 0o600 });
      await fs.rename(temp, filename);
      ctx.body = { index };
    },
  );
  router.post("/api/uploads/:id/complete", requireUploadUser, async (ctx) => {
    const upload = await findUpload(ctx.params.id, ctx.state.uploadUserId);
    if (!upload) ctx.throw(404, "Upload was not found.");
    if (!upload.completed) {
      const chunks = [];
      for (let index = 0; index < upload.chunk_count; index++) {
        try {
          chunks.push(
            await fs.readFile(
              path.join(uploadDirectory(upload.id), `${index}.part`),
            ),
          );
        } catch {
          ctx.throw(409, "Some chunks are missing. Resume the upload.");
        }
      }
      const bytes = Buffer.concat(chunks);
      if (
        bytes.length !== upload.total_bytes ||
        crypto.createHash("sha256").update(bytes).digest("hex") !==
          upload.checksum
      )
        ctx.throw(400, "Image checksum does not match.");
      const sanitized = await sanitizeImage(bytes);
      await writeImage(upload.id, sanitized);
      await completeUploadRetention(upload.id, ctx.state.uploadUserId);
      // Keep chunks until expiry so retries/concurrent completion remain safe.
    }
    ctx.body = { id: upload.id, url: `/api/uploads/${upload.id}/content` };
  });
  router.get("/api/uploads/:id/content", requireUploadUser, async (ctx) => {
    const upload = await findUpload(ctx.params.id, ctx.state.uploadUserId);
    if (!upload?.completed) ctx.throw(404, "Image was not found.");
    ctx.type = "image/jpeg";
    ctx.body = await readImage(upload.id);
  });
  router.delete("/api/uploads/:id", requireUploadUser, async (ctx) => {
    const upload = await findUpload(ctx.params.id, ctx.state.uploadUserId);
    if (!upload) ctx.throw(404, "Upload was not found.");
    // Keep metadata for retry if remote deletion fails.
    await removeImage(upload.id);
    await pool.execute("DELETE FROM image_uploads WHERE id=?", [upload.id]);
    ctx.status = 204;
  });
  return router;
}
