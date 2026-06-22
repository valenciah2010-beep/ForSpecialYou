import { createServerApp } from './app.js';
import { serverConfig } from './config.js';
import { cleanupExpiredAdminSessions } from './services/adminSession.js';
import { ensureDatabaseShape } from './services/databaseShape.js';

await ensureDatabaseShape();

const app = createServerApp();
const server = app.listen(serverConfig.port, serverConfig.host, () => {
  console.log(`Server running on http://${serverConfig.host}:${serverConfig.port}`);
});

const adminSessionCleanupTimer = setInterval(cleanupExpiredAdminSessions, 60 * 60 * 1000);
adminSessionCleanupTimer.unref?.();

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(
      `Port ${serverConfig.port} is already in use. Stop the running server or start this one with a different PORT.`
    );
    process.exit(1);
  }

  if (error.code === 'EPERM') {
    console.error(
      `This computer blocked the server from opening ${serverConfig.host}:${serverConfig.port}. Try another port or check local development permissions.`
    );
    process.exit(1);
  }

  throw error;
});
