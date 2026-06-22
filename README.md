# Care Portal Auth App

This project has a Vue + Vite frontend, a Node.js + Koa2 backend, and a MySQL users table for sign up and log in.

## Setup

1. Install packages:

   ```bash
   npm install
   ```

2. Create the MySQL database and table:

   ```bash
   npm run db:setup
   ```

   If you already created the database before the admin role was added, update the role column:

   ```bash
   /usr/local/mysql/bin/mysql -h 127.0.0.1 -P 3306 -u root -proot123456 < database/add-admin-role.sql
   ```

   If you already created the database before profile images were added, update the users table:

   ```bash
   /usr/local/mysql/bin/mysql -h 127.0.0.1 -P 3306 -u root -proot123456 < database/add-profile-image.sql
   ```

   If MySQL is not running yet, start it first:

   ```bash
   sudo /usr/local/mysql/support-files/mysql.server start
   ```

   If MySQL says it quit without updating the PID file, repair the data folder ownership and remove any stale PID file:

   ```bash
   sudo chown -R _mysql:_mysql /usr/local/mysql/data
   sudo rm -f /usr/local/mysql/data/*.pid
   sudo /usr/local/mysql/support-files/mysql.server start
   ```

   To see the exact MySQL startup error:

   ```bash
   sudo tail -80 /usr/local/mysql/data/*.err
   ```

3. Create a `.env` file from the example:

   ```bash
   cp .env.example .env
   ```

4. Update `.env` with your MySQL username and password.
   - For local backend development, keep `HOST=127.0.0.1`, `PORT=3002`, `COOKIE_SECURE=false`, and leave `VITE_API_BASE_URL` empty.
   - For server deployment behind Nginx, use `HOST=127.0.0.1`, `PORT=3002`, `PUBLIC_ORIGIN=https://fsyadmin.top`, and `COOKIE_SECURE=true`.

## Run

Start the backend:

```bash
npm run server
```

The backend uses port `3002` by default so it does not conflict with older servers on `3000` or `3001`.
If you do not create a `.env` file, the backend still defaults to `3002`.

In another terminal, start the frontend:

```bash
npm run dev
```

Open the frontend at:

```text
http://localhost:5173/
```

The frontend is now an admin-only portal. Log in with a user whose role is `admin` to view simulator app users.
During local Vite development, `/api` is proxied to `http://127.0.0.1:3002`.
Production builds call `https://fsyadmin.top` by default. Override `VITE_API_BASE_URL` only if you intentionally want a different backend.

Simulator app parent sign-up and log-in still use the backend API, but website user-list and user-management routes require an admin session.

## fsyadmin.top Deployment

Build the admin site and run the Koa backend on the server:

```bash
npm install
npm run build
PORT=3002 HOST=127.0.0.1 PUBLIC_ORIGIN=https://fsyadmin.top COOKIE_SECURE=true npm run server
```

Point Nginx for `fsyadmin.top` to the Koa backend on `127.0.0.1:3002`. The backend serves the built admin site from `dist` and all `/api/*` routes from the same origin.

## Structure

- `server/app.js` creates the Koa app and mounts middleware/routes.
- `server/routes/` contains admin, app, and user API route groups.
- `server/services/` contains database shape checks, admin sessions, OpenAI response handling, and report record shaping.
- `src/composables/` contains portal state and UI state helpers.
- `src/components/` contains reusable page panels, layout, and parent-history presentation.
- `src/utils/` contains date, validation, and history formatting helpers.
