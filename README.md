# Care Portal Auth App

This project has a Vue + Vite frontend, a Node.js + Express backend, and a MySQL users table for sign up and log in.

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

4. Update `.env` with your MySQL username and password. Keep `HOST=127.0.0.1` for local development.

## Run

Start the backend:

```bash
npm run server
```

The backend uses port `3002` by default so it does not conflict with older servers on `3000` or `3001`.

In another terminal, start the frontend:

```bash
npm run dev
```

Open the frontend at:

```text
http://localhost:5173/
```

The frontend sends sign-up, log-in, profile, and user-list requests through `/api`. Vite proxies `/api` to the backend during local development.
