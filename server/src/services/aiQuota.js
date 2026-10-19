import { auditEvent } from "./audit.js";
import { pool } from "../db.js";
import { serverConfig } from "../config.js";
import { normalizeNutrientDailyLimit } from "../utils/validators.js";
export const utcDateKey = () => new Date().toISOString().slice(0, 10);
export async function reserveQuota(userId, kind) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    // Serialize all reservations for this account, including first use and concurrent devices.
    await connection.execute("SELECT id FROM users WHERE id=? FOR UPDATE", [
      userId,
    ]);
    let limit =
      kind === "meal"
        ? 3
        : kind === "insight"
          ? serverConfig.insightDailyLimit
          : serverConfig.reportDailyLimit;
    if (kind === "meal") {
      const [rows] = await connection.execute(
        "SELECT nutrient_daily_limit FROM parent_app_data WHERE user_id=?",
        [userId],
      );
      limit = normalizeNutrientDailyLimit(rows[0]?.nutrient_daily_limit ?? 3);
    }
    const dateKey = utcDateKey();
    const [rows] = await connection.execute(
      "SELECT used FROM ai_daily_usage WHERE user_id=? AND usage_date=? AND kind=?",
      [userId, dateKey, kind],
    );
    if ((rows[0]?.used || 0) >= limit) {
      const error = new Error("Daily AI limit reached.");
      error.status = 429;
      throw error;
    }
    await connection.execute(
      "INSERT INTO ai_daily_usage (user_id,usage_date,kind,used) VALUES (?,?,?,1) ON DUPLICATE KEY UPDATE used=used+1",
      [userId, dateKey, kind],
    );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}
export async function mealUsage(userId) {
  const dateKey = utcDateKey();
  const [rows] = await pool.execute(
    "SELECT used FROM ai_daily_usage WHERE user_id=? AND usage_date=? AND kind='meal'",
    [userId, dateKey],
  );
  return { dateKey, uploadCount: 0, estimateCount: rows[0]?.used || 0 };
}
export function aiGuard(kind) {
  return async (ctx, next) => {
    if (ctx.request.body?.aiConsent !== true) {
      ctx.status = 403;
      ctx.body = { message: "Confirm AI data processing before continuing." };
      return;
    }
    if (!serverConfig.aiEnabled) {
      ctx.status = 503;
      ctx.body = {
        message: "AI processing is disabled by the service operator.",
      };
      return;
    }
    if (!process.env.OPENAI_API_KEY) {
      ctx.status = 503;
      ctx.body = { message: "AI service is not configured." };
      return;
    }
    ctx.state.reserveAIQuota = async () => {
      const userId = ctx.state.appUser?.id || ctx.state.adminUser.id;
      await reserveQuota(userId, kind);
      await auditEvent(userId, "AI " + kind);
    };
    return next();
  };
}
