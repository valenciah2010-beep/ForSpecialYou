import Koa from 'koa';
import { serverConfig } from './config.js';
import { Router } from './http/router.js';
import { corsMiddleware } from './middleware/cors.js';
import { jsonBodyParser } from './middleware/bodyParser.js';
import { staticSiteMiddleware } from './middleware/staticSite.js';
import { createAdminRoutes } from './routes/adminRoutes.js';
import { createAppRoutes } from './routes/appRoutes.js';
import { createUserRoutes } from './routes/userRoutes.js';

export function createServerApp() {
  const app = new Koa();
  const router = new Router();
  app.proxy = true;

  router.get('/api/health', (ctx) => {
    ctx.body = { ok: true };
  });
  router.use(createAdminRoutes());
  router.use(createUserRoutes());
  router.use(createAppRoutes());

  app.use(corsMiddleware(serverConfig.corsOrigins));
  app.use(jsonBodyParser({ limitBytes: 20 * 1024 * 1024 }));
  app.use(router.middleware());
  app.use(staticSiteMiddleware(serverConfig.adminSitePath));
  app.use((ctx) => {
    if (ctx.path.startsWith('/api/')) {
      ctx.status = 404;
      ctx.body = { message: 'API route was not found.' };
    }
  });

  return app;
}
