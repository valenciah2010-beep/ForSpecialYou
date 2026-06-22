export function jsonBodyParser({ limitBytes = 20 * 1024 * 1024 } = {}) {
  return async (ctx, next) => {
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(ctx.method)) {
      return next();
    }

    const contentType = ctx.get('content-type') || '';
    if (!contentType.includes('application/json')) {
      ctx.request.body = {};
      return next();
    }

    const chunks = [];
    let size = 0;

    try {
      for await (const chunk of ctx.req) {
        size += chunk.length;
        if (size > limitBytes) {
          ctx.status = 413;
          ctx.body = { message: 'Request body is too large.' };
          return;
        }
        chunks.push(chunk);
      }

      const rawBody = Buffer.concat(chunks).toString('utf8').trim();
      ctx.request.body = rawBody ? JSON.parse(rawBody) : {};
      return next();
    } catch {
      ctx.status = 400;
      ctx.body = { message: 'Request body must be valid JSON.' };
    }
  };
}
