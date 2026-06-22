import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const dirname = path.dirname(fileURLToPath(import.meta.url));

export const serverConfig = {
  port: Number(process.env.PORT || 3002),
  host: process.env.HOST || '127.0.0.1',
  adminSitePath: path.join(dirname, '..', 'dist'),
  openAIModel: process.env.OPENAI_MODEL || 'gpt-4.1-mini'
};
