import crypto from "node:crypto";
import { serverConfig } from "../config.js";
import { pool } from "../db.js";
export async function errorHandler(ctx, next) {
  ctx.set("X-Content-Type-Options", "nosniff");
  ctx.set("X-Frame-Options", "DENY");
  ctx.set("Referrer-Policy", "same-origin");
  if (ctx.path.startsWith("/api/")) ctx.set("Cache-Control", "no-store");
  try {
    await next();
  } catch (error) {
    ctx.status = error.status >= 400 && error.status < 600 ? error.status : 500;
    ctx.body = {
      message:
        ctx.status >= 500
          ? "The server could not complete this request."
          : error.message,
    };
    if (ctx.status >= 500)
      console.error(
        "Request failed:",
        ctx.method,
        ctx.path,
        error.code || error.name,
      );
  }
}
export async function csrfProtection(ctx, next) {
  if (
    ["POST", "PUT", "PATCH", "DELETE"].includes(ctx.method) &&
    (ctx.get("cookie").includes("care_portal_admin_session=") ||
      ctx.path.startsWith("/api/admin/"))
  ) {
    const origin = ctx.get("origin");
    const trusted = new Set([
      serverConfig.publicOrigin,
      ...serverConfig.corsOrigins,
    ]);
    if (!trusted.has(origin) || ctx.get("x-requested-with") !== "CarePortal") {
      ctx.status = 403;
      ctx.body = { message: "Request origin was not verified." };
      return;
    }
  }
  return next();
}
export function rateLimit({ name, max, windowMs = 60000 }) {
  return async (ctx, next) => {
    const identity = ctx.state.appUser?.id || ctx.state.adminUser?.id || ctx.ip;
    const bucket = crypto
      .createHash("sha256")
      .update(`${name}:${identity}`)
      .digest("hex");
    const start = Math.floor(Date.now() / windowMs) * windowMs;
    await pool.execute(
      `INSERT INTO api_rate_limits (bucket,window_start,hits,expires_at) VALUES (?,?,1,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? SECOND))
   ON DUPLICATE KEY UPDATE hits=IF(window_start=VALUES(window_start),hits+1,1), window_start=VALUES(window_start), expires_at=VALUES(expires_at)`,
      [bucket, start, Math.ceil(windowMs / 1000)],
    );
    const [rows] = await pool.execute(
      "SELECT hits FROM api_rate_limits WHERE bucket=?",
      [bucket],
    );
    if (rows[0].hits > max) {
      ctx.status = 429;
      ctx.set("Retry-After", String(Math.ceil(windowMs / 1000)));
      ctx.body = { message: "Too many requests. Please try again later." };
      return;
    }
    return next();
  };
}
