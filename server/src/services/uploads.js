import fs from "node:fs/promises";
import { pool } from "../db.js";
import { serverConfig } from "../config.js";
import { ACTIVE_UPLOAD_SQL } from "./storageRetention.js";
import {
  uploadDirectory,
  readImage,
  removeImage,
  remoteImageStore,
} from "../storage/imageStore.js";
export { uploadDirectory } from "../storage/imageStore.js";
export const CHUNK_BYTES = 512 * 1024;
export async function findUpload(id, userId) {
  if (!/^[a-f0-9-]{36}$/.test(id || "")) return null;
  const [rows] = await pool.execute(
    `SELECT * FROM image_uploads WHERE id=? AND user_id=? AND ${ACTIVE_UPLOAD_SQL}`,
    [id, userId],
  );
  return rows[0] || null;
}
export async function uploadedImage(id, userId) {
  const upload = await findUpload(id, userId);
  if (!upload?.completed) {
    const error = new Error("Image was not found.");
    error.status = 404;
    throw error;
  }
  return readImage(id);
}
export async function cleanupUploads() {
  const remote = remoteImageStore();
  if (remote) {
    // Prefix-scoped sweep also removes objects orphaned by user FK cascade deletion.
    for await (const key of remote.keys(serverConfig.r2.prefix)) {
      const suffix = key.slice(serverConfig.r2.prefix.length);
      const match = /^([a-f0-9-]{36})\/image\.jpg$/.exec(suffix);
      if (!match) continue;
      const [rows] = await pool.execute(
        `SELECT id FROM image_uploads WHERE id=? AND ${ACTIVE_UPLOAD_SQL}`,
        [match[1]],
      );
      if (!rows[0]) await remote.remove(key);
    }
  }
  // DB deletion of a user must not leave private files indefinitely on disk.
  await fs.mkdir(serverConfig.uploadPath, { recursive: true, mode: 0o700 });
  for (const name of await fs.readdir(serverConfig.uploadPath)) {
    if (!/^[a-f0-9-]{36}$/.test(name)) continue;
    const [rows] = await pool.execute(
      `SELECT id FROM image_uploads WHERE id=? AND ${ACTIVE_UPLOAD_SQL}`,
      [name],
    );
    if (!rows[0]) await removeImage(name);
  }
  await pool.execute(
    "DELETE FROM image_uploads WHERE expires_at<=UTC_TIMESTAMP()",
  );
}
