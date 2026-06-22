import bcrypt from 'bcryptjs';
import { pool } from '../db.js';
import { Router } from '../http/router.js';
import { ensureDatabaseShapeReady } from '../services/databaseShape.js';
import {
  normalizeHealthInsights,
  normalizeMealEstimate,
  normalizeMealImage,
  normalizeResponseLanguage,
  requestOpenAIJSON
} from '../services/openaiReports.js';
import { normalizeNutrientDailyLimit } from '../utils/validators.js';
import { activeBlockMessage, blockFieldsSQL, serializeUser } from '../utils/users.js';

export function createAppRoutes() {
  const router = new Router();

  router.post('/api/app-data', async (ctx) => {
    const body = ctx.request.body || {};
    const userId = Number(body.userId);
    const hasChildProfile = Object.prototype.hasOwnProperty.call(body, 'childProfile');
    const hasHealthLogs = Object.prototype.hasOwnProperty.call(body, 'healthLogs');
    const hasSavedMeals = Object.prototype.hasOwnProperty.call(body, 'savedMeals');
    const hasNutrientDailyUsage = Object.prototype.hasOwnProperty.call(body, 'nutrientDailyUsage');

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    if (!hasChildProfile && !hasHealthLogs && !hasSavedMeals && !hasNutrientDailyUsage) {
      ctx.status = 400;
      ctx.body = { message: 'No app data was provided.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

      const [userRows] = await pool.execute('SELECT id, role FROM users WHERE id = ? LIMIT 1', [userId]);
      const user = userRows[0];

      if (!user || user.role !== 'parent') {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      const childProfile = hasChildProfile ? JSON.stringify(body.childProfile || {}) : null;
      const healthLogs = hasHealthLogs ? JSON.stringify(Array.isArray(body.healthLogs) ? body.healthLogs : []) : null;
      const savedMeals = hasSavedMeals ? JSON.stringify(Array.isArray(body.savedMeals) ? body.savedMeals : []) : null;
      const nutrientDailyUsage = hasNutrientDailyUsage ? JSON.stringify(body.nutrientDailyUsage || {}) : null;

      await pool.execute(
        `INSERT INTO parent_app_data (user_id, child_profile, health_logs, saved_meals, nutrient_daily_usage)
         VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
          child_profile = COALESCE(VALUES(child_profile), child_profile),
          health_logs = COALESCE(VALUES(health_logs), health_logs),
          saved_meals = COALESCE(VALUES(saved_meals), saved_meals),
          nutrient_daily_usage = COALESCE(VALUES(nutrient_daily_usage), nutrient_daily_usage),
          updated_at = CURRENT_TIMESTAMP`,
        [userId, childProfile, healthLogs, savedMeals, nutrientDailyUsage]
      );

      ctx.body = { message: 'App data synced.' };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not sync app data right now.' };
    }
  });

  router.post('/api/app-settings', async (ctx) => {
    const userId = Number(ctx.request.body?.userId);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

      const [rows] = await pool.execute(
        `SELECT
          users.id,
          users.role,
          ${blockFieldsSQL('users')}
          COALESCE(parent_app_data.nutrient_daily_limit, 3) AS nutrientDailyLimit
         FROM users
         LEFT JOIN parent_app_data ON parent_app_data.user_id = users.id
         WHERE users.id = ? AND users.role = 'parent'
         LIMIT 1`,
        [userId]
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        nutrientDailyLimit: normalizeNutrientDailyLimit(user.nutrientDailyLimit)
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not load app settings right now.' };
    }
  });

  router.post('/api/health-insights', async (ctx) => {
    const body = ctx.request.body || {};
    const apiKey = process.env.OPENAI_API_KEY;
    const languageInfo = normalizeResponseLanguage(body.language);
    const childName = String(body.childName || 'the child').trim() || 'the child';
    const quickLogTitles = Array.isArray(body.quickLogTitles)
      ? body.quickLogTitles.map((item) => String(item).trim()).filter(Boolean)
      : [];
    const snapshotTitles = Array.isArray(body.snapshotTitles)
      ? body.snapshotTitles.map((item) => String(item).trim()).filter(Boolean)
      : [];
    const logs = Array.isArray(body.logs) ? body.logs.slice(-80) : [];

    if (!apiKey) {
      ctx.status = 503;
      ctx.body = { message: 'OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.' };
      return;
    }

    if (logs.length === 0) {
      ctx.status = 400;
      ctx.body = { message: 'No health logs were provided.' };
      return;
    }

    const logSummary = logs.map((log) => ({
      type: log.type,
      category: log.title || log.categoryID,
      timestamp: log.timestamp,
      severity: log.severity,
      value: log.value,
      comments: log.comments
    }));

    try {
      const rawInsights = await requestOpenAIJSON({
        apiKey,
        maxOutputTokens: 700,
        input: [
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text: [
                  'You are helping a parent review a special-needs child health tracking dashboard.',
                  'Use only the provided quick-log and daily snapshot data.',
                  'Return JSON only with this exact shape:',
                  '{"insights": [{"title": "Tip|Notice|Alert|Reminder", "message": string}]}',
                  `Write every title and message in ${languageInfo.instruction}.`,
                  `Use only these title words, translated for the requested language: ${languageInfo.insightTitles}.`,
                  'Write exactly 1 parent-friendly card.',
                  'Keep the message to one short sentence. Prefer under 18 English words or under 35 Chinese characters.',
                  'Use Alert only for an actual concern visible in the logs, such as high severity, repeated pain, seizure, allergic reaction, or concerning sleep/food pattern.',
                  'Do not diagnose, do not give medical instructions, and do not replace professional care.',
                  'If something seems urgent, tell the parent to contact their clinician or emergency services based on their usual care plan.',
                  '',
                  `Child name: ${childName}`,
                  `Required quick-log buttons completed today: ${quickLogTitles.join(', ') || 'none listed'}`,
                  `Required daily snapshot buttons completed today: ${snapshotTitles.join(', ') || 'none listed'}`,
                  `Today logs JSON: ${JSON.stringify(logSummary)}`
                ].join('\n')
              }
            ]
          }
        ]
      });

      ctx.body = normalizeHealthInsights(rawInsights, languageInfo);
    } catch (error) {
      console.error('Health insights error:', error.payload || error.outputText || error);
      ctx.status = error.status || 500;
      ctx.body = { message: error.message === 'OpenAI returned non-JSON output.' ? 'The AI returned unexpected health insights.' : (error.message || 'Could not create health insights right now.') };
    }
  });

  router.post('/api/analyze-meal', async (ctx) => {
    const body = ctx.request.body || {};
    const imageUrl = normalizeMealImage(body.imageData);
    const apiKey = process.env.OPENAI_API_KEY;
    const languageInfo = normalizeResponseLanguage(body.language);

    if (!imageUrl) {
      ctx.status = 400;
      ctx.body = { message: 'Please upload a valid meal photo.' };
      return;
    }

    if (!apiKey) {
      ctx.status = 503;
      ctx.body = { message: 'OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.' };
      return;
    }

    try {
      const rawEstimate = await requestOpenAIJSON({
        apiKey,
        maxOutputTokens: 700,
        input: [
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text: [
                  'Estimate nutrition from this meal photo for parent meal tracking.',
                  'Return JSON only with this exact shape:',
                  '{"calories": number, "protein": number, "carbs": number, "fat": number, "fiber": number, "sugar": number, "confidence": "low|medium|high", "summary": string, "recommendations": string[], "notes": string[]}',
                  `Write summary, recommendations, and notes in ${languageInfo.instruction}.`,
                  'Keep confidence as one of these exact English values: low, medium, high.',
                  'Use grams for protein, carbs, fat, fiber, and sugar.',
                  'Make summary one short parent-friendly sentence.',
                  'Make recommendations short practical suggestions for balance, hydration, portion checking, texture/sensory needs, or allergen caution.',
                  'If portion size or ingredients are unclear, make a conservative estimate and explain uncertainty in notes.',
                  'Do not provide medical advice.'
                ].join('\n')
              },
              {
                type: 'input_image',
                image_url: imageUrl,
                detail: 'low'
              }
            ]
          }
        ]
      });

      ctx.body = normalizeMealEstimate(rawEstimate, languageInfo);
    } catch (error) {
      console.error('Meal analysis error:', error.payload || error.outputText || error);
      ctx.status = error.status || 500;
      ctx.body = { message: error.message === 'OpenAI returned non-JSON output.' ? 'The AI returned an unexpected meal estimate.' : (error.message || 'Could not analyze this meal photo right now.') };
    }
  });

  router.post('/api/app-session', async (ctx) => {
    const userId = Number(ctx.request.body?.userId);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please log in again.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

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
        [userId]
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 404;
        ctx.body = { message: 'Please log in again.' };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        message: 'Session is active.',
        user: serializeUser(user)
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not check this account right now.' };
    }
  });

  router.post('/api/login', async (ctx) => {
    const { username, password } = ctx.request.body || {};

    if (!username || !password) {
      ctx.status = 400;
      ctx.body = { message: 'Please enter your nickname and password.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

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
         WHERE username = ?`,
        [username.trim()]
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 401;
        ctx.body = { message: 'Invalid nickname or password.' };
        return;
      }

      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        ctx.status = 401;
        ctx.body = { message: 'Invalid nickname or password.' };
        return;
      }

      if (Number(user.isBlocked) === 1) {
        ctx.status = 403;
        ctx.body = { message: activeBlockMessage(user) };
        return;
      }

      ctx.body = {
        message: 'Logged in successfully.',
        user: serializeUser(user)
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not log in right now.' };
    }
  });

  return router;
}
