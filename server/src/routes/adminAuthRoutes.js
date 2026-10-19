import { rateLimit } from "../middleware/security.js";
import bcrypt from "bcryptjs";
import { pool } from "../db.js";
import { Router } from "../http/router.js";
import {
  clearAdminSessionCookie,
  createAdminSession,
  deleteAdminSessionFromRequest,
  requireAdmin,
  setAdminSessionCookie,
} from "../services/adminSession.js";
import { publicUser } from "../utils/users.js";

export function createAdminAuthRoutes() {
  const router = new Router();

  router.post(
    "/api/admin/login",
    rateLimit({ name: "admin-login", max: 10, windowMs: 900000 }),
    async (ctx) => {
      const { username, password } = ctx.request.body || {};

      if (
        typeof username !== "string" ||
        typeof password !== "string" ||
        !username.trim() ||
        !password
      ) {
        ctx.status = 400;
        ctx.body = { message: "Please enter an admin username and password." };
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
          blocked_indefinitely,
          DATE_FORMAT(blocked_until, '%Y-%m-%d %H:%i') AS blockedUntil,
          CASE
            WHEN blocked_indefinitely = 1
              OR (blocked_until IS NOT NULL AND blocked_until > NOW())
            THEN 1
            ELSE 0
          END AS isBlocked
         FROM users
         WHERE username = ?`,
          [username.trim()],
        );

        const user = rows[0];
        if (!user) {
          ctx.status = 401;
          ctx.body = { message: "Invalid admin username or password." };
          return;
        }

        const validPassword = await bcrypt.compare(
          password,
          user.password_hash,
        );
        if (!validPassword) {
          ctx.status = 401;
          ctx.body = { message: "Invalid admin username or password." };
          return;
        }

        if (user.role !== "admin") {
          ctx.status = 403;
          ctx.body = {
            message: "Only admin accounts can access this website.",
          };
          return;
        }

        if (Number(user.isBlocked)) {
          ctx.throw(403, "This account is blocked.");
        }
        await deleteAdminSessionFromRequest(ctx);
        const token = await createAdminSession(user.id, user.password_hash);
        setAdminSessionCookie(ctx, token);

        ctx.body = {
          message: "Admin logged in successfully.",
          user: publicUser(user),
        };
      } catch (error) {
        console.error("Request failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = { message: "Could not log in right now." };
      }
    },
  );

  router.get("/api/admin/session", requireAdmin, (ctx) => {
    ctx.body = { user: ctx.state.adminUser };
  });

  router.post("/api/admin/logout", async (ctx) => {
    await deleteAdminSessionFromRequest(ctx);
    clearAdminSessionCookie(ctx);
    ctx.body = { message: "Logged out successfully." };
  });

  return router;
}
