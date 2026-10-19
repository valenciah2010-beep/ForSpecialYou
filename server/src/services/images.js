import sharp from "sharp";
export const MAX_IMAGE_BYTES = 20 * 1024 * 1024;
export async function sanitizeImage(bytes) {
  if (
    !Buffer.isBuffer(bytes) ||
    !bytes.length ||
    bytes.length > MAX_IMAGE_BYTES
  ) {
    const error = new Error("Image is too large or empty.");
    error.status = 413;
    throw error;
  }
  try {
    const image = sharp(bytes, {
      limitInputPixels: 24_000_000,
      animated: false,
      failOn: "warning",
    });
    const metadata = await image.metadata();
    if (
      !["jpeg", "png", "webp", "heif"].includes(metadata.format) ||
      metadata.pages > 1
    )
      throw new Error("Unsupported image.");
    // Re-encoding strips EXIF/GPS and untrusted embedded content.
    return await image
      .rotate()
      .resize({
        width: 2048,
        height: 2048,
        fit: "inside",
        withoutEnlargement: true,
      })
      .jpeg({ quality: 85 })
      .toBuffer();
  } catch {
    const error = new Error("Upload a valid JPEG, PNG, WebP or HEIC photo.");
    error.status = 400;
    throw error;
  }
}
export function decodeBase64(value) {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(value) ||
    value.length % 4 !== 0
  ) {
    const error = new Error("Invalid image encoding.");
    error.status = 400;
    throw error;
  }
  return Buffer.from(value, "base64");
}
export async function validateImageData(value) {
  if (typeof value !== "string") {
    const error = new Error("Invalid image.");
    error.status = 400;
    throw error;
  }
  const raw = value.replace(
    /^data:image\/(?:jpeg|jpg|png|webp|heic);base64,/,
    "",
  );
  if (raw.length > Math.ceil((MAX_IMAGE_BYTES * 4) / 3)) {
    const error = new Error("Image is too large.");
    error.status = 413;
    throw error;
  }
  return (
    "data:image/jpeg;base64," +
    (await sanitizeImage(decodeBase64(raw))).toString("base64")
  );
}
