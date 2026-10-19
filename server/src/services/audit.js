import { pool } from "../db.js";
export async function auditEvent(actorId, action, targetId = null) {
  await pool.execute(
    "INSERT INTO audit_events (actor_id,action,target_id) VALUES (?,?,?)",
    [actorId, action, targetId],
  );
}
export async function auditAdminMutations(ctx, next) {
  await next();
  if (
    ctx.state.adminUser &&
    ["POST", "PUT", "PATCH", "DELETE"].includes(ctx.method) &&
    ctx.status < 400
  ) {
    await auditEvent(
      ctx.state.adminUser.id,
      `${ctx.method} ${ctx.path.replace(/\/\d+(?=\/|$)/g, "/:id")}`.slice(
        0,
        80,
      ),
      ctx.state.auditTargetId || Number(ctx.params?.id) || null,
    );
  }
}
