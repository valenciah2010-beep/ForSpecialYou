import bcrypt from "bcryptjs";
import { pool } from "../src/db.js";
import { validateEnvironment } from "../src/config.js";
import { isValidEmail } from "../src/utils/validators.js";
validateEnvironment();
const { ADMIN_USERNAME, ADMIN_EMAIL, ADMIN_PASSWORD } = process.env;
if (
  !ADMIN_USERNAME ||
  !ADMIN_EMAIL ||
  !ADMIN_PASSWORD ||
  ADMIN_PASSWORD.length < 12 ||
  Buffer.byteLength(ADMIN_PASSWORD, "utf8") > 72 ||
  ADMIN_USERNAME.length > 80 ||
  ADMIN_EMAIL.length > 255 ||
  !isValidEmail(ADMIN_EMAIL)
)
  throw new Error(
    "Set a valid ADMIN_USERNAME, ADMIN_EMAIL and ADMIN_PASSWORD (12+ characters, at most 72 UTF-8 bytes) for this command.",
  );
try {
  await pool.execute(
    "INSERT INTO users (username,email,password_hash,role) VALUES (?,?,?,'admin')",
    [ADMIN_USERNAME, ADMIN_EMAIL, await bcrypt.hash(ADMIN_PASSWORD, 12)],
  );
  console.log("Admin created.");
} finally {
  await pool.end();
}
