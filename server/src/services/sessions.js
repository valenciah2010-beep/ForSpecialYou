import crypto from "node:crypto";
import { pool } from "../db.js";
import { activeBlockMessage } from "../utils/users.js";
export const hashToken = (token) =>
  crypto.createHash("sha256").update(token).digest("hex");
export async function createSession(userId, kind, expectedPasswordHash) {
  const token = crypto.randomBytes(32).toString("hex");
  const hours = kind === "admin" ? 12 : 24 * 30;
  if (expectedPasswordHash) {
    // A concurrent password reset must not issue a session for the old password.
    const [result] = await pool.execute(
      "INSERT INTO auth_sessions (token_hash,user_id,kind,expires_at) SELECT ?,id,?,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? HOUR) FROM users WHERE id=? AND password_hash=?",
      [hashToken(token), kind, hours, userId, expectedPasswordHash],
    );
    if (result.affectedRows !== 1) {
      const error = new Error("Credentials changed. Please log in again.");
      error.status = 401;
      throw error;
    }
  } else {
    await pool.execute(
      "INSERT INTO auth_sessions (token_hash,user_id,kind,expires_at) VALUES (?,?,?,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? HOUR))",
      [hashToken(token), userId, kind, hours],
    );
  }
  return token;
}
export async function revokeSession(token) {
  if (token)
    await pool.execute("DELETE FROM auth_sessions WHERE token_hash = ?", [
      hashToken(token),
    ]);
}
export async function sessionUser(token, kind) {
  if (!/^[a-f0-9]{64}$/.test(token || "")) return null;
  const [rows] = await pool.execute(
    `SELECT u.*, CASE WHEN u.blocked_indefinitely = 1 OR u.blocked_until > NOW() THEN 1 ELSE 0 END AS isBlocked
 FROM auth_sessions s JOIN users u ON u.id=s.user_id
 WHERE s.token_hash=? AND s.kind=? AND s.expires_at > UTC_TIMESTAMP() LIMIT 1`,
    [hashToken(token), kind],
  );
  const user = rows[0];
  if (!user || user.role !== (kind === "admin" ? "admin" : "parent"))
    return null;
  return user;
}
export const bearerToken = (ctx) =>
  /^Bearer ([a-f0-9]{64})$/.exec(ctx.get("authorization"))?.[1];
export async function requireParent(ctx, next) {
  const user = await sessionUser(bearerToken(ctx), "app");
  if (!user) {
    ctx.status = 401;
    ctx.body = { message: "Please log in again." };
    return;
  }
  if (Number(user.isBlocked)) {
    ctx.status = 403;
    ctx.body = { message: activeBlockMessage(user) };
    return;
  }
  if (
    ctx.request.body?.userId != null &&
    Number(ctx.request.body.userId) !== user.id
  ) {
    ctx.status = 403;
    ctx.body = { message: "Account access denied." };
    return;
  }
  ctx.state.appUser = user;
  return next();
}
export async function cleanupSessions() {
  await pool.execute(
    "DELETE FROM auth_sessions WHERE expires_at <= UTC_TIMESTAMP()",
  );
  await pool.execute(
    "DELETE FROM api_rate_limits WHERE expires_at <= UTC_TIMESTAMP()",
  );
}
