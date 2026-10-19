#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/server/.env"
OUTPUT_FILE="${1:-$PROJECT_DIR/tmp/database-exports/care_portal_backup.sql}"
MYSQLDUMP="${MYSQLDUMP_BINARY:-$(command -v mysqldump || true)}"
MYSQLDUMP="${MYSQLDUMP:-/usr/local/mysql/bin/mysqldump}"

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

if [[ ! -x "$MYSQLDUMP" ]]; then
  echo "Install mysqldump or set MYSQLDUMP_BINARY to its executable path."
  exit 1
fi

echo "Exporting database $DB_NAME from $DB_HOST:$DB_PORT..."
mkdir -p "$(dirname "$OUTPUT_FILE")"
umask 077
"$MYSQLDUMP" \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  -p \
  --databases "$DB_NAME" \
  --routines \
  --triggers \
  --single-transaction \
  --no-tablespaces \
  > "$OUTPUT_FILE"

echo
echo "Backup created:"
echo "$OUTPUT_FILE"

