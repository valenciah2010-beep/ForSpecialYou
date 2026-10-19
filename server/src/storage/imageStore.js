import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { serverConfig } from "../config.js";
import { createR2Store } from "./r2Store.js";

export const uploadDirectory = (id) => {
  if (!/^[a-f0-9-]{36}$/.test(id || "")) throw new Error("Invalid upload ID.");
  return path.join(serverConfig.uploadPath, id);
};
export const imageObjectKey = (id) => {
  uploadDirectory(id);
  return `${serverConfig.r2.prefix}${id}/image.jpg`;
};
let remote;
export const remoteImageStore = () => {
  if (serverConfig.imageStorage !== "r2") return null;
  return (remote ||= createR2Store(serverConfig.r2));
};
export async function writeImage(id, bytes) {
  // Upload first: failure must keep the upload resumable, never mark it complete.
  await remoteImageStore()?.put(imageObjectKey(id), bytes);
  // A local copy preserves existing uploads and permits code/config rollback.
  await fs.mkdir(uploadDirectory(id), { recursive: true, mode: 0o700 });
  const filename = path.join(uploadDirectory(id), "image.jpg");
  const temporary = `${filename}.${crypto.randomUUID()}`;
  try {
    await fs.writeFile(temporary, bytes, { mode: 0o600 });
    await fs.rename(temporary, filename);
  } finally {
    await fs.rm(temporary, { force: true });
  }
}
export async function readImage(id) {
  const bytes = await remoteImageStore()?.get(imageObjectKey(id));
  if (bytes) return bytes;
  // Only a missing object may fall back to a legacy local file; outages fail closed.
  try {
    return await fs.readFile(path.join(uploadDirectory(id), "image.jpg"));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    const missing = new Error("Image was not found.");
    missing.status = 404;
    throw missing;
  }
}
export async function removeImage(id) {
  await remoteImageStore()?.remove(imageObjectKey(id));
  await fs.rm(uploadDirectory(id), { recursive: true, force: true });
}
