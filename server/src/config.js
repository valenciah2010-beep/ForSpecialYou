import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";
const dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(dirname, "../.env") });
const list = (value) =>
  String(value)
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
export const serverConfig = {
  port: Number(process.env.PORT || 4223),
  host: process.env.HOST || "127.0.0.1",
  publicOrigin: process.env.PUBLIC_ORIGIN || "http://localhost:5223",
  corsOrigins: list(
    process.env.CORS_ORIGINS ||
      "https://fsyadmin.top,http://localhost:5223,http://127.0.0.1:5223",
  ),
  cookieSecure: process.env.COOKIE_SECURE === "true",
  adminSitePath: path.resolve(
    process.env.ADMIN_SITE_PATH ||
      path.resolve(dirname, "../../admin-web/dist"),
  ),
  uploadPath: path.resolve(
    process.env.UPLOAD_DIR || path.resolve(dirname, "../storage"),
  ),
  imageStorage: process.env.IMAGE_STORAGE || "local",
  r2: {
    endpoint: process.env.R2_ENDPOINT || "",
    bucket: process.env.R2_BUCKET || "",
    accessKeyId: process.env.R2_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || "",
    prefix: process.env.R2_PREFIX || "forspecialyou/uploads/",
  },
  trustProxy: process.env.TRUST_PROXY === "true",
  openAIModel: process.env.OPENAI_MODEL || "gpt-4.1-mini",
  aiEnabled: process.env.AI_PROCESSING_ENABLED === "true",
  aiTimeoutMs: 45000,
  aiConcurrency: 2,
  insightDailyLimit: 20,
  reportDailyLimit: 10,
};
export function validateEnvironment() {
  const missing = ["DB_HOST", "DB_USER", "DB_PASSWORD", "DB_NAME"].filter(
    (key) => !process.env[key],
  );
  if (missing.length)
    throw new Error(
      `Missing environment variables: ${missing.join(", ")}. Configure server/.env.`,
    );
  if (
    !Number.isInteger(serverConfig.port) ||
    serverConfig.port < 1 ||
    serverConfig.port > 65535
  )
    throw new Error("Invalid PORT.");
  if (process.env.NODE_ENV === "production" && !serverConfig.cookieSecure)
    throw new Error("Production requires COOKIE_SECURE=true.");
  if (!["local", "r2"].includes(serverConfig.imageStorage))
    throw new Error("IMAGE_STORAGE must be local or r2.");
  if (serverConfig.imageStorage === "r2") {
    const settings = serverConfig.r2;
    if (!settings.bucket || !settings.accessKeyId || !settings.secretAccessKey)
      throw new Error("R2 bucket and S3 credentials are required.");
    const endpoint = new URL(settings.endpoint);
    const testEndpoint =
      process.env.NODE_ENV === "test" &&
      endpoint.protocol === "http:" &&
      endpoint.hostname === "127.0.0.1";
    if (
      (!testEndpoint &&
        (endpoint.protocol !== "https:" ||
          !/^[a-f0-9]{32}\.r2\.cloudflarestorage\.com$/.test(
            endpoint.hostname,
          ))) ||
      endpoint.username ||
      endpoint.password ||
      endpoint.search ||
      endpoint.hash ||
      !["", "/"].includes(endpoint.pathname)
    )
      throw new Error(
        "R2_ENDPOINT must be the account S3 endpoint without a bucket path.",
      );
    if (
      !/^[a-zA-Z0-9][a-zA-Z0-9/_-]*\/$/.test(settings.prefix) ||
      settings.prefix.includes("//")
    )
      throw new Error(
        "R2_PREFIX must be an application-specific directory prefix.",
      );
  }
}
