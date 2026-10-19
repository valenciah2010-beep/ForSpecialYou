# Security and operations

## Sessions and access

Parents authenticate with a random 256-bit bearer token. MySQL stores only its SHA-256 hash, account, purpose and expiry (30 days). Every protected request rechecks role and block status. Caller-supplied userId must match the authenticated parent. Admin sessions expire after 12 hours and use HttpOnly, SameSite=Lax cookies with Secure in production. Cookie mutations also require a trusted Origin and the custom CarePortal header. Deploy the admin frontend and API on the same origin.

Password changes revoke all account sessions; role changes and blocks take effect on the next request. Logout revokes the current token. Existing legacy login state intentionally cannot be upgraded without a password. Client health logs remain in app-local storage; device access policies and OS encryption should be considered when distributing devices.

## AI and data handling

AI processing requires operator configuration and explicit client consent. Profile/contact fields and free-text notes are excluded from generated prompts. Structured medical categories, measurements and selected photos still leave the service for OpenAI processing. `store:false` disables storing generated Responses objects; it does not promise zero provider retention. The operator must publish accurate privacy terms and configure retention with the provider.

MySQL enforces per-account UTC-day quotas (meal default 3, insights 20, admin reports 10). The account row is locked during reservation to prevent multiple devices overspending. The server ignores client counters. Attempts reserve quota immediately before provider calls; failed provider calls also consume an attempt to prevent retry abuse. Rate limits are shared in MySQL; default global AI concurrency is two per process and PM2 is configured for one instance. Requests time out after 45 seconds. Audit rows contain actor/action/target/time, never prompts, images or health records.

## Files and retention

Uploads accept up to 20 MiB in 512 KiB resumable chunks, with owner isolation, exact chunk lengths and SHA-256 verification. Decoding rejects unsupported content and images exceeding 24 million pixels. JPEG re-encoding strips metadata and limits output to 2048 pixels. Files are private and served through authentication. Up to 100 active uploads / 100 MiB source bytes per account are allowed. Incomplete uploads default to 24 hours; completed analysis images default to 30 days. Administrators can change both values in the Storage page, including permanent completed-file retention, and can explicitly recalculate existing active records. An hourly job removes expired files and orphaned files left by account deletion. Preserve the storage directory across deployments. Raw chunks remain private until expiry to support retry-safe completion. Small, resized avatars remain inline for native-client compatibility and are validated and re-encoded on write.

Use encrypted volumes/backups and restrict filesystem and database access. Backups may contain health records and require the same access controls. Audit and daily quota retention should be scheduled by the operator; this change does not erase historical business records or existing backups automatically. Stored user health data currently remains as JSON snapshots; simultaneous changes to the same collection still use last-write-wins and should be migrated to record-level synchronization before concurrent editing is offered.

## Release checks

Run build, unit tests, isolated integration tests and native compiles before rollout. Back up and apply migrations first; release the API and updated clients in one maintenance window. Confirm unauthenticated data/AI requests return 401 and login/AI throttles return 429. Test with real device photos and your configured provider in staging before enabling AI for users.
