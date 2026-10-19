import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import mysql from "mysql2/promise";
import { validateEnvironment } from "../src/config.js";
validateEnvironment();
const dbName = process.env.DB_NAME;
if (!/^[a-zA-Z0-9_]+$/.test(dbName)) throw new Error("Invalid DB_NAME.");
const connection = await mysql.createConnection({
  socketPath: process.env.DB_SOCKET || undefined,
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  multipleStatements: true,
});
try {
  await connection.query(
    "CREATE DATABASE IF NOT EXISTS `" +
      dbName +
      "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci",
  );
  await connection.changeUser({ database: dbName });
  const [[lock]] = await connection.query(
    "SELECT GET_LOCK(?, 30) AS acquired",
    ["forspecialyou:migrate:" + dbName],
  );
  if (Number(lock.acquired) !== 1)
    throw new Error("Migration is already running.");
  await connection.query(
    "CREATE TABLE IF NOT EXISTS schema_migrations (name VARCHAR(255) PRIMARY KEY, checksum CHAR(64) NOT NULL, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
  );
  const directory = fileURLToPath(new URL("../migrations/", import.meta.url));
  for (const name of (await fs.readdir(directory))
    .filter((f) => /^\d+_.+\.sql$/.test(f))
    .sort()) {
    const sql = await fs.readFile(path.join(directory, name), "utf8");
    const checksum = crypto.createHash("sha256").update(sql).digest("hex");
    const [rows] = await connection.execute(
      "SELECT checksum FROM schema_migrations WHERE name = ?",
      [name],
    );
    if (rows[0]) {
      if (rows[0].checksum !== checksum)
        throw new Error("Previously applied migration changed: " + name);
      continue;
    }
    await connection.query(sql);
    await connection.execute(
      "INSERT INTO schema_migrations (name,checksum) VALUES (?,?)",
      [name, checksum],
    );
    console.log("Applied " + name);
  }
} finally {
  await connection.end();
}
