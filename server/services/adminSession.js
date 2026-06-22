import crypto from 'crypto';
import { pool } from '../db.js';
import { parseStoredJSON, publicUser } from '../utils/users.js';
import { ensureDatabaseShapeReady } from './databaseShape.js';

export const adminSessionCookieName = 'care_portal_admin_session';
const adminSessionMaxAgeMs = 12 * 60 * 60 * 1000;
const adminSessions = new Map();

export function parseCookies(cookieHeader = '') {
  return cookieHeader
    .split(';')
    .map((cookie) => cookie.trim())
    .filter(Boolean)
    .reduce((cookies, cookie) => {
      const separatorIndex = cookie.indexOf('=');
      if (separatorIndex === -1) return cookies;

      const name = decodeURIComponent(cookie.slice(0, separatorIndex));
      const value = decodeURIComponent(cookie.slice(separatorIndex + 1));
      cookies[name] = value;
      return cookies;
    }, {});
}

export function setAdminSessionCookie(ctx, token) {
  ctx.set(
    'Set-Cookie',
    [
      `${adminSessionCookieName}=${encodeURIComponent(token)}`,
      'Path=/',
      'HttpOnly',
      'SameSite=Lax',
      `Max-Age=${adminSessionMaxAgeMs / 1000}`
    ].join('; ')
  );
}

export function clearAdminSessionCookie(ctx) {
  ctx.set(
    'Set-Cookie',
    `${adminSessionCookieName}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`
  );
}

export function createAdminSession(userId) {
  const token = crypto.randomUUID();
  adminSessions.set(token, {
    userId,
    createdAt: Date.now()
  });
  return token;
}

export function deleteAdminSessionFromRequest(ctx) {
  const cookies = parseCookies(ctx.get('cookie') || '');
  const token = cookies[adminSessionCookieName];
  if (token) {
    adminSessions.delete(token);
  }
}

function isExpiredAdminSession(session) {
  return !session || Date.now() - session.createdAt > adminSessionMaxAgeMs;
}

export function cleanupExpiredAdminSessions() {
  const now = Date.now();

  for (const [token, session] of adminSessions.entries()) {
    if (!session || now - session.createdAt > adminSessionMaxAgeMs) {
      adminSessions.delete(token);
    }
  }
}

export async function getAdminUser(ctx) {
  const cookies = parseCookies(ctx.get('cookie') || '');
  const token = cookies[adminSessionCookieName];
  const session = token ? adminSessions.get(token) : null;

  if (!token || !session) {
    return null;
  }

  if (isExpiredAdminSession(session)) {
    adminSessions.delete(token);
    return null;
  }

  const [rows] = await pool.execute(
    'SELECT id, username, email, role, profile_image FROM users WHERE id = ? LIMIT 1',
    [session.userId]
  );

  const user = rows[0];
  if (!user || user.role !== 'admin') {
    adminSessions.delete(token);
    return null;
  }

  return publicUser(user);
}

export async function requireAdmin(ctx, next) {
  try {
    await ensureDatabaseShapeReady();
    const adminUser = await getAdminUser(ctx);

    if (!adminUser) {
      ctx.status = 401;
      ctx.body = { message: 'Admin access is required.' };
      return;
    }

    ctx.state.adminUser = adminUser;
    return next();
  } catch (error) {
    console.error(error);
    ctx.status = 500;
    ctx.body = { message: 'Could not verify admin access right now.' };
  }
}

export { parseStoredJSON };
