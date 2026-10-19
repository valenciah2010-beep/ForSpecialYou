import { deidentify } from "../services/aiPrivacy.js";
import { rateLimit } from "../middleware/security.js";
import { aiGuard } from "../services/aiQuota.js";
import { pool } from "../db.js";
import { Router } from "../http/router.js";
import { buildAdminReportRecords } from "../services/adminReportRecords.js";
import { requireAdmin } from "../services/adminSession.js";
import {
  normalizeAdminAIReport,
  normalizeResponseLanguage,
  requestOpenAIJSON,
} from "../services/openaiReports.js";
import { parseStoredJSON } from "../utils/users.js";

export function createAdminReportsRoutes() {
  const router = new Router();

  router.post(
    "/api/admin/app-users/:id/ai-report",
    requireAdmin,
    rateLimit({ name: "report", max: 3 }),
    aiGuard("report"),
    async (ctx) => {
      const body = ctx.request.body || {};
      const userId = Number(ctx.params.id);
      const apiKey = process.env.OPENAI_API_KEY;
      const languageInfo = normalizeResponseLanguage(body.language);
      const filters = {
        startDate: String(body.startDate || "").trim(),
        endDate: String(body.endDate || "").trim(),
        includeHealth: Boolean(body.includeHealth),
        includeTherapy: Boolean(body.includeTherapy),
        includeNutrient: Boolean(body.includeNutrient),
        healthSections: Array.isArray(body.healthSections)
          ? body.healthSections
              .map((item) => String(item).trim())
              .filter(Boolean)
          : [],
      };

      if (!Number.isInteger(userId) || userId <= 0) {
        ctx.status = 400;
        ctx.body = { message: "Please choose a valid parent user." };
        return;
      }

      if (
        !/^\d{4}-\d{2}-\d{2}$/.test(filters.startDate) ||
        !/^\d{4}-\d{2}-\d{2}$/.test(filters.endDate) ||
        filters.startDate > filters.endDate
      ) {
        ctx.status = 400;
        ctx.body = { message: "Choose a valid date range." };
        return;
      }

      if (
        !filters.includeHealth &&
        !filters.includeTherapy &&
        !filters.includeNutrient
      ) {
        ctx.status = 400;
        ctx.body = { message: "Choose at least one page for the AI report." };
        return;
      }

      if (!apiKey) {
        ctx.status = 503;
        ctx.body = {
          message:
            "OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.",
        };
        return;
      }

      try {
        const [rows] = await pool.execute(
          `SELECT
          users.id,
          users.username AS nickname,
          users.email,
          parent_app_data.child_profile AS childProfile,
          parent_app_data.health_logs AS healthLogs,
          parent_app_data.saved_meals AS savedMeals,
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

        const childProfile = parseStoredJSON(row.childProfile, {});
        const healthLogs = parseStoredJSON(row.healthLogs, []);
        const savedMeals = parseStoredJSON(row.savedMeals, []);
        const records = buildAdminReportRecords({
          healthLogs,
          savedMeals,
          filters,
        });
        const dateRange =
          filters.startDate === filters.endDate
            ? filters.startDate
            : `${filters.startDate} to ${filters.endDate}`;

        if (records.length === 0) {
          ctx.status = 400;
          ctx.body = {
            message: "No selected history is available for this date range.",
          };
          return;
        }

        await ctx.state.reserveAIQuota();
        const rawReport = await requestOpenAIJSON({
          apiKey,
          maxOutputTokens: 3000,
          input: [
            {
              role: "user",
              content: [
                {
                  type: "input_text",
                  text: [
                    "You are creating an admin-only caregiver data report from a parent-managed child health tracking app.",
                    "Use only the provided synced app records. Do not invent facts.",
                    "This is not medical advice, diagnosis, or treatment.",
                    "Return JSON only with this exact shape:",
                    '{"title": string, "dateRange": string, "summary": string, "highlights": string[], "patterns": string[], "concerns": string[], "recommendations": string[], "dataQualityNotes": string[], "followUpQuestions": string[]}',
                    `Write every field in ${languageInfo.instruction}.`,
                    "Make this a deep, admin-facing review, not a short alert.",
                    "Summary must be 4-6 useful sentences and describe the overall picture of the selected date range.",
                    "Highlights should identify positive or stable observations visible in the records.",
                    "Patterns should compare timing, frequency, severity, repeated categories, therapy progress, sleep, nutrition, medication, and symptoms when those records exist.",
                    "Concerns should only include patterns visible in the selected data; include why the pattern may deserve admin or care-team attention.",
                    "Recommendations should focus on documentation quality, care coordination, parent follow-up, and questions to review with the care team.",
                    "DataQualityNotes should mention missing categories, sparse days, duplicated records, unclear notes, or limits of the selected data.",
                    "FollowUpQuestions should be concrete questions an admin could ask the parent or care team.",
                    "Each list should contain 3-8 specific, useful bullet strings when data supports it.",
                    "Avoid vague phrases. Use dates, categories, counts, and details from the selected records when available.",
                    "",
                    "Parent: anonymized",

                    `Date range: ${dateRange}`,
                    `Last app sync: ${row.appDataUpdatedAt || "Not synced yet"}`,
                    "Child profile: excluded for privacy",
                    `Selected records JSON: ${JSON.stringify(deidentify(records))}`,
                  ].join("\n"),
                },
              ],
            },
          ],
        });

        ctx.body = {
          report: normalizeAdminAIReport(rawReport, dateRange, languageInfo),
          recordCount: records.length,
          generatedAt: new Date().toISOString(),
        };
      } catch (error) {
        console.error("Admin AI report failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = {
          message:
            error.message === "OpenAI returned non-JSON output."
              ? "The AI returned an unexpected report."
              : error.message || "Could not create the AI report right now.",
        };
      }
    },
  );

  return router;
}
