import {
  requireParent,
  createSession,
  revokeSession,
  bearerToken,
} from "../services/sessions.js";
import { rateLimit } from "../middleware/security.js";
import bcrypt from "bcryptjs";
import { pool } from "../db.js";
import { Router } from "../http/router.js";
import {
  activeBlockMessage,
  blockFieldsSQL,
  serializeUser,
} from "../utils/users.js";

export function createAppAuthRoutes() {
  const router = new Router();

  router.post("/api/app-session", requireParent, async (ctx) => {
    const userId = ctx.state.appUser.id;

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please log in again." };
      return;
    }

    try {
      const [rows] = await pool.execute(
        `SELECT
          id,
          username,
          email,
          role,
          profile_image,
          ${blockFieldsSQL()}
          blocked_indefinitely,
          DATE_FORMAT(blocked_until, '%Y-%m-%d %H:%i') AS blocked_until
         FROM users
         WHERE id = ?
         LIMIT 1`,
        [userId],
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 404;
        ctx.body = { message: "Please log in again." };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        message: "Session is active.",
        user: serializeUser(user),
      };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not check this account right now." };
    }
  });

  router.post(
    "/api/login",
    rateLimit({ name: "login", max: 10, windowMs: 900000 }),
    async (ctx) => {
      const { username, password } = ctx.request.body || {};

      if (
        typeof username !== "string" ||
        typeof password !== "string" ||
        !username.trim() ||
        !password
      ) {
        ctx.status = 400;
        ctx.body = { message: "Please enter your nickname and password." };
        return;
      }

      try {
        const [rows] = await pool.execute(
          `SELECT
          id,
          username,
          email,
          password_hash,
          role,
          profile_image,
          ${blockFieldsSQL()}
          blocked_indefinitely,
          DATE_FORMAT(blocked_until, '%Y-%m-%d %H:%i') AS blocked_until
         FROM users
         WHERE username = ? OR LOWER(email) = LOWER(?)
         ORDER BY LOWER(email) = LOWER(?) DESC
         LIMIT 1`,
          [username.trim(), username.trim(), username.trim()],
        );

        const user = rows[0];
        if (!user) {
          ctx.status = 401;
          ctx.body = { message: "Invalid email, username, or password." };
          return;
        }

        const validPassword = await bcrypt.compare(
          password,
          user.password_hash,
        );
        if (!validPassword) {
          ctx.status = 401;
          ctx.body = { message: "Invalid email, username, or password." };
          return;
        }

        if (Number(user.isBlocked) === 1) {
          ctx.status = 403;
          ctx.body = { message: activeBlockMessage(user) };
          return;
        }

        if (user.role !== "parent") {
          ctx.throw(403, "Parent access is required.");
        }
        ctx.body = {
          message: "Logged in successfully.",
          user: serializeUser(user),
          token: await createSession(user.id, "app", user.password_hash),
        };
      } catch (error) {
        console.error("Request failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = { message: "Could not log in right now." };
      }
    },
  );

  router.post("/api/app-logout", requireParent, async (ctx) => {
    await revokeSession(bearerToken(ctx));
    ctx.body = { message: "Logged out successfully." };
  });

  return router;
}
