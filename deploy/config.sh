#!/usr/bin/env bash
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_HOST="${REMOTE_HOST:-154.40.41.179}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_DIR="${REMOTE_DIR:-/www/wwwroot/default}"
PUBLIC_PORT="${PUBLIC_PORT:-80}"
API_PORT="${API_PORT:-3002}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/deploydesk_ed25519}"
NGINX_VHOST="${NGINX_VHOST:-/www/server/panel/vhost/nginx/fsyadmin.top.conf}"
