import fs from "node:fs/promises";
import { pool } from "./db.js";
import { cleanupUploads } from "./services/uploads.js";
import { createServerApp } from "./app.js";
import { serverConfig } from "./config.js";
import { cleanupExpiredAdminSessions } from "./services/adminSession.js";
import { validateEnvironment } from "./config.js";

validateEnvironment();

const [applied] = await pool.execute(
  "SELECT name FROM schema_migrations ORDER BY name",
);
const requiredMigrations = (
  await fs.readdir(new URL("../migrations/", import.meta.url))
).filter((name) => /^\d+_.+\.sql$/.test(name));
if (
  requiredMigrations.some((name) => !applied.some((row) => row.name === name))
)
  throw new Error(
    "Database migrations are missing. Run npm run db:init before startup.",
  );
const app = createServerApp();
const server = app.listen(serverConfig.port, serverConfig.host, () => {
  console.log(
    `Server running on http://${serverConfig.host}:${serverConfig.port}`,
  );
});

const adminSessionCleanupTimer = setInterval(
  () =>
    cleanupExpiredAdminSessions().catch((error) =>
      console.error(error.message),
    ),
  60 * 60 * 1000,
);
adminSessionCleanupTimer.unref?.();

server.on("error", (error) => {
  if (error.code === "EADDRINUSE") {
    console.error(
      `Port ${serverConfig.port} is already in use. Stop the running server or start this one with a different PORT.`,
    );
    process.exit(1);
  }

  if (error.code === "EPERM") {
    console.error(
      `This computer blocked the server from opening ${serverConfig.host}:${serverConfig.port}. Try another port or check local development permissions.`,
    );
    process.exit(1);
  }

  throw error;
});

const uploadCleanupTimer = setInterval(
  () =>
    cleanupUploads().catch((error) =>
      console.error("Upload cleanup failed:", error.code || error.name),
    ),
  3600000,
);
uploadCleanupTimer.unref();
for (const signal of ["SIGTERM", "SIGINT"])
  process.once(signal, () => {
    clearInterval(adminSessionCleanupTimer);
    clearInterval(uploadCleanupTimer);
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
  });
