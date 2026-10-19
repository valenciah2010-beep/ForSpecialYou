import { Router } from "../http/router.js";
import { requireAdmin } from "../services/adminSession.js";
import {
  getStorageSettings,
  saveRetentionPolicy,
} from "../services/storageRetention.js";

export function createAdminStorageRoutes() {
  const router = new Router();
  router.get("/api/admin/settings/storage", requireAdmin, async (ctx) => {
    ctx.body = await getStorageSettings();
  });
  router.put("/api/admin/settings/storage", requireAdmin, async (ctx) => {
    ctx.body = await saveRetentionPolicy(
      ctx.request.body,
      ctx.state.adminUser.id,
    );
  });
  return router;
}
