import fs from 'fs';
import path from 'path';

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp'
};

function fileExists(filePath) {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

export function staticSiteMiddleware(rootPath) {
  const hasSite = fs.existsSync(rootPath);

  return async (ctx, next) => {
    if (!hasSite || ctx.path.startsWith('/api/')) {
      return next();
    }

    const safePath = path.normalize(decodeURIComponent(ctx.path)).replace(/^(\.\.[/\\])+/, '');
    const requestedPath = path.join(rootPath, safePath === '/' ? 'index.html' : safePath);
    const filePath = fileExists(requestedPath)
      ? requestedPath
      : path.join(rootPath, 'index.html');

    if (!fileExists(filePath)) {
      return next();
    }

    ctx.type = contentTypes[path.extname(filePath)] || 'application/octet-stream';
    ctx.body = fs.createReadStream(filePath);
  };
}
