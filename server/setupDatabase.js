import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const dirname = path.dirname(fileURLToPath(import.meta.url));
const schemaPath = path.join(dirname, '..', 'database', 'schema.sql');

const connection = await mysql.createConnection({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  multipleStatements: true
});

try {
  const schema = await fs.readFile(schemaPath, 'utf8');
  await connection.query(schema);
  console.log('Database ready: care_portal');
} finally {
  await connection.end();
}
