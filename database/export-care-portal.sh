#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
OUTPUT_FILE="${1:-$HOME/Desktop/care_portal_backup.sql}"
MYSQLDUMP="/usr/local/mysql/bin/mysqldump"

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
  echo "mysqldump was not found at /usr/local/mysql/bin/mysqldump."
  exit 1
fi

echo "Exporting database $DB_NAME from $DB_HOST:$DB_PORT..."
"$MYSQLDUMP" \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  -p \
  --databases "$DB_NAME" \
  --routines \
  --triggers \
  --single-transaction \
  > "$OUTPUT_FILE"

echo
echo "Backup created:"
echo "$OUTPUT_FILE"

