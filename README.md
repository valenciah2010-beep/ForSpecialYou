# ForSpecialYou / Care Portal

Special-needs care records: Vue admin portal, Koa API, MySQL, native iOS and Android clients.

## Structure

- `admin-web/`: Vue 3 + Vite admin portal; page and dialog components, composables, shared API client.
- `server/src/`: API, authentication, image uploads, AI quotas and audit services.
- `server/migrations/`: ordered, recorded, repeatable database migrations.
- `server/scripts/`: migration runner, initial administrator and isolated integration tests.
- `ios/CarePortalSwiftUI/`: SwiftUI features grouped by Diagnosis, Health, Therapy, Nutrition and Profile.
- `android/CarePortalAndroid/`: Java native app; screen/form modules and shared API/session storage.
- `deploy/`: DeployDesk configuration, PM2, Nginx HTTP and HTTPS location snippet.
- `tmp/`: ignored test data, exports and one-time manual SQL. Never deploy this directory.

## Local development

Requires Node.js 22+, MySQL 5.7+ and a database user with access to the configured schema. A migration user additionally needs database/schema DDL permissions. The application user needs normal data access only.

```bash
npm ci
cp server/.env.example server/.env
# Configure DB_HOST, DB_PORT, DB_USER, DB_PASSWORD and DB_NAME.
npm run db:init
npm run dev
```

Ports registered in `/Users/zjy/Desktop/project/端口号管理.xlsx`: admin **5223**, API **4223**. Vite uses strictPort and proxies `/api` to the API. `npm run dev` runs the API with nodemon. The server refuses to start with missing DB credentials or unapplied migrations. No credentials are committed.

Create the first administrator by setting `ADMIN_USERNAME`, `ADMIN_EMAIL` and `ADMIN_PASSWORD` (12+ characters) in the command's environment, then running `npm run db:create-admin`. The command only creates a new account; it never resets an existing password. Do not store these one-time values in tracked files or shell history.

```bash
npm run build
npm test
npm run test:integration
```

Integration tests create and remove an isolated MySQL data directory with networking disabled. Set `MYSQLD_BINARY` if MySQL is installed outside a detected path. They never use your application database. Unit tests require no database.

## Deployment

Current topology (confirmed 2026-10-19): one US production server, `154.40.41.179`, serving all production clients at `https://fsyadmin.top`. Web uses same-origin `/api`; native Release builds use that HTTPS origin. Nginx forwards requests to `127.0.0.1:3002`, with MySQL on the same server. China/US routing, regional account assignment and `cn.fsyadmin.top` are deferred and are not active. Data is currently stored in the US. Debug builds continue to use the local development API.

DeployDesk detects workspaces `admin-web` and `server`, root `db:init`, four ordered SQL migrations, PM2 `server` and `deploy/fsyadmin.top.conf`. The existing production directory is `/www/wwwroot/default`, API port is 3002 and public HTTP port is 80.

1. Back up the current database and preserve the existing TLS configuration.
2. Install dependencies and build: `npm ci && npm run build`.
3. Configure `server/.env`; in production set `COOKIE_SECURE=true`, `PUBLIC_ORIGIN=https://fsyadmin.top`, `CORS_ORIGINS=https://fsyadmin.top`. Set `TRUST_PROXY=true` only behind the local Nginx proxy.
4. Run `npm run db:init` before restarting the API. Startup never performs `ALTER TABLE`.
5. Keep the existing HTTPS certificate configuration and include `deploy/https-locations.inc` inside that HTTPS server block. `fsyadmin.top.conf` provides the HTTP-to-HTTPS redirect. Validate with `nginx -t` before reload.
6. For this existing site publish Web files to `/www/wwwroot/default/dist`; set `ADMIN_SITE_PATH=/www/wwwroot/default/dist`. Local development continues to use ports 5223/4223. Release iOS/Android and Web use HTTPS port 443; Nginx forwards `/api/` internally to 127.0.0.1:3002.
7. This production site currently uses the hosting panel's existing Node project `server`, running `server/index.js` as `www` with Node 22.22.3. The compatibility entry forwards to `src/index.js`; `server/node_modules` links to workspace dependencies. Restart through that existing manager. The PM2 file supports DeployDesk deployments, but migrate process management explicitly before using it; never run both managers for port 3002. Preserve `server/.env` and `server/storage/` across deployments.
8. Deploy updated iOS and Android clients together. Old clients that send only `userId` will receive 401 and must update/re-login. API authentication cannot be safely made backward compatible with those requests.

AI is **disabled by default**. After confirming your privacy policy, OpenAI processing terms and operational retention requirements, configure `OPENAI_API_KEY` and `AI_PROCESSING_ENABLED=true`. Clients ask before sending photos/records. Request payloads exclude direct identity fields and free-text comments; photos and structured medical records remain sensitive. OpenAI requests use `store:false`. See [security notes](docs/SECURITY.md).

## Native clients

Private R2 storage for chunk-uploaded images is enabled in production through server-side `IMAGE_STORAGE=r2` configuration. Existing database avatars and health records remain unchanged. See [object storage configuration, retention and rollback](docs/OBJECT_STORAGE.md) and the [R2 deployment record](docs/DEPLOYMENT_2026-10-19_R2.md). Integration tests run both local and simulated S3 storage without cloud credentials.

- iOS: open the Xcode project; Debug uses `http://127.0.0.1:4223`, Release uses `https://fsyadmin.top`. Tokens are stored in Keychain.
- Android: open the Gradle project; Debug uses `http://10.0.2.2:4223`, Release uses HTTPS. Session tokens are encrypted with Android Keystore. `local.properties`, `.gradle` and signing files stay local.
- Physical-device development requires a reachable LAN address and backend bind address. Restrict cleartext exceptions to local development; never change Release to HTTP.

No real AI calls or external deployment are part of the test suite. See [local validation results and remaining limits](docs/VALIDATION.md) and the [production deployment record](docs/DEPLOYMENT_2026-10-14.md).
