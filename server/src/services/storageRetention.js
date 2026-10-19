import { pool } from "../db.js";

export const ACTIVE_UPLOAD_SQL =
  "(expires_at IS NULL OR expires_at > UTC_TIMESTAMP())";
function badRequest(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  return error;
}
export function validateRetentionPolicy(body) {
  if (
    !body ||
    !Number.isInteger(body.incompleteHours) ||
    body.incompleteHours < 1 ||
    body.incompleteHours > 720
  )
    throw badRequest("Unfinished uploads must be kept for 1–720 whole hours.");
  if (
    body.completedDays !== null &&
    (!Number.isInteger(body.completedDays) ||
      body.completedDays < 1 ||
      body.completedDays > 36500)
  )
    throw badRequest(
      "Completed files require 1–36500 whole days, or permanent storage.",
    );
  if (
    !Number.isInteger(body.revision) ||
    body.revision < 1 ||
    body.revision >= 4294967295
  )
    throw badRequest("Reload the current settings before saving.");
  if (typeof body.applyToExisting !== "boolean")
    throw badRequest("Choose whether to update existing files.");
  return {
    incompleteHours: body.incompleteHours,
    completedDays: body.completedDays,
    revision: body.revision,
    applyToExisting: body.applyToExisting,
  };
}
function publicPolicy(row) {
  return {
    incompleteHours: row.incomplete_hours,
    completedDays: row.completed_days,
    revision: row.revision,
  };
}
export async function getRetentionPolicy(connection = pool, lock = false) {
  const [[row]] = await connection.execute(
    "SELECT * FROM storage_retention_policy WHERE id=1" +
      (lock ? " FOR UPDATE" : ""),
  );
  if (!row) throw badRequest("Storage settings are not initialized.", 503);
  return publicPolicy(row);
}
export async function getStorageSettings() {
  const policy = await getRetentionPolicy();
  const [[usage]] = await pool.query(`SELECT
    COALESCE(SUM(completed=0),0) AS incomplete,
    COALESCE(SUM(completed=1),0) AS completed,
    COALESCE(SUM(completed=1 AND expires_at IS NULL),0) AS permanent
    FROM image_uploads WHERE ${ACTIVE_UPLOAD_SQL}`);
  return {
    policy,
    usage: Object.fromEntries(
      Object.entries(usage).map(([key, value]) => [key, Number(value)]),
    ),
  };
}
export async function saveRetentionPolicy(body, actorId) {
  const policy = validateRetentionPolicy(body);
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const current = await getRetentionPolicy(connection, true);
    if (current.revision !== policy.revision)
      throw badRequest(
        "Settings changed in another session. Reload before saving.",
        409,
      );
    await connection.execute(
      "UPDATE storage_retention_policy SET incomplete_hours=?,completed_days=?,revision=revision+1,updated_by=?,updated_at=UTC_TIMESTAMP() WHERE id=1",
      [policy.incompleteHours, policy.completedDays, actorId],
    );
    let affected = 0;
    if (policy.applyToExisting) {
      // Expired resources cannot be revived while deletion may already be in flight.
      const [pending] = await connection.execute(
        `UPDATE image_uploads
        SET expires_at=DATE_ADD(COALESCE(retention_started_at,created_at), INTERVAL ? HOUR)
        WHERE completed=0 AND ${ACTIVE_UPLOAD_SQL}`,
        [policy.incompleteHours],
      );
      const [completed] = await connection.execute(
        `UPDATE image_uploads
        SET expires_at=IF(? IS NULL,NULL,DATE_ADD(COALESCE(retention_started_at,created_at), INTERVAL ? DAY))
        WHERE completed=1 AND ${ACTIVE_UPLOAD_SQL}`,
        [policy.completedDays, policy.completedDays],
      );
      affected = pending.affectedRows + completed.affectedRows;
    }
    await connection.execute(
      "INSERT INTO audit_events (actor_id,action) VALUES (?,?)",
      [
        actorId,
        `Storage: ${policy.incompleteHours}h/${policy.completedDays === null ? "permanent" : policy.completedDays + "d"}; existing=${policy.applyToExisting}`,
      ],
    );
    await connection.commit();
    return {
      policy: {
        incompleteHours: policy.incompleteHours,
        completedDays: policy.completedDays,
        revision: current.revision + 1,
      },
      affected,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

export async function completeUploadRetention(id, userId) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const policy = await getRetentionPolicy(connection, true);
    const [[upload]] = await connection.execute(
      `SELECT completed FROM image_uploads WHERE id=? AND user_id=? AND ${ACTIVE_UPLOAD_SQL} FOR UPDATE`,
      [id, userId],
    );
    if (!upload)
      throw badRequest(
        "Upload expired or was deleted. Start a new upload.",
        404,
      );
    if (!upload.completed)
      await connection.execute(
        `UPDATE image_uploads SET completed=1,retention_started_at=UTC_TIMESTAMP(),
      expires_at=IF(? IS NULL,NULL,DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? DAY)) WHERE id=?`,
        [policy.completedDays, policy.completedDays, id],
      );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}
