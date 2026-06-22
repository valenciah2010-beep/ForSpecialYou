export function corsMiddleware(allowedOrigins = []) {
  const allowedOriginSet = new Set(allowedOrigins);

  return async (ctx, next) => {
    const origin = ctx.get('origin');
    if (origin && allowedOriginSet.has(origin)) {
      ctx.set('Access-Control-Allow-Origin', origin);
      ctx.set('Vary', 'Origin');
      ctx.set('Access-Control-Allow-Credentials', 'true');
    }

    ctx.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    ctx.set('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');

    if (ctx.method === 'OPTIONS') {
      ctx.status = 204;
      return;
    }

    return next();
  };
}
