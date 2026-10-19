import { Router } from "../http/router.js";
import { createAdminAuthRoutes } from "./adminAuthRoutes.js";
import { createAdminReportsRoutes } from "./adminReportsRoutes.js";
import { createAdminParentsRoutes } from "./adminParentsRoutes.js";
import { createAdminStorageRoutes } from "./adminStorageRoutes.js";

export function createAdminRoutes() {
  const router = new Router();
  router.use(createAdminAuthRoutes());
  router.use(createAdminReportsRoutes());
  router.use(createAdminParentsRoutes());
  router.use(createAdminStorageRoutes());
  return router;
}
