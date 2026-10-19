import { requireParent } from "../services/sessions.js";
import { mealUsage } from "../services/aiQuota.js";
import { pool } from "../db.js";
import { Router } from "../http/router.js";
import { normalizeNutrientDailyLimit } from "../utils/validators.js";
import { activeBlockMessage, blockFieldsSQL } from "../utils/users.js";

import { parseStoredJSON } from "../utils/users.js";
export function createAppDataRoutes() {
  const router = new Router();

  router.post("/api/app-data/load", requireParent, async (ctx) => {
    const userId = ctx.state.appUser.id;

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    try {
      const [rows] = await pool.execute(
        `SELECT
          users.id,
          users.role,
          ${blockFieldsSQL("users")}
          parent_app_data.child_profile AS childProfile,
          parent_app_data.health_logs AS healthLogs,
          parent_app_data.saved_meals AS savedMeals,
          parent_app_data.nutrient_daily_usage AS nutrientDailyUsage,
          COALESCE(parent_app_data.nutrient_daily_limit, 3) AS nutrientDailyLimit
         FROM users
         LEFT JOIN parent_app_data ON parent_app_data.user_id = users.id
         WHERE users.id = ? AND users.role = 'parent'
         LIMIT 1`,
        [userId],
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        childProfile: parseStoredJSON(user.childProfile, {}),
        healthLogs: parseStoredJSON(user.healthLogs, []),
        savedMeals: parseStoredJSON(user.savedMeals, []),
        nutrientDailyLimit: normalizeNutrientDailyLimit(
          user.nutrientDailyLimit,
        ),
        nutrientDailyUsage: await mealUsage(userId),
      };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not load app data right now." };
    }
  });

  router.post("/api/app-data", requireParent, async (ctx) => {
    const body = ctx.request.body || {};
    const userId = ctx.state.appUser.id;
    const hasChildProfile = body.childProfile != null;
    const hasHealthLogs = body.healthLogs != null;
    const hasSavedMeals = body.savedMeals != null;
    const hasNutrientDailyUsage = body.nutrientDailyUsage != null;

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    if (
      (hasChildProfile &&
        (typeof body.childProfile !== "object" ||
          Array.isArray(body.childProfile))) ||
      (hasHealthLogs &&
        (!Array.isArray(body.healthLogs) || body.healthLogs.length > 10000)) ||
      (hasSavedMeals &&
        (!Array.isArray(body.savedMeals) || body.savedMeals.length > 2000))
    ) {
      ctx.throw(400, "Invalid app data.");
    }

    if (
      !hasChildProfile &&
      !hasHealthLogs &&
      !hasSavedMeals &&
      !hasNutrientDailyUsage
    ) {
      ctx.status = 400;
      ctx.body = { message: "No app data was provided." };
      return;
    }

    try {
      const [userRows] = await pool.execute(
        "SELECT id, role FROM users WHERE id = ? LIMIT 1",
        [userId],
      );
      const user = userRows[0];

      if (!user || user.role !== "parent") {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      const childProfile = hasChildProfile
        ? JSON.stringify(body.childProfile || {})
        : null;
      const healthLogs = hasHealthLogs
        ? JSON.stringify(Array.isArray(body.healthLogs) ? body.healthLogs : [])
        : null;
      const savedMeals = hasSavedMeals
        ? JSON.stringify(Array.isArray(body.savedMeals) ? body.savedMeals : [])
        : null;
      const nutrientDailyUsage = null;

      await pool.execute(
        `INSERT INTO parent_app_data (user_id, child_profile, health_logs, saved_meals, nutrient_daily_usage)
         VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
          child_profile = COALESCE(VALUES(child_profile), child_profile),
          health_logs = COALESCE(VALUES(health_logs), health_logs),
          saved_meals = COALESCE(VALUES(saved_meals), saved_meals),
          nutrient_daily_usage = COALESCE(VALUES(nutrient_daily_usage), nutrient_daily_usage),
          updated_at = CURRENT_TIMESTAMP`,
        [userId, childProfile, healthLogs, savedMeals, nutrientDailyUsage],
      );

      ctx.body = { message: "App data synced." };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not sync app data right now." };
    }
  });

  router.post("/api/app-settings", requireParent, async (ctx) => {
    const userId = ctx.state.appUser.id;

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: "Please choose a valid parent user." };
      return;
    }

    try {
      const [rows] = await pool.execute(
        `SELECT
          users.id,
          users.role,
          ${blockFieldsSQL("users")}
          COALESCE(parent_app_data.nutrient_daily_limit, 3) AS nutrientDailyLimit
         FROM users
         LEFT JOIN parent_app_data ON parent_app_data.user_id = users.id
         WHERE users.id = ? AND users.role = 'parent'
         LIMIT 1`,
        [userId],
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 404;
        ctx.body = { message: "Parent user was not found." };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        nutrientDailyLimit: normalizeNutrientDailyLimit(
          user.nutrientDailyLimit,
        ),
        nutrientDailyUsage: await mealUsage(userId),
      };
    } catch (error) {
      console.error("Request failed:", error.code || error.name);
      ctx.status = error.status || 500;
      ctx.body = { message: "Could not load app settings right now." };
    }
  });

  return router;
}
