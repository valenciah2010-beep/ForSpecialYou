import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import mysql from "mysql2/promise";
import { startS3Fixture } from "../test/helpers/s3Fixture.js";
const directory = await fs.mkdtemp(path.join(os.tmpdir(), "fsy-test-"));
const socket = path.join(directory, "mysql.sock");
const password = crypto.randomBytes(24).toString("hex");
let daemon, s3;
function run(command, args, env = process.env) {
  return new Promise((resolve, reject) => {
    const process = spawn(command, args, {
      env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let output = "";
    process.stdout.on("data", (chunk) => {
      output += chunk;
    });
    process.stderr.on("data", (chunk) => {
      output += chunk;
    });
    process.on("error", reject);
    process.on("close", (code) =>
      code === 0 ? resolve(output) : reject(new Error(output)),
    );
  });
}
try {
  let binary = process.env.MYSQLD_BINARY;
  if (!binary)
    for (const candidate of [
      "/opt/homebrew/opt/mysql/bin/mysqld",
      "/usr/local/mysql/bin/mysqld",
      "/usr/sbin/mysqld",
    ]) {
      if (
        await fs.access(candidate).then(
          () => true,
          () => false,
        )
      ) {
        binary = candidate;
        break;
      }
    }
  if (!binary)
    throw new Error(
      "Set MYSQLD_BINARY to a local MySQL server executable. Integration tests use an isolated temporary database.",
    );
  await run(binary, [
    "--no-defaults",
    "--initialize-insecure",
    "--datadir=" + path.join(directory, "data"),
  ]);
  daemon = spawn(
    binary,
    [
      "--no-defaults",
      "--datadir=" + path.join(directory, "data"),
      "--socket=" + socket,
      "--skip-networking",
      "--mysqlx=0",
      "--pid-file=" + path.join(directory, "mysql.pid"),
      "--log-error=" + path.join(directory, "mysql.log"),
    ],
    { stdio: "ignore" },
  );
  let connection;
  for (let n = 0; n < 100; n++) {
    try {
      connection = await mysql.createConnection({
        socketPath: socket,
        user: "root",
      });
      break;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!connection) throw new Error("Temporary MySQL did not start.");
  await connection.query("ALTER USER 'root'@'localhost' IDENTIFIED BY ?", [
    password,
  ]);
  await connection.end();
  const env = {
    ...process.env,
    NODE_ENV: "test",
    DB_HOST: "127.0.0.1",
    DB_SOCKET: socket,
    DB_USER: "root",
    DB_PASSWORD: password,
    DB_NAME: "care_portal_test",
    AI_PROCESSING_ENABLED: "false",
    UPLOAD_DIR: path.join(directory, "uploads"),
    // Never inherit real object storage credentials into destructive fixture tests.
    IMAGE_STORAGE: "local",
    R2_ACCESS_KEY_ID: "",
    R2_SECRET_ACCESS_KEY: "",
  };
  s3 = await startS3Fixture();
  for (const storage of ["local", "r2"]) {
    const testEnv = {
      ...env,
      DB_NAME: "care_portal_test_" + storage,
      IMAGE_STORAGE: storage,
      R2_ENDPOINT: s3.settings.endpoint,
      R2_BUCKET: s3.settings.bucket,
      R2_ACCESS_KEY_ID: s3.settings.accessKeyId,
      R2_SECRET_ACCESS_KEY: s3.settings.secretAccessKey,
      R2_PREFIX: "forspecialyou-test/uploads/",
    };
    console.log("Storage integration: " + storage);
    console.log(
      (await run(process.execPath, ["scripts/migrate.js"], testEnv)).trim(),
    );
    // Second application proves migration history makes reruns safe.
    await run(process.execPath, ["scripts/migrate.js"], testEnv);
    console.log(
      await run(
        process.execPath,
        ["--test", "test/security.integration.js"],
        testEnv,
      ),
    );
  }
} finally {
  if (s3) await s3.close();
  if (daemon) {
    const stopped = new Promise((resolve) => daemon.once("close", resolve));
    daemon.kill("SIGTERM");
    await stopped;
  }
  await fs.rm(directory, { recursive: true, force: true });
}
