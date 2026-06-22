import bcrypt from 'bcryptjs';
import { pool } from '../db.js';
import { Router } from '../http/router.js';
import { buildAdminReportRecords } from '../services/adminReportRecords.js';
import {
  clearAdminSessionCookie,
  createAdminSession,
  deleteAdminSessionFromRequest,
  requireAdmin,
  setAdminSessionCookie
} from '../services/adminSession.js';
import { ensureDatabaseShapeReady } from '../services/databaseShape.js';
import {
  normalizeAdminAIReport,
  normalizeResponseLanguage,
  requestOpenAIJSON
} from '../services/openaiReports.js';
import { normalizeNutrientDailyLimit } from '../utils/validators.js';
import { blockFieldsSQL, parseStoredJSON, publicUser } from '../utils/users.js';

export function createAdminRoutes() {
  const router = new Router();

  router.post('/api/admin/login', async (ctx) => {
    const { username, password } = ctx.request.body || {};

    if (!username || !password) {
      ctx.status = 400;
      ctx.body = { message: 'Please enter an admin username and password.' };
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
        [username.trim()]
      );

      const user = rows[0];
      if (!user) {
        ctx.status = 401;
        ctx.body = { message: 'Invalid admin username or password.' };
        return;
      }

      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        ctx.status = 401;
        ctx.body = { message: 'Invalid admin username or password.' };
        return;
      }

      if (user.role !== 'admin') {
        ctx.status = 403;
        ctx.body = { message: 'Only admin accounts can access this website.' };
        return;
      }

      const token = createAdminSession(user.id);
      setAdminSessionCookie(ctx, token);

      ctx.body = {
        message: 'Admin logged in successfully.',
        user: publicUser(user)
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not log in right now.' };
    }
  });

  router.get('/api/admin/session', requireAdmin, (ctx) => {
    ctx.body = { user: ctx.state.adminUser };
  });

  router.post('/api/admin/logout', async (ctx) => {
    deleteAdminSessionFromRequest(ctx);
    clearAdminSessionCookie(ctx);
    ctx.body = { message: 'Logged out successfully.' };
  });

  router.get('/api/admin/app-users', requireAdmin, async (ctx) => {
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
        ORDER BY created_at DESC`
      );

      ctx.body = { users: rows };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not load simulator app users right now.' };
    }
  });

  router.get('/api/admin/app-users/:id/details', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
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
          ${blockFieldsSQL('users')}
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
        [userId]
      );

      const row = rows[0];
      if (!row) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
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
          createdAt: row.createdAt
        },
        childProfile: parseStoredJSON(row.childProfile, {}),
        healthLogs: parseStoredJSON(row.healthLogs, []),
        savedMeals: parseStoredJSON(row.savedMeals, []),
        nutrientDailyUsage: parseStoredJSON(row.nutrientDailyUsage, null),
        nutrientDailyLimit: normalizeNutrientDailyLimit(row.nutrientDailyLimit),
        appDataUpdatedAt: row.appDataUpdatedAt
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not load parent app data right now.' };
    }
  });

  router.post('/api/admin/app-users/:id/ai-report', requireAdmin, async (ctx) => {
    const body = ctx.request.body || {};
    const userId = Number(ctx.params.id);
    const apiKey = process.env.OPENAI_API_KEY;
    const languageInfo = normalizeResponseLanguage(body.language);
    const filters = {
      startDate: String(body.startDate || '').trim(),
      endDate: String(body.endDate || '').trim(),
      includeHealth: Boolean(body.includeHealth),
      includeTherapy: Boolean(body.includeTherapy),
      includeNutrient: Boolean(body.includeNutrient),
      healthSections: Array.isArray(body.healthSections)
        ? body.healthSections.map((item) => String(item).trim()).filter(Boolean)
        : []
    };

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    if (!/^\d{4}-\d{2}-\d{2}$/.test(filters.startDate) || !/^\d{4}-\d{2}-\d{2}$/.test(filters.endDate) || filters.startDate > filters.endDate) {
      ctx.status = 400;
      ctx.body = { message: 'Choose a valid date range.' };
      return;
    }

    if (!filters.includeHealth && !filters.includeTherapy && !filters.includeNutrient) {
      ctx.status = 400;
      ctx.body = { message: 'Choose at least one page for the AI report.' };
      return;
    }

    if (!apiKey) {
      ctx.status = 503;
      ctx.body = { message: 'OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.' };
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
        [userId]
      );

      const row = rows[0];
      if (!row) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      const childProfile = parseStoredJSON(row.childProfile, {});
      const healthLogs = parseStoredJSON(row.healthLogs, []);
      const savedMeals = parseStoredJSON(row.savedMeals, []);
      const records = buildAdminReportRecords({ healthLogs, savedMeals, filters });
      const dateRange = filters.startDate === filters.endDate
        ? filters.startDate
        : `${filters.startDate} to ${filters.endDate}`;

      if (records.length === 0) {
        ctx.status = 400;
        ctx.body = { message: 'No selected history is available for this date range.' };
        return;
      }

      const rawReport = await requestOpenAIJSON({
        apiKey,
        maxOutputTokens: 3000,
        input: [
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text: [
                  'You are creating an admin-only caregiver data report from a parent-managed child health tracking app.',
                  'Use only the provided synced app records. Do not invent facts.',
                  'This is not medical advice, diagnosis, or treatment.',
                  'Return JSON only with this exact shape:',
                  '{"title": string, "dateRange": string, "summary": string, "highlights": string[], "patterns": string[], "concerns": string[], "recommendations": string[], "dataQualityNotes": string[], "followUpQuestions": string[]}',
                  `Write every field in ${languageInfo.instruction}.`,
                  'Make this a deep, admin-facing review, not a short alert.',
                  'Summary must be 4-6 useful sentences and describe the overall picture of the selected date range.',
                  'Highlights should identify positive or stable observations visible in the records.',
                  'Patterns should compare timing, frequency, severity, repeated categories, therapy progress, sleep, nutrition, medication, and symptoms when those records exist.',
                  'Concerns should only include patterns visible in the selected data; include why the pattern may deserve admin or care-team attention.',
                  'Recommendations should focus on documentation quality, care coordination, parent follow-up, and questions to review with the care team.',
                  'DataQualityNotes should mention missing categories, sparse days, duplicated records, unclear notes, or limits of the selected data.',
                  'FollowUpQuestions should be concrete questions an admin could ask the parent or care team.',
                  'Each list should contain 3-8 specific, useful bullet strings when data supports it.',
                  'Avoid vague phrases. Use dates, categories, counts, and details from the selected records when available.',
                  '',
                  `Parent username: ${row.nickname}`,
                  `Parent email: ${row.email}`,
                  `Date range: ${dateRange}`,
                  `Last app sync: ${row.appDataUpdatedAt || 'Not synced yet'}`,
                  `Child profile JSON: ${JSON.stringify(childProfile)}`,
                  `Selected records JSON: ${JSON.stringify(records)}`
                ].join('\n')
              }
            ]
          }
        ]
      });

      ctx.body = {
        report: normalizeAdminAIReport(rawReport, dateRange, languageInfo),
        recordCount: records.length,
        generatedAt: new Date().toISOString()
      };
    } catch (error) {
      console.error('Admin AI report error:', error.payload || error.outputText || error);
      ctx.status = error.status || 500;
      ctx.body = { message: error.message === 'OpenAI returned non-JSON output.' ? 'The AI returned an unexpected report.' : (error.message || 'Could not create the AI report right now.') };
    }
  });

  router.patch('/api/admin/app-users/:id/block', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);
    const { mode, untilDate } = ctx.request.body || {};

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    if (mode !== 'indefinite' && mode !== 'duration') {
      ctx.status = 400;
      ctx.body = { message: 'Please choose how long to block this user.' };
      return;
    }

    let blockedUntil = null;
    let blockedIndefinitely = 1;

    if (mode === 'duration') {
      const normalizedUntilDate = String(untilDate || '').trim();

      if (!/^\d{4}-\d{2}-\d{2}$/.test(normalizedUntilDate)) {
        ctx.status = 400;
        ctx.body = { message: 'Please type a valid unblock date.' };
        return;
      }

      const [year, month, day] = normalizedUntilDate.split('-').map(Number);
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
        ctx.body = { message: 'Please choose a future unblock date.' };
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
        [blockedUntil, blockedIndefinitely, userId]
      );

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      ctx.body = {
        message: mode === 'indefinite'
          ? 'User blocked until an admin unblocks them.'
          : `User blocked until ${untilDate}.`
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not block user right now.' };
    }
  });

  router.delete('/api/admin/app-users/:id/block', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    try {
      const [result] = await pool.execute(
        `UPDATE users
         SET blocked_until = NULL, blocked_indefinitely = 0
         WHERE id = ? AND role = 'parent'`,
        [userId]
      );

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      ctx.body = { message: 'User unblocked successfully.' };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not unblock user right now.' };
    }
  });

  router.patch('/api/admin/app-users/:id/nutrient-limit', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);
    const dailyLimit = normalizeNutrientDailyLimit(ctx.request.body?.dailyLimit);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid parent user.' };
      return;
    }

    try {
      const [userRows] = await pool.execute('SELECT id FROM users WHERE id = ? AND role = ? LIMIT 1', [userId, 'parent']);
      if (!userRows[0]) {
        ctx.status = 404;
        ctx.body = { message: 'Parent user was not found.' };
        return;
      }

      await pool.execute(
        `INSERT INTO parent_app_data (user_id, nutrient_daily_limit)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE
          nutrient_daily_limit = VALUES(nutrient_daily_limit),
          updated_at = CURRENT_TIMESTAMP`,
        [userId, dailyLimit]
      );

      ctx.body = {
        message: `Nutrient estimate limit updated to ${dailyLimit} per day.`,
        nutrientDailyLimit: dailyLimit
      };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not update nutrient estimate limit right now.' };
    }
  });

  return router;
}
