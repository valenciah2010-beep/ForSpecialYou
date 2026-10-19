import { Router } from "../http/router.js";
import { createAppAuthRoutes } from "./appAuthRoutes.js";
import { createAppDataRoutes } from "./appDataRoutes.js";
import { createAppAIRoutes } from "./appAIRoutes.js";

export function createAppRoutes() {
  const router = new Router();
  router.use(createAppAuthRoutes());
  router.use(createAppDataRoutes());
  router.use(createAppAIRoutes());
  return router;
}
