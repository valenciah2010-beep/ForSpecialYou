#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/server/.env"
BACKUP_FILE="${1:-$PROJECT_DIR/tmp/database-exports/care_portal_backup.sql}"
MYSQL="${MYSQL_BINARY:-$(command -v mysql || true)}"
MYSQL="${MYSQL:-/usr/local/mysql/bin/mysql}"

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USER="root"
DB_NAME="care_portal"

if [[ -f "$ENV_FILE" ]]; then
  DB_HOST="$(awk -F= '/^DB_HOST=/{print $2}' "$ENV_FILE" | tail -n 1)"
  DB_PORT="$(awk -F= '/^DB_PORT=/{print $2}' "$ENV_FILE" | tail -n 1)"
  DB_USER="$(awk -F= '/^DB_USER=/{print $2}' "$ENV_FILE" | tail -n 1)"
  DB_NAME="$(awk -F= '/^DB_NAME=/{print $2}' "$ENV_FILE" | tail -n 1)"
fi

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-care_portal}"

if [[ ! -x "$MYSQL" ]]; then
  echo "Install mysql or set MYSQL_BINARY to its executable path."
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Backup file not found:"
  echo "$BACKUP_FILE"
  echo
  echo "Copy the old computer's dump to:"
  echo "$PROJECT_DIR/tmp/database-exports/care_portal_backup.sql"
  exit 1
fi

echo "Importing $BACKUP_FILE into MySQL at $DB_HOST:$DB_PORT..."
"$MYSQL" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p < "$BACKUP_FILE"

echo
echo "Import complete. Run npm run db:init before starting the API."

