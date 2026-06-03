#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
BACKUP_FILE="${1:-$PROJECT_DIR/database/care_portal_backup.sql}"
MYSQL="/usr/local/mysql/bin/mysql"
MYSQLADMIN="/usr/local/mysql/bin/mysqladmin"

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

if [[ ! -x "$MYSQL" || ! -x "$MYSQLADMIN" ]]; then
  echo "MySQL tools were not found at /usr/local/mysql/bin."
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Backup file not found:"
  echo "$BACKUP_FILE"
  echo
  echo "Copy the old computer's dump to:"
  echo "$PROJECT_DIR/database/care_portal_backup.sql"
  exit 1
fi

if ! "$MYSQLADMIN" ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --silent >/dev/null 2>&1; then
  echo "MySQL is not running or is not reachable at $DB_HOST:$DB_PORT."
  echo "Start it with:"
  echo "sudo /usr/local/mysql/support-files/mysql.server start"
  exit 1
fi

echo "Importing $BACKUP_FILE into MySQL at $DB_HOST:$DB_PORT..."
"$MYSQL" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p < "$BACKUP_FILE"

echo
echo "Import complete. Showing recent users from $DB_NAME:"
"$MYSQL" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p -e "USE $DB_NAME; SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC LIMIT 10;"

