import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const dirname = path.dirname(fileURLToPath(import.meta.url));

function envList(name, fallback) {
  return String(process.env[name] || fallback)
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

export const serverConfig = {
  port: Number(process.env.PORT || 3002),
  host: process.env.HOST || '127.0.0.1',
  publicOrigin: process.env.PUBLIC_ORIGIN || 'https://fsyadmin.top',
  corsOrigins: envList(
    'CORS_ORIGINS',
    'https://fsyadmin.top,http://localhost:5173,http://127.0.0.1:5173'
  ),
  cookieSecure: process.env.COOKIE_SECURE !== 'false',
  adminSitePath: path.join(dirname, '..', 'dist'),
  openAIModel: process.env.OPENAI_MODEL || 'gpt-4.1-mini'
};
