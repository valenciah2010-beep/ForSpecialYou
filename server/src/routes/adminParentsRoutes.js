import { mealUsage } from "../services/aiQuota.js";
import { pool } from "../db.js";
import { Router } from "../http/router.js";
import { requireAdmin } from "../services/adminSession.js";
import { normalizeNutrientDailyLimit } from "../utils/validators.js";
import { blockFieldsSQL, parseStoredJSON } from "../utils/users.js";

export function createAdminParentsRoutes() {
  const router = new Router();

  router.get("/api/admin/app-users", requireAdmin, async (ctx) => {
    try {
      const [rows] = await pool.execute(
        `SELECT
          id,
          username AS nickname,
          email,
          role,
          profile_image AS profileImage,
          ${blockFieldsSQL()}
          DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS createdAt
        FROM users
        WHERE role = 'parent'
        ORDER BY created_at DESC`,
      );

      ctx.body = { users: rows };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not load simulator app users right now." };
    }
  });

  router.get("/api/admin/app-users/:id/details", requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    try {
      const [rows] = await pool.execute(
        `SELECT
          users.id,
          users.username AS nickname,
          users.email,
          users.role,
          users.profile_image AS profileImage,
          ${blockFieldsSQL("users")}
          DATE_FORMAT(users.created_at, '%Y-%m-%d %H:%i') AS createdAt,
          parent_app_data.child_profile AS childProfile,
          parent_app_data.health_logs AS healthLogs,
          parent_app_data.saved_meals AS savedMeals,
          parent_app_data.nutrient_daily_usage AS nutrientDailyUsage,
          COALESCE(parent_app_data.nutrient_daily_limit, 3) AS nutrientDailyLimit,
          DATE_FORMAT(parent_app_data.updated_at, '%Y-%m-%d %H:%i') AS appDataUpdatedAt
        FROM users
        LEFT JOIN parent_app_data ON parent_app_data.user_id = users.id
        WHERE users.id = ? AND users.role = 'parent'
        LIMIT 1`,
        [userId],
      );

      const row = rows[0];
      if (!row) {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      ctx.body = {
        user: {
          id: row.id,
          nickname: row.nickname,
          email: row.email,
          role: row.role,
          profileImage: row.profileImage,
          blockedIndefinitely: Boolean(row.blockedIndefinitely),
          blockedUntil: row.blockedUntil,
          isBlocked: Boolean(row.isBlocked),
          createdAt: row.createdAt,
        },
        childProfile: parseStoredJSON(row.childProfile, {}),
        healthLogs: parseStoredJSON(row.healthLogs, []),
        savedMeals: parseStoredJSON(row.savedMeals, []),
        nutrientDailyUsage: await mealUsage(userId),
        nutrientDailyLimit: normalizeNutrientDailyLimit(row.nutrientDailyLimit),
        appDataUpdatedAt: row.appDataUpdatedAt,
      };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not load parent app data right now." };
    }
  });

  router.patch("/api/admin/app-users/:id/block", requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);
    const { mode, untilDate } = ctx.request.body || {};

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    if (mode !== "indefinite" && mode !== "duration") {
      ctx.status = 400;
      ctx.body = { message: "Please choose how long to block this user." };
      return;
    }

    let blockedUntil = null;
    let blockedIndefinitely = 1;

    if (mode === "duration") {
      const normalizedUntilDate = String(untilDate || "").trim();

      if (!/^\d{4}-\d{2}-\d{2}$/.test(normalizedUntilDate)) {
        ctx.status = 400;
        ctx.body = { message: "Please type a valid unblock date." };
        return;
      }

      const [year, month, day] = normalizedUntilDate.split("-").map(Number);
      const unblockDate = new Date(year, month - 1, day);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (
        Number.isNaN(unblockDate.getTime()) ||
        unblockDate.getFullYear() !== year ||
        unblockDate.getMonth() !== month - 1 ||
        unblockDate.getDate() !== day ||
        unblockDate <= today
      ) {
        ctx.status = 400;
        ctx.body = { message: "Please choose a future unblock date." };
        return;
      }

      blockedUntil = `${normalizedUntilDate} 23:59:59`;
      blockedIndefinitely = 0;
    }

    try {
      const [result] = await pool.execute(
        `UPDATE users
         SET blocked_until = ?, blocked_indefinitely = ?
         WHERE id = ? AND role = 'parent'`,
        [blockedUntil, blockedIndefinitely, userId],
      );

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      ctx.body = {
        message:
          mode === "indefinite"
            ? "User blocked until an admin unblocks them."
            : `User blocked until ${untilDate}.`,
      };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not block user right now." };
    }
  });

  router.delete("/api/admin/app-users/:id/block", requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    try {
      const [result] = await pool.execute(
        `UPDATE users
         SET blocked_until = NULL, blocked_indefinitely = 0
         WHERE id = ? AND role = 'parent'`,
        [userId],
      );

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      ctx.body = { message: "User unblocked successfully." };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not unblock user right now." };
    }
  });

  router.patch(
    "/api/admin/app-users/:id/nutrient-limit",
    requireAdmin,
    async (ctx) => {
      const userId = Number(ctx.params.id);
      const dailyLimit = ctx.request.body?.dailyLimit;
      if (!Number.isInteger(dailyLimit) || dailyLimit < 0 || dailyLimit > 20)
        ctx.throw(400, "Enter a whole number from 0 to 20.");

      if (!Number.isInteger(userId) || userId <= 0) {
        ctx.status = 400;
        ctx.body = { message: "Please choose a valid parent user." };
        return;
      }

      try {
        const [userRows] = await pool.execute(
          "SELECT id FROM users WHERE id = ? AND role = ? LIMIT 1",
          [userId, "parent"],
        );
        if (!userRows[0]) {
          ctx.status = 404;
          ctx.body = { message: "Parent user was not found." };
          return;
        }

        await pool.execute(
          `INSERT INTO parent_app_data (user_id, nutrient_daily_limit)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE
          nutrient_daily_limit = VALUES(nutrient_daily_limit),
          updated_at = CURRENT_TIMESTAMP`,
          [userId, dailyLimit],
        );

        ctx.body = {
          message: `Nutrient estimate limit updated to ${dailyLimit} per day.`,
          nutrientDailyLimit: dailyLimit,
        };
      } catch (error) {
        console.error("Request failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = {
          message: "Could not update nutrient estimate limit right now.",
        };
      }
    },
  );

  return router;
}
