import { serverConfig } from "../config.js";
import { publicUser, parseStoredJSON } from "../utils/users.js";
import {
  createSession,
  revokeSession,
  sessionUser,
  cleanupSessions,
} from "./sessions.js";
export const adminSessionCookieName = "care_portal_admin_session";
export function parseCookies(header = "") {
  return header.split(";").reduce((out, part) => {
    const index = part.indexOf("=");
    if (index < 0) return out;
    try {
      out[decodeURIComponent(part.slice(0, index).trim())] = decodeURIComponent(
        part.slice(index + 1),
      );
    } catch {
      /* Ignore malformed cookies. */
    }
    return out;
  }, Object.create(null));
}
const requestToken = (ctx) =>
  parseCookies(ctx.get("cookie"))[adminSessionCookieName];
export function setAdminSessionCookie(ctx, token) {
  ctx.set(
    "Set-Cookie",
    `${adminSessionCookieName}=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200${serverConfig.cookieSecure ? "; Secure" : ""}`,
  );
}
export function clearAdminSessionCookie(ctx) {
  ctx.set(
    "Set-Cookie",
    `${adminSessionCookieName}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0${serverConfig.cookieSecure ? "; Secure" : ""}`,
  );
}
export const createAdminSession = (id, expectedPasswordHash) =>
  createSession(id, "admin", expectedPasswordHash);
export const deleteAdminSessionFromRequest = (ctx) =>
  revokeSession(requestToken(ctx));
export const cleanupExpiredAdminSessions = cleanupSessions;
export async function getAdminUser(ctx) {
  const user = await sessionUser(requestToken(ctx), "admin");
  return user && !Number(user.isBlocked) ? publicUser(user) : null;
}
export async function requireAdmin(ctx, next) {
  const user = await getAdminUser(ctx);
  if (!user) {
    ctx.status = 401;
    ctx.body = { message: "Admin access is required." };
    return;
  }
  ctx.state.adminUser = user;
  return next();
}
export { parseStoredJSON };
