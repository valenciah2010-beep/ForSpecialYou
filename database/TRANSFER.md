# Database transfer

Backups contain private care records. Transfer them through an encrypted channel and keep them outside version control.

1. Configure connection fields in `server/.env` on each computer. The scripts prompt for the database password; they do not print it or pass it as a command argument.
2. Export from the old installation: `bash database/export-care-portal.sh`. The default output is `tmp/database-exports/care_portal_backup.sql`; an explicit output path can be passed as the first argument. Copy the dump to the same ignored directory on the new machine.
3. Back up the destination database before restoring. A full dump may replace existing tables and records. Restore only into the intended instance: `bash database/import-backup.sh`.
4. Run `npm run db:init` to apply recorded schema upgrades. Then run `npm run dev` to start both the API and admin portal.

The scripts find MySQL clients on PATH, with `/usr/local/mysql/bin` as a fallback. Set `MYSQL_BINARY` or `MYSQLDUMP_BINARY` for another installation. They read `DB_HOST`, `DB_PORT`, `DB_USER` and `DB_NAME` from `server/.env` as simple unquoted values; confirm these before importing. They do not start or stop database services.
