import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './db.js';

dotenv.config();

const dirname = path.dirname(fileURLToPath(import.meta.url));
const adminSitePath = path.join(dirname, '..', 'dist');
const app = express();
const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '127.0.0.1';
const roles = new Set(['patient', 'parent', 'caregiver', 'doctor', 'admin']);
const adminSessionCookieName = 'care_portal_admin_session';
const adminSessions = new Map();
let databaseShapeReady = false;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '20mb' }));

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPassword(password) {
  return password.length >= 6 && /\d/.test(password);
}

function normalizeProfileImage(profileImage) {
  if (!profileImage) return null;
  const trimmedImage = String(profileImage).trim();
  return trimmedImage.startsWith('data:image/') ? trimmedImage : null;
}

function parseCookies(cookieHeader = '') {
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

function setAdminSessionCookie(res, token) {
  const cookie = [
    `${adminSessionCookieName}=${encodeURIComponent(token)}`,
    'Path=/',
    'HttpOnly',
    'SameSite=Lax',
    `Max-Age=${60 * 60 * 12}`
  ].join('; ');

  res.setHeader('Set-Cookie', cookie);
}

function clearAdminSessionCookie(res) {
  res.setHeader(
    'Set-Cookie',
    `${adminSessionCookieName}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`
  );
}

function publicUser(user) {
  return {
    id: user.id,
    nickname: user.username,
    email: user.email,
    role: user.role,
    profileImage: user.profile_image
  };
}

function blockFieldsSQL(prefix = '') {
  const tablePrefix = prefix ? `${prefix}.` : '';
  return `
    ${tablePrefix}blocked_indefinitely AS blockedIndefinitely,
    DATE_FORMAT(${tablePrefix}blocked_until, '%Y-%m-%d %H:%i') AS blockedUntil,
    CASE
      WHEN ${tablePrefix}blocked_indefinitely = 1
        OR (${tablePrefix}blocked_until IS NOT NULL AND ${tablePrefix}blocked_until > NOW())
      THEN 1
      ELSE 0
    END AS isBlocked,
  `;
}

function activeBlockMessage(user) {
  if (Number(user.blockedIndefinitely || user.blocked_indefinitely) === 1) {
    return 'This account is blocked until an admin unblocks it.';
  }

  const blockedUntil = user.blockedUntil || user.blocked_until;
  if (blockedUntil) {
    return `This account is blocked until ${blockedUntil}.`;
  }

  return 'This account is currently blocked.';
}

function parseStoredJSON(value, fallback) {
  if (!value) return fallback;

  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

async function getAdminUser(req) {
  const cookies = parseCookies(req.headers.cookie || '');
  const token = cookies[adminSessionCookieName];
  const session = token ? adminSessions.get(token) : null;

  if (!token || !session) {
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

async function requireAdmin(req, res, next) {
  try {
    await ensureDatabaseShapeReady();
    const adminUser = await getAdminUser(req);

    if (!adminUser) {
      return res.status(401).json({ message: 'Admin access is required.' });
    }

    req.adminUser = adminUser;
    next();
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not verify admin access right now.' });
  }
}

function normalizeMealImage(imageData) {
  if (!imageData) return null;

  const trimmedImage = String(imageData).trim();
  if (trimmedImage.startsWith('data:image/')) {
    return trimmedImage;
  }

  if (/^[A-Za-z0-9+/=\s]+$/.test(trimmedImage)) {
    return `data:image/jpeg;base64,${trimmedImage.replace(/\s/g, '')}`;
  }

  return null;
}

function extractOpenAIText(payload) {
  if (typeof payload?.output_text === 'string') {
    return payload.output_text;
  }

  const output = Array.isArray(payload?.output) ? payload.output : [];
  return output
    .flatMap((item) => item.content || [])
    .map((content) => content.text || '')
    .filter(Boolean)
    .join('\n');
}

function parseJSONOutput(text) {
  const trimmedText = String(text || '').trim();

  try {
    return JSON.parse(trimmedText);
  } catch {
    const match = trimmedText.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

function clampNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(Math.max(Math.round(number), min), max);
}

function normalizeMealEstimate(rawEstimate) {
  const notes = Array.isArray(rawEstimate?.notes)
    ? rawEstimate.notes.map((note) => String(note).trim()).filter(Boolean).slice(0, 5)
    : [];
  const recommendations = Array.isArray(rawEstimate?.recommendations)
    ? rawEstimate.recommendations.map((item) => String(item).trim()).filter(Boolean).slice(0, 5)
    : [];
  const summary = String(rawEstimate?.summary || '').trim();

  return {
    calories: clampNumber(rawEstimate?.calories, 0, 3000, 0),
    protein: clampNumber(rawEstimate?.protein, 0, 250, 0),
    carbs: clampNumber(rawEstimate?.carbs, 0, 400, 0),
    fat: clampNumber(rawEstimate?.fat, 0, 250, 0),
    fiber: clampNumber(rawEstimate?.fiber, 0, 100, 0),
    sugar: clampNumber(rawEstimate?.sugar, 0, 250, 0),
    confidence: String(rawEstimate?.confidence || 'low').trim(),
    summary: summary || 'This is a photo-based meal estimate. Exact totals may vary with portion size and ingredients.',
    recommendations: recommendations.length > 0
      ? recommendations
      : ['Confirm portion size when possible', 'Check allergens separately', 'Use this estimate for tracking, not medical advice'],
    notes: notes.length > 0
      ? notes
      : ['AI photo estimate only', 'Portion size may change totals', 'Confirm allergens separately']
  };
}

async function ensureDatabaseShape() {
  let setupFailed = false;

  try {
    await pool.execute(
      "ALTER TABLE users MODIFY role ENUM('patient', 'parent', 'caregiver', 'doctor', 'admin') NOT NULL"
    );
    await pool.execute("UPDATE users SET role = 'parent' WHERE role = 'patient'");
  } catch (error) {
    setupFailed = true;
    console.error('Role setup check failed:', error.message);
  }

  try {
    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'users'
        AND COLUMN_NAME = 'profile_image'`
    );

    if (columns.length === 0) {
      await pool.execute('ALTER TABLE users ADD COLUMN profile_image LONGTEXT NULL');
    }
  } catch (error) {
    setupFailed = true;
    console.error('Profile image setup check failed:', error.message);
  }

  try {
    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'users'
        AND COLUMN_NAME IN ('blocked_until', 'blocked_indefinitely')`
    );
    const existingColumns = new Set(columns.map((column) => column.COLUMN_NAME));

    if (!existingColumns.has('blocked_until')) {
      await pool.execute('ALTER TABLE users ADD COLUMN blocked_until DATETIME NULL');
    }

    if (!existingColumns.has('blocked_indefinitely')) {
      await pool.execute('ALTER TABLE users ADD COLUMN blocked_indefinitely TINYINT(1) NOT NULL DEFAULT 0');
    }
  } catch (error) {
    setupFailed = true;
    console.error('User block setup check failed:', error.message);
  }

  try {
    await pool.execute(
      `CREATE TABLE IF NOT EXISTS parent_app_data (
        user_id INT PRIMARY KEY,
        child_profile LONGTEXT NULL,
        health_logs LONGTEXT NULL,
        saved_meals LONGTEXT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT parent_app_data_user_fk
          FOREIGN KEY (user_id) REFERENCES users(id)
          ON DELETE CASCADE
      )`
    );

    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'parent_app_data'
        AND COLUMN_NAME = 'saved_meals'`
    );

    if (columns.length === 0) {
      await pool.execute('ALTER TABLE parent_app_data ADD COLUMN saved_meals LONGTEXT NULL AFTER health_logs');
    }
  } catch (error) {
    setupFailed = true;
    console.error('Parent app data setup check failed:', error.message);
  }

  databaseShapeReady = !setupFailed;
}

async function ensureDatabaseShapeReady() {
  if (!databaseShapeReady) {
    await ensureDatabaseShape();
  }
}

app.get('/api/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/api/admin/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Please enter an admin username and password.' });
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
      return res.status(401).json({ message: 'Invalid admin username or password.' });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid admin username or password.' });
    }

    if (user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admin accounts can access this website.' });
    }

    const token = crypto.randomUUID();
    adminSessions.set(token, {
      userId: user.id,
      createdAt: Date.now()
    });
    setAdminSessionCookie(res, token);

    res.json({
      message: 'Admin logged in successfully.',
      user: publicUser(user)
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not log in right now.' });
  }
});

app.get('/api/admin/session', requireAdmin, (req, res) => {
  res.json({ user: req.adminUser });
});

app.post('/api/admin/logout', async (req, res) => {
  const cookies = parseCookies(req.headers.cookie || '');
  const token = cookies[adminSessionCookieName];

  if (token) {
    adminSessions.delete(token);
  }

  clearAdminSessionCookie(res);
  res.json({ message: 'Logged out successfully.' });
});

app.get('/api/admin/app-users', requireAdmin, async (_req, res) => {
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

    res.json({ users: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not load simulator app users right now.' });
  }
});

app.get('/api/admin/app-users/:id/details', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid parent user.' });
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
        DATE_FORMAT(parent_app_data.updated_at, '%Y-%m-%d %H:%i') AS appDataUpdatedAt
      FROM users
      LEFT JOIN parent_app_data ON parent_app_data.user_id = users.id
      WHERE users.id = ? AND users.role = 'parent'
      LIMIT 1`,
      [userId]
    );

    const row = rows[0];
    if (!row) {
      return res.status(404).json({ message: 'Parent user was not found.' });
    }

    res.json({
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
      appDataUpdatedAt: row.appDataUpdatedAt
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not load parent app data right now.' });
  }
});

app.patch('/api/admin/app-users/:id/block', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);
  const { mode, untilDate } = req.body || {};

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid parent user.' });
  }

  if (mode !== 'indefinite' && mode !== 'duration') {
    return res.status(400).json({ message: 'Please choose how long to block this user.' });
  }

  let blockedUntil = null;
  let blockedIndefinitely = 1;

  if (mode === 'duration') {
    const normalizedUntilDate = String(untilDate || '').trim();

    if (!/^\d{4}-\d{2}-\d{2}$/.test(normalizedUntilDate)) {
      return res.status(400).json({ message: 'Please type a valid unblock date.' });
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
      return res.status(400).json({ message: 'Please choose a future unblock date.' });
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
      return res.status(404).json({ message: 'Parent user was not found.' });
    }

    res.json({
      message: mode === 'indefinite'
        ? 'User blocked until an admin unblocks them.'
        : `User blocked until ${untilDate}.`
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not block user right now.' });
  }
});

app.delete('/api/admin/app-users/:id/block', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid parent user.' });
  }

  try {
    const [result] = await pool.execute(
      `UPDATE users
       SET blocked_until = NULL, blocked_indefinitely = 0
       WHERE id = ? AND role = 'parent'`,
      [userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Parent user was not found.' });
    }

    res.json({ message: 'User unblocked successfully.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not unblock user right now.' });
  }
});

app.post('/api/app-data', async (req, res) => {
  const userId = Number(req.body?.userId);
  const hasChildProfile = Object.prototype.hasOwnProperty.call(req.body || {}, 'childProfile');
  const hasHealthLogs = Object.prototype.hasOwnProperty.call(req.body || {}, 'healthLogs');
  const hasSavedMeals = Object.prototype.hasOwnProperty.call(req.body || {}, 'savedMeals');

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid parent user.' });
  }

  if (!hasChildProfile && !hasHealthLogs && !hasSavedMeals) {
    return res.status(400).json({ message: 'No app data was provided.' });
  }

  try {
    await ensureDatabaseShapeReady();

    const [userRows] = await pool.execute('SELECT id, role FROM users WHERE id = ? LIMIT 1', [userId]);
    const user = userRows[0];

    if (!user || user.role !== 'parent') {
      return res.status(404).json({ message: 'Parent user was not found.' });
    }

    const childProfile = hasChildProfile ? JSON.stringify(req.body.childProfile || {}) : null;
    const healthLogs = hasHealthLogs ? JSON.stringify(Array.isArray(req.body.healthLogs) ? req.body.healthLogs : []) : null;
    const savedMeals = hasSavedMeals ? JSON.stringify(Array.isArray(req.body.savedMeals) ? req.body.savedMeals : []) : null;

    await pool.execute(
      `INSERT INTO parent_app_data (user_id, child_profile, health_logs, saved_meals)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
        child_profile = COALESCE(VALUES(child_profile), child_profile),
        health_logs = COALESCE(VALUES(health_logs), health_logs),
        saved_meals = COALESCE(VALUES(saved_meals), saved_meals),
        updated_at = CURRENT_TIMESTAMP`,
      [userId, childProfile, healthLogs, savedMeals]
    );

    res.json({ message: 'App data synced.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not sync app data right now.' });
  }
});

app.post('/api/analyze-meal', async (req, res) => {
  const imageUrl = normalizeMealImage(req.body?.imageData);
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';

  if (!imageUrl) {
    return res.status(400).json({ message: 'Please upload a valid meal photo.' });
  }

  if (!apiKey) {
    return res.status(503).json({
      message: 'OpenAI is not configured. Add OPENAI_API_KEY to .env and restart the server.'
    });
  }

  try {
    const openAIResponse = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model,
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
        ],
        max_output_tokens: 700
      })
    });

    const payload = await openAIResponse.json().catch(() => ({}));

    if (!openAIResponse.ok) {
      console.error('OpenAI meal analysis failed:', payload);
      return res.status(502).json({
        message: payload?.error?.message || 'Could not analyze this meal photo right now.'
      });
    }

    const outputText = extractOpenAIText(payload);
    const rawEstimate = parseJSONOutput(outputText);

    if (!rawEstimate) {
      console.error('OpenAI meal analysis returned non-JSON:', outputText);
      return res.status(502).json({ message: 'The AI returned an unexpected meal estimate.' });
    }

    res.json(normalizeMealEstimate(rawEstimate));
  } catch (error) {
    console.error('Meal analysis error:', error);
    res.status(500).json({ message: 'Could not analyze this meal photo right now.' });
  }
});

app.get('/api/users', requireAdmin, async (_req, res) => {
  try {
    await ensureDatabaseShapeReady();

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
      ORDER BY created_at DESC`
    );

    res.json({ users: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not load users right now.' });
  }
});

app.get('/api/users/:id', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid user.' });
  }

  try {
    await ensureDatabaseShapeReady();

    const [rows] = await pool.execute(
      `SELECT
        id,
        username AS nickname,
        email,
        role,
        profile_image AS profileImage,
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS createdAt
      FROM users
      WHERE id = ?
      LIMIT 1`,
      [userId]
    );

    const user = rows[0];
    if (!user) {
      return res.status(404).json({ message: 'User was not found.' });
    }

    res.json({ user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not load user right now.' });
  }
});

app.post('/api/signup', async (req, res) => {
  const { nickname, username, password, verifyPassword, email, role } = req.body;
  const requestedNickname = (nickname || username || '').trim();
  const requestedEmail = (email || '').trim().toLowerCase();
  const requestedRole = role || 'parent';

  if (!requestedNickname || !password || !verifyPassword || !requestedEmail || !requestedRole) {
    return res.status(400).json({ message: 'Please fill out every field.' });
  }

  if (!isValidEmail(requestedEmail)) {
    return res.status(400).json({ message: 'Please enter a valid email address.' });
  }

  if (!isValidPassword(password)) {
    return res
      .status(400)
      .json({ message: 'Password must be at least 6 characters and include one number.' });
  }

  if (password !== verifyPassword) {
    return res.status(400).json({ message: 'Passwords do not match.' });
  }

  if (!roles.has(requestedRole)) {
    return res.status(400).json({ message: 'Please choose a valid account type.' });
  }

  try {
    await ensureDatabaseShapeReady();
    const adminUser = await getAdminUser(req);

    if (!adminUser && requestedRole !== 'parent') {
      return res.status(403).json({ message: 'Only admins can create non-parent accounts.' });
    }

    const [emailRows] = await pool.execute('SELECT id FROM users WHERE email = ? LIMIT 1', [
      requestedEmail
    ]);

    if (emailRows.length > 0) {
      return res.status(409).json({ message: 'This email has already been used.' });
    }

    const [nicknameRows] = await pool.execute('SELECT id FROM users WHERE username = ? LIMIT 1', [
      requestedNickname
    ]);

    if (nicknameRows.length > 0) {
      return res.status(409).json({ message: 'This nickname is already in use.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await pool.execute(
      'INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [requestedNickname, requestedEmail, passwordHash, requestedRole]
    );

    res.status(201).json({ message: 'Account created successfully.' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Nickname or email is already in use.' });
    }

    console.error(error);
    res.status(500).json({ message: 'Could not create account right now.' });
  }
});

app.put('/api/users/:id', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);
  const { nickname, username, email, password, profileImage } = req.body;
  const requestedNickname = (nickname || username || '').trim();
  const requestedEmail = (email || '').trim().toLowerCase();
  const requestedPassword = (password || '').trim();
  const shouldUpdateProfileImage = Object.prototype.hasOwnProperty.call(req.body, 'profileImage');

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid user.' });
  }

  if (!requestedNickname || !requestedEmail) {
    return res.status(400).json({ message: 'Please fill out nickname and email.' });
  }

  if (!isValidEmail(requestedEmail)) {
    return res.status(400).json({ message: 'Please enter a valid email address.' });
  }

  if (requestedPassword && !isValidPassword(requestedPassword)) {
    return res
      .status(400)
      .json({ message: 'Password must be at least 6 characters and include one number.' });
  }

  try {
    await ensureDatabaseShapeReady();

    const [existingRows] = await pool.execute(
      'SELECT id, profile_image FROM users WHERE id = ? LIMIT 1',
      [userId]
    );

    if (existingRows.length === 0) {
      return res.status(404).json({ message: 'User was not found.' });
    }

    const [emailRows] = await pool.execute(
      'SELECT id FROM users WHERE email = ? AND id <> ? LIMIT 1',
      [requestedEmail, userId]
    );

    if (emailRows.length > 0) {
      return res.status(409).json({ message: 'This email has already been used.' });
    }

    const [nicknameRows] = await pool.execute(
      'SELECT id FROM users WHERE username = ? AND id <> ? LIMIT 1',
      [requestedNickname, userId]
    );

    if (nicknameRows.length > 0) {
      return res.status(409).json({ message: 'This nickname is already in use.' });
    }

    const savedProfileImage = shouldUpdateProfileImage
      ? normalizeProfileImage(profileImage)
      : existingRows[0].profile_image;

    if (requestedPassword) {
      const passwordHash = await bcrypt.hash(requestedPassword, 12);

      await pool.execute(
        'UPDATE users SET username = ?, email = ?, password_hash = ?, profile_image = ? WHERE id = ?',
        [requestedNickname, requestedEmail, passwordHash, savedProfileImage, userId]
      );
    } else {
      await pool.execute('UPDATE users SET username = ?, email = ?, profile_image = ? WHERE id = ?', [
        requestedNickname,
        requestedEmail,
        savedProfileImage,
        userId
      ]);
    }

    res.json({ message: 'User updated successfully.' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Nickname or email is already in use.' });
    }

    console.error(error);
    res.status(500).json({ message: 'Could not update user right now.' });
  }
});

app.patch('/api/users/:id/role', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);
  const { role } = req.body;

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid user.' });
  }

  if (!roles.has(role)) {
    return res.status(400).json({ message: 'Please choose a valid role.' });
  }

  try {
    await ensureDatabaseShapeReady();

    const [result] = await pool.execute('UPDATE users SET role = ? WHERE id = ?', [role, userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User was not found.' });
    }

    res.json({ message: 'Role updated successfully.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not update role right now.' });
  }
});

app.delete('/api/users/:id', requireAdmin, async (req, res) => {
  const userId = Number(req.params.id);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ message: 'Please choose a valid user.' });
  }

  try {
    const [result] = await pool.execute('DELETE FROM users WHERE id = ?', [userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'User was not found.' });
    }

    res.json({ message: 'User deleted successfully.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not delete user right now.' });
  }
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Please enter your nickname and password.' });
  }

  try {
    await ensureDatabaseShapeReady();

    const [rows] = await pool.execute(
      'SELECT id, username, email, password_hash, role, profile_image FROM users WHERE username = ?',
      [username.trim()]
    );

    const user = rows[0];
    if (!user) {
      return res.status(401).json({ message: 'Invalid nickname or password.' });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid nickname or password.' });
    }

    if (Number(user.isBlocked) === 1) {
      return res.status(403).json({ message: activeBlockMessage(user) });
    }

    res.json({
      message: 'Logged in successfully.',
      user: {
        id: user.id,
        nickname: user.username,
        email: user.email,
        role: user.role,
        profileImage: user.profile_image
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Could not log in right now.' });
  }
});

if (fs.existsSync(adminSitePath)) {
  app.use(express.static(adminSitePath));

  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api/')) {
      return next();
    }

    res.sendFile(path.join(adminSitePath, 'index.html'));
  });
}

await ensureDatabaseShape();

const server = app.listen(port, host, () => {
  console.log(`Server running on http://${host}:${port}`);
});

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(
      `Port ${port} is already in use. Stop the running server or start this one with a different PORT.`
    );
    process.exit(1);
  }

  if (error.code === 'EPERM') {
    console.error(
      `This computer blocked the server from opening ${host}:${port}. Try another port or check local development permissions.`
    );
    process.exit(1);
  }

  throw error;
});
