import bcrypt from 'bcryptjs';
import { pool } from '../db.js';
import { Router } from '../http/router.js';
import { getAdminUser, requireAdmin } from '../services/adminSession.js';
import { ensureDatabaseShapeReady } from '../services/databaseShape.js';
import { isValidEmail, isValidPassword, roles } from '../utils/validators.js';
import { blockFieldsSQL, normalizeProfileImage } from '../utils/users.js';

export function createUserRoutes() {
  const router = new Router();

  router.get('/api/users', requireAdmin, async (ctx) => {
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

      ctx.body = { users: rows };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not load users right now.' };
    }
  });

  router.get('/api/users/:id', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid user.' };
      return;
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
        ctx.status = 404;
        ctx.body = { message: 'User was not found.' };
        return;
      }

      ctx.body = { user };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not load user right now.' };
    }
  });

  router.post('/api/signup', async (ctx) => {
    const { nickname, username, password, verifyPassword, email, role } = ctx.request.body || {};
    const requestedNickname = (nickname || username || '').trim();
    const requestedEmail = (email || '').trim().toLowerCase();
    const requestedRole = role || 'parent';

    if (!requestedNickname || !password || !verifyPassword || !requestedEmail || !requestedRole) {
      ctx.status = 400;
      ctx.body = { message: 'Please fill out every field.' };
      return;
    }

    if (!isValidEmail(requestedEmail)) {
      ctx.status = 400;
      ctx.body = { message: 'Please enter a valid email address.' };
      return;
    }

    if (!isValidPassword(password)) {
      ctx.status = 400;
      ctx.body = { message: 'Password must be at least 6 characters and include one number.' };
      return;
    }

    if (password !== verifyPassword) {
      ctx.status = 400;
      ctx.body = { message: 'Passwords do not match.' };
      return;
    }

    if (!roles.has(requestedRole)) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid account type.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();
      const adminUser = await getAdminUser(ctx);

      if (!adminUser && requestedRole !== 'parent') {
        ctx.status = 403;
        ctx.body = { message: 'Only admins can create non-parent accounts.' };
        return;
      }

      const [emailRows] = await pool.execute('SELECT id FROM users WHERE email = ? LIMIT 1', [
        requestedEmail
      ]);

      if (emailRows.length > 0) {
        ctx.status = 409;
        ctx.body = { message: 'This email has already been used.' };
        return;
      }

      const [nicknameRows] = await pool.execute('SELECT id FROM users WHERE username = ? LIMIT 1', [
        requestedNickname
      ]);

      if (nicknameRows.length > 0) {
        ctx.status = 409;
        ctx.body = { message: 'This nickname is already in use.' };
        return;
      }

      const passwordHash = await bcrypt.hash(password, 12);

      await pool.execute(
        'INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
        [requestedNickname, requestedEmail, passwordHash, requestedRole]
      );

      ctx.status = 201;
      ctx.body = { message: 'Account created successfully.' };
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        ctx.status = 409;
        ctx.body = { message: 'Nickname or email is already in use.' };
        return;
      }

      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not create account right now.' };
    }
  });

  router.put('/api/users/:id', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);
    const { nickname, username, email, password, profileImage } = ctx.request.body || {};
    const requestedNickname = (nickname || username || '').trim();
    const requestedEmail = (email || '').trim().toLowerCase();
    const requestedPassword = (password || '').trim();
    const shouldUpdateProfileImage = Object.prototype.hasOwnProperty.call(ctx.request.body || {}, 'profileImage');

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid user.' };
      return;
    }

    if (!requestedNickname || !requestedEmail) {
      ctx.status = 400;
      ctx.body = { message: 'Please fill out nickname and email.' };
      return;
    }

    if (!isValidEmail(requestedEmail)) {
      ctx.status = 400;
      ctx.body = { message: 'Please enter a valid email address.' };
      return;
    }

    if (requestedPassword && !isValidPassword(requestedPassword)) {
      ctx.status = 400;
      ctx.body = { message: 'Password must be at least 6 characters and include one number.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

      const [existingRows] = await pool.execute(
        'SELECT id, profile_image FROM users WHERE id = ? LIMIT 1',
        [userId]
      );

      if (existingRows.length === 0) {
        ctx.status = 404;
        ctx.body = { message: 'User was not found.' };
        return;
      }

      const [emailRows] = await pool.execute(
        'SELECT id FROM users WHERE email = ? AND id <> ? LIMIT 1',
        [requestedEmail, userId]
      );

      if (emailRows.length > 0) {
        ctx.status = 409;
        ctx.body = { message: 'This email has already been used.' };
        return;
      }

      const [nicknameRows] = await pool.execute(
        'SELECT id FROM users WHERE username = ? AND id <> ? LIMIT 1',
        [requestedNickname, userId]
      );

      if (nicknameRows.length > 0) {
        ctx.status = 409;
        ctx.body = { message: 'This nickname is already in use.' };
        return;
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

      ctx.body = { message: 'User updated successfully.' };
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        ctx.status = 409;
        ctx.body = { message: 'Nickname or email is already in use.' };
        return;
      }

      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not update user right now.' };
    }
  });

  router.patch('/api/users/:id/role', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);
    const { role } = ctx.request.body || {};

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid user.' };
      return;
    }

    if (!roles.has(role)) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid role.' };
      return;
    }

    try {
      await ensureDatabaseShapeReady();

      const [result] = await pool.execute('UPDATE users SET role = ? WHERE id = ?', [role, userId]);

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: 'User was not found.' };
        return;
      }

      ctx.body = { message: 'Role updated successfully.' };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not update role right now.' };
    }
  });

  router.delete('/api/users/:id', requireAdmin, async (ctx) => {
    const userId = Number(ctx.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      ctx.status = 400;
      ctx.body = { message: 'Please choose a valid user.' };
      return;
    }

    try {
      const [result] = await pool.execute('DELETE FROM users WHERE id = ?', [userId]);

      if (result.affectedRows === 0) {
        ctx.status = 404;
        ctx.body = { message: 'User was not found.' };
        return;
      }

      ctx.body = { message: 'User deleted successfully.' };
    } catch (error) {
      console.error(error);
      ctx.status = 500;
      ctx.body = { message: 'Could not delete user right now.' };
    }
  });

  return router;
}
