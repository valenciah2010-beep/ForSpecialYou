import { uploadedImage } from "../services/uploads.js";
import { deidentify } from "../services/aiPrivacy.js";
import { requireParent } from "../services/sessions.js";
import { rateLimit } from "../middleware/security.js";
import { aiGuard } from "../services/aiQuota.js";
import { Router } from "../http/router.js";
import {
  normalizeHealthInsights,
  normalizeMealEstimate,
  normalizeMealImage,
  normalizeResponseLanguage,
  requestOpenAIJSON,
} from "../services/openaiReports.js";

export function createAppAIRoutes() {
  const router = new Router();

  router.post(
    "/api/health-insights",
    requireParent,
    rateLimit({ name: "insight", max: 5 }),
    aiGuard("insight"),
    async (ctx) => {
      const body = ctx.request.body || {};
      const apiKey = process.env.OPENAI_API_KEY;
      const languageInfo = normalizeResponseLanguage(body.language);
      const childName =
        String(body.childName || "the child").trim() || "the child";
      const quickLogTitles = Array.isArray(body.quickLogTitles)
        ? body.quickLogTitles.map((item) => String(item).trim()).filter(Boolean)
        : [];
      const snapshotTitles = Array.isArray(body.snapshotTitles)
        ? body.snapshotTitles.map((item) => String(item).trim()).filter(Boolean)
        : [];
      const logs = Array.isArray(body.logs) ? body.logs.slice(-80) : [];

      if (!apiKey) {
        ctx.status = 503;
        ctx.body = {
          message:
            "OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.",
        };
        return;
      }

      if (logs.length === 0) {
        ctx.status = 400;
        ctx.body = { message: "No health logs were provided." };
        return;
      }

      const logSummary = logs.map((log) => ({
        type: log.type,
        category: log.title || log.categoryID,
        timestamp: log.timestamp,
        severity: log.severity,
        value: log.value,
        comments: log.comments,
      }));

      try {
        await ctx.state.reserveAIQuota();
        const rawInsights = await requestOpenAIJSON({
          apiKey,
          maxOutputTokens: 700,
          input: [
            {
              role: "user",
              content: [
                {
                  type: "input_text",
                  text: [
                    "You are helping a parent review a special-needs child health tracking dashboard.",
                    "Use only the provided quick-log and daily snapshot data.",
                    "Return JSON only with this exact shape:",
                    '{"insights": [{"title": "Tip|Notice|Alert|Reminder", "message": string}]}',
                    `Write every title and message in ${languageInfo.instruction}.`,
                    `Use only these title words, translated for the requested language: ${languageInfo.insightTitles}.`,
                    "Write exactly 1 parent-friendly card.",
                    "Keep the message to one short sentence. Prefer under 18 English words or under 35 Chinese characters.",
                    "Use Alert only for an actual concern visible in the logs, such as high severity, repeated pain, seizure, allergic reaction, or concerning sleep/food pattern.",
                    "Do not diagnose, do not give medical instructions, and do not replace professional care.",
                    "If something seems urgent, tell the parent to contact their clinician or emergency services based on their usual care plan.",
                    "",
                    "Child: anonymized",
                    `Required quick-log buttons completed today: ${quickLogTitles.join(", ") || "none listed"}`,
                    `Required daily snapshot buttons completed today: ${snapshotTitles.join(", ") || "none listed"}`,
                    `Today logs JSON: ${JSON.stringify(deidentify(logSummary))}`,
                  ].join("\n"),
                },
              ],
            },
          ],
        });

        ctx.body = normalizeHealthInsights(rawInsights, languageInfo);
      } catch (error) {
        console.error("Health insights failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = {
          message:
            error.message === "OpenAI returned non-JSON output."
              ? "The AI returned unexpected health insights."
              : error.message || "Could not create health insights right now.",
        };
      }
    },
  );

  router.post(
    "/api/analyze-meal",
    requireParent,
    rateLimit({ name: "meal", max: 5 }),
    aiGuard("meal"),
    async (ctx) => {
      const body = ctx.request.body || {};
      const imageUrl = body.imageId
        ? "data:image/jpeg;base64," +
          (await uploadedImage(body.imageId, ctx.state.appUser.id)).toString(
            "base64",
          )
        : await normalizeMealImage(body.imageData);
      const apiKey = process.env.OPENAI_API_KEY;
      const languageInfo = normalizeResponseLanguage(body.language);

      if (!imageUrl) {
        ctx.status = 400;
        ctx.body = { message: "Please upload a valid meal photo." };
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
        await ctx.state.reserveAIQuota();
        const rawEstimate = await requestOpenAIJSON({
          apiKey,
          maxOutputTokens: 700,
          input: [
            {
              role: "user",
              content: [
                {
                  type: "input_text",
                  text: [
                    "Estimate nutrition from this meal photo for parent meal tracking.",
                    "Return JSON only with this exact shape:",
                    '{"calories": number, "protein": number, "carbs": number, "fat": number, "fiber": number, "sugar": number, "confidence": "low|medium|high", "summary": string, "recommendations": string[], "notes": string[]}',
                    `Write summary, recommendations, and notes in ${languageInfo.instruction}.`,
                    "Keep confidence as one of these exact English values: low, medium, high.",
                    "Use grams for protein, carbs, fat, fiber, and sugar.",
                    "Make summary one short parent-friendly sentence.",
                    "Make recommendations short practical suggestions for balance, hydration, portion checking, texture/sensory needs, or allergen caution.",
                    "If portion size or ingredients are unclear, make a conservative estimate and explain uncertainty in notes.",
                    "Do not provide medical advice.",
                  ].join("\n"),
                },
                {
                  type: "input_image",
                  image_url: imageUrl,
                  detail: "low",
                },
              ],
            },
          ],
        });

        ctx.body = normalizeMealEstimate(rawEstimate, languageInfo);
      } catch (error) {
        console.error("Meal analysis failed:", error.code || error.name);
        ctx.status = error.status || 500;
        ctx.body = {
          message:
            error.message === "OpenAI returned non-JSON output."
              ? "The AI returned an unexpected meal estimate."
              : error.message || "Could not analyze this meal photo right now.",
        };
      }
    },
  );

  return router;
}
