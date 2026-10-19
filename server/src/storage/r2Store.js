import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
} from "@aws-sdk/client-s3";

// Only sanitized, completed images enter R2. Chunks remain private local staging.
export function createR2Store(settings) {
  const client = new S3Client({
    endpoint: settings.endpoint,
    region: "auto",
    credentials: {
      accessKeyId: settings.accessKeyId,
      secretAccessKey: settings.secretAccessKey,
    },
    forcePathStyle: true,
    maxAttempts: 3,
    requestHandler: { connectionTimeout: 5000, requestTimeout: 15000 },
    requestChecksumCalculation: "WHEN_REQUIRED",
    responseChecksumValidation: "WHEN_REQUIRED",
  });
  async function send(Command, input) {
    try {
      return await client.send(
        new Command({ Bucket: settings.bucket, ...input }),
      );
    } catch (error) {
      if (
        error.name === "NoSuchKey" &&
        [GetObjectCommand, DeleteObjectCommand].includes(Command)
      )
        return null;
      // Never expose signed requests, credentials or upstream response bodies.
      const unavailable = new Error(
        "Image storage is temporarily unavailable. Please retry.",
      );
      unavailable.name = "ImageStorageUnavailable";
      unavailable.status = 503;
      throw unavailable;
    }
  }
  return {
    async put(key, bytes) {
      await send(PutObjectCommand, {
        Key: key,
        Body: bytes,
        ContentType: "image/jpeg",
        CacheControl: "private, no-store",
      });
    },
    async get(key) {
      const result = await send(GetObjectCommand, { Key: key });
      if (!result) return null;
      try {
        return Buffer.from(await result.Body.transformToByteArray());
      } catch {
        const error = new Error(
          "Image storage is temporarily unavailable. Please retry.",
        );
        error.name = "ImageStorageUnavailable";
        error.status = 503;
        throw error;
      }
    },
    async remove(key) {
      await send(DeleteObjectCommand, { Key: key });
    },
    async *keys(prefix) {
      let token;
      do {
        const result = await send(ListObjectsV2Command, {
          Prefix: prefix,
          ContinuationToken: token,
          MaxKeys: 1000,
        });
        for (const object of result.Contents || []) yield object.Key;
        token = result.IsTruncated ? result.NextContinuationToken : undefined;
        if (result.IsTruncated && !token)
          throw new Error("Invalid storage listing.");
      } while (token);
    },
    close: () => client.destroy(),
  };
}
